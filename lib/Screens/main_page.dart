// main_page.dart

// Import necessary packages for Flutter and Firebase
import 'package:flutter/material.dart'; // Flutter material widgets library
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For interacting with Firestore database
import 'package:yellowmuscu/Screens/session_page.dart'; // Session page of the YellowMuscu app
import 'package:yellowmuscu/main_page/streaks_widget.dart'; // Custom widget to display streaks
import 'package:yellowmuscu/screens/profile_page.dart'; // User profile page
import 'package:yellowmuscu/screens/statistics_page.dart'; // User statistics page
import 'package:yellowmuscu/screens/exercises_page.dart'; // Exercises page
import 'package:yellowmuscu/Screens/app_bar_widget.dart'; // Custom widget for the app bar
import 'package:yellowmuscu/Screens/bottom_nav_bar_widget.dart'; // Custom widget for the bottom navigation bar
import 'package:yellowmuscu/main_page/like_item_widget.dart'; // Custom widget to display liked items
import 'dart:async'; // For using Timer objects and handling asynchrony
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For state management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider to manage the theme (light/dark)
import 'package:flutter/cupertino.dart'; // For using CupertinoSegmentedControl

/// Enumeration for the statistics menu
enum StatisticsMenu { friends, personal }

/// Main class of the page, which is a ConsumerStatefulWidget to use Riverpod
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

/// State associated with the MainPage class
class MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex = 0; // Index of the selected tab in the navigation bar
  String? _userId; // ID of the current user

  List<Map<String, dynamic>> likesData = []; // List of likes data
  List<Map<String, dynamic>> personalActivities =
      []; // List of personal activities
  List<String> hiddenEvents = []; // List of eventIds of deleted events

  // List of days of the week in English
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  StatisticsMenu _selectedMenu = StatisticsMenu.friends; // Selected menu

  Map<String, Map<String, dynamic>> friendsData = {}; // Cache for friends data

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // Call to retrieve the current user during initialization
  }

  /// Method to get the current user connected via Firebase Auth
  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user != null) {
      setState(() {
        _userId = user.uid; // Store the user's ID
        _fetchFriendsEvents(); // Retrieve the user's friends' events
        _fetchPersonalActivities(); // Retrieve personal activities
      });
    }
  }

  /// Method to retrieve the user's friends' events
  void _fetchFriendsEvents() async {
    if (_userId == null) {
      return; // If the user is not connected, do nothing
    }

    try {
      // Retrieve the current user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (!mounted) return;

      // Check if the document exists
      if (!userDoc.exists) {
        // Display an error message if the user does not exist
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Retrieve the user's friends list and hidden events
      List<dynamic> friends = [];
      if (userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('friends') && data['friends'] is List) {
          friends = data['friends']; // List of friends' IDs
        }
        if (data.containsKey('hiddenEvents') && data['hiddenEvents'] is List) {
          hiddenEvents = List<String>.from(
              data['hiddenEvents']); // List of hidden eventIds
        }
      }

      // Retrieve data for each friend
      friendsData = {};

      for (String friendId in friends) {
        // For each friend, retrieve their data
        Map<String, dynamic> friendData = await _getUserData(friendId);
        friendsData[friendId] = friendData;
      }

      // Retrieve events from each friend
      List<Map<String, dynamic>> events = [];

      for (String friendId in friends) {
        // Retrieve the friend's events from their 'events' collection in Firestore
        QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .collection('events')
                .get();

        for (var doc in eventsSnapshot.docs) {
          Map<String, dynamic> data = doc.data();
          String eventId = doc.id;

          // Filter out hidden events
          if (hiddenEvents.contains(eventId)) {
            continue; // Skip this event
          }

          // Check if necessary fields exist
          String eventType = data['type'] ?? '';
          String profileImage = friendsData[friendId]?['profilePicture'] ??
              'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg';
          Timestamp timestamp =
              data['timestamp'] ?? Timestamp.fromDate(DateTime(1970));

          String friendName =
              '${friendsData[friendId]?['first_name'] ?? ''} ${friendsData[friendId]?['last_name'] ?? ''}'
                  .trim();

          String description = '';

          if (eventType == 'program_creation') {
            String programName = data['programName'] ?? 'Unknown Program';

            // Construct the description message
            description = '$friendName has created a program "$programName"';

            events.add({
              'eventId': eventId,
              'friendId': friendId,
              'friendName': friendName,
              'profileImage': profileImage,
              'description': description,
              'timestamp': timestamp,
              'likes': data['likes'] ?? [],
              'programName': programName, // Add programName for notifications
            });
          } else if (eventType == 'program_completed') {
            String programName = data['programName'] ?? 'Unknown Program';
            double totalWeight = data['totalWeight'] ?? 0.0;

            // Construct the description message
            description =
                '$friendName lifted ${totalWeight.toStringAsFixed(2)} kg during the session "$programName"';

            events.add({
              'eventId': eventId,
              'friendId': friendId,
              'friendName': friendName,
              'profileImage': profileImage,
              'description': description,
              'timestamp': timestamp,
              'likes': data['likes'] ?? [],
              'programName': programName,
            });
          }
        }
      }

      // Sort events by decreasing date (most recent first)
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (!mounted) return;

      setState(() {
        likesData = events; // Update the list of liked events
      });
    } catch (e) {
      // Handle errors by displaying a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error retrieving events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Method to retrieve the user's personal activities
  void _fetchPersonalActivities() async {
    if (_userId == null) {
      return;
    }

    try {
      QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('events')
              .get();

      List<Map<String, dynamic>> events = [];

      // Retrieve the user's profile image
      Map<String, dynamic> currentUserData = await _getUserData(_userId!);
      String profileImage = currentUserData['profilePicture'] ??
          'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg';

      for (var doc in eventsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String eventId = doc.id;

        String eventType = data['type'] ?? '';

        Timestamp timestamp =
            data['timestamp'] ?? Timestamp.fromDate(DateTime(1970));

        // Retrieve likes
        List<dynamic> likes = data['likes'] ?? [];

        String description = '';

        if (eventType == 'program_creation') {
          String programName = data['programName'] ?? 'Unknown Program';

          // Construct the description message
          description = 'You have created a program "$programName"';

          events.add({
            'eventId': eventId,
            'profileImage': profileImage, // Use the user's profile image
            'description': description,
            'timestamp': timestamp,
            'likes': likes,
          });
        } else if (eventType == 'program_completed') {
          String programName = data['programName'] ?? 'Unknown Program';
          double totalWeight = data['totalWeight'] ?? 0.0;

          // Construct the description message
          description =
              'You lifted ${totalWeight.toStringAsFixed(2)} kg during the session "$programName"';

          events.add({
            'eventId': eventId,
            'profileImage': profileImage,
            'description': description,
            'timestamp': timestamp,
            'likes': likes,
          });
        }
      }

      // Sort events by decreasing date
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (!mounted) return;

      setState(() {
        personalActivities = events;
      });
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error retrieving your activities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Function to retrieve a user's data (full name and profile picture)
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return {
        'last_name': data['last_name'] ?? 'Unknown',
        'first_name': data['first_name'] ?? 'User',
        'profilePicture': data['profilePicture'] ??
            'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg',
      };
    } else {
      // If the user does not exist, return default values
      return {
        'last_name': 'Unknown',
        'first_name': 'User',
        'profilePicture':
            'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg',
      };
    }
  }

  /// Method to like an event
  void _likeEvent(Map<String, dynamic> event) async {
    if (_userId == null) {
      return; // If the user is not connected, do nothing
    }

    try {
      // Retrieve necessary information from the event
      String friendId = event['friendId'] as String;
      String eventId = event['eventId'] as String;

      // Check if the user has already liked the event
      List<dynamic> currentLikes = event['likes'] as List<dynamic>? ?? [];
      if (currentLikes.contains(_userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already liked this event.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Add a like to the event in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('events')
          .doc(eventId)
          .update({
        'likes': FieldValue.arrayUnion([_userId])
      });

      // Add a notification to the friend to inform them of the like
      Map<String, dynamic> currentUserData = await _getUserData(_userId!);
      String fromUserName =
          '${currentUserData['first_name']} ${currentUserData['last_name']}'
              .trim();
      String fromUserProfilePicture = currentUserData['profilePicture'];

      // Use the event description for the notification
      String notificationDescription =
          '$fromUserName liked your activity: ${event['description']}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('notifications')
          .add({
        'type': 'like',
        'fromUserId': _userId,
        'fromUserName': fromUserName,
        'fromUserProfilePicture': fromUserProfilePicture,
        'eventId': eventId,
        'timestamp': FieldValue.serverTimestamp(),
        'description': notificationDescription,
      });

      // Update the user interface by refreshing the events
      _fetchFriendsEvents();

      // Display a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You liked an activity'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle errors by displaying a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Method to build the program summary section
  Widget _buildProgramSummarySection() {
    if (_userId == null) {
      // If the user is not connected, display a message
      return const Text('Please sign in to see your programs.');
    }

    // Use a StreamBuilder to listen for changes in the user's 'programs' collection
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a progress indicator while loading
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Display a message in case of error
          return const Text('Error loading programs.');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // If no program is available
          return const Text('No program available.');
        }

        // Convert documents into a list of maps
        List<Map<String, dynamic>> programs = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data();

          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Program',
            'icon': data['icon'] ?? 'lib/data/icon_images/chest_part.png',
            'iconName': data['iconName'] ?? 'Chest part',
            'day': data['day'] ?? '',
            'isFavorite': data['isFavorite'] ?? false,
            'exercises': data['exercises'] ?? [],
          };
        }).toList();

        // Determine the next upcoming program
        Map<String, dynamic>? nextProgram = _getNextProgram(programs);

        if (nextProgram == null) {
          return const Text('No program scheduled at the moment.');
        }

        // Return the widget displaying the summary of the next program
        return NextProgramSummary(
          program: nextProgram,
          daysOfWeek: _daysOfWeek,
        );
      },
    );
  }

  /// Method to find the next program based on the current day
  Map<String, dynamic>? _getNextProgram(List<Map<String, dynamic>> programs) {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday

    // Filter programs whose day is after the current day
    List<Map<String, dynamic>> futurePrograms = programs.where((program) {
      int programDayIndex = _daysOfWeek.indexOf(program['day']) + 1; // 1-7
      return programDayIndex >= currentWeekday;
    }).toList();

    if (futurePrograms.isNotEmpty) {
      // Find the program with the closest day after the current day
      futurePrograms.sort((a, b) {
        int dayA = _daysOfWeek.indexOf(a['day']) + 1;
        int dayB = _daysOfWeek.indexOf(b['day']) + 1;
        return dayA.compareTo(dayB);
      });
      return futurePrograms.first;
    } else if (programs.isNotEmpty) {
      // If no program is after today, return the first program of the next week
      return programs.first;
    } else {
      return null; // No program available
    }
  }

  /// Method to build the likes section with permanent deletion
  Widget _buildLikesSection() {
    final isDarkMode =
        ref.watch(themeModeProvider); // Check if dark theme is enabled

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? darkWidget : lightWidget,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.7),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Ensure children occupy full width
        children: [
          // Section title
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          // Container with borderRadius for the CupertinoSegmentedControl
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0), // Border radius
            ),
            child: CupertinoSegmentedControl<StatisticsMenu>(
              padding: EdgeInsets.zero, // Remove the default internal padding
              groupValue: _selectedMenu,
              children: {
                StatisticsMenu.friends: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Friends activity',
                    style: TextStyle(
                      color: _selectedMenu == StatisticsMenu.friends
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: _selectedMenu == StatisticsMenu.friends
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                StatisticsMenu.personal: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Your Activity',
                    style: TextStyle(
                      color: _selectedMenu == StatisticsMenu.friends
                          ? Colors.black
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: _selectedMenu == StatisticsMenu.friends
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              },
              onValueChanged: (StatisticsMenu value) {
                setState(() {
                  _selectedMenu = value;
                });
              },
              selectedColor: darkBottom,
              unselectedColor: Colors.white,
              borderColor: darkBottom,
            ),
          ),
          const SizedBox(height: 16),
          // Display activities based on the selected menu
          _selectedMenu == StatisticsMenu.friends
              ? _buildFriendsActivities(isDarkMode)
              : _buildPersonalActivities(isDarkMode),
        ],
      ),
    );
  }

  /// Method to build the list of friends' activities
  Widget _buildFriendsActivities(bool isDarkMode) {
    return likesData.isEmpty
        ? const Center(
            child: Text(
              'No recent activity',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16.0), // Add internal padding
            width: double.infinity, // Use full available width
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: likesData.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = likesData[index];
                  bool isLiked =
                      (event['likes'] as List<dynamic>?)?.contains(_userId) ??
                          false;
                  String description = event['description'];

                  return Dismissible(
                    key: Key(event['eventId']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      String dismissedEventId = event['eventId'];

                      setState(() {
                        likesData.removeAt(index);
                      });

                      // Add the eventId to hiddenEvents in Firestore
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_userId)
                            .update({
                          'hiddenEvents':
                              FieldValue.arrayUnion([dismissedEventId])
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      // Display a confirmation message
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event permanently deleted.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: LikeItem(
                      profileImage: event['profileImage'] as String,
                      description: description,
                      onLike: () => _likeEvent(event),
                      isLiked: isLiked,
                    ),
                  );
                },
              ),
            ),
          );
  }

  /// Method to build the list of personal activities
  Widget _buildPersonalActivities(bool isDarkMode) {
    return personalActivities.isEmpty
        ? Container(
            width: double.infinity, // Ensure consistent width
            child: const Center(
              child: Text(
                'No recent activity',
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16.0), // Add internal padding
            width: double.infinity, // Use full available width
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: personalActivities.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = personalActivities[index];
                  List<dynamic> likes = event['likes'] ?? [];
                  int likesCount = likes.length;
                  bool isLiked = likes.contains(_userId);
                  String description = event['description'];

                  return PersonalActivityItem(
                    profileImage: event['profileImage'] as String,
                    description: description,
                    likesCount: likesCount,
                    isLiked: isLiked,
                    onLike: () => _likePersonalEvent(event),
                  );
                },
              ),
            ),
          );
  }

  /// Method to like a personal activity
  void _likePersonalEvent(Map<String, dynamic> event) async {
    if (_userId == null) return;

    try {
      String eventId = event['eventId'] as String;

      List<dynamic> currentLikes = event['likes'] as List<dynamic>? ?? [];
      if (currentLikes.contains(_userId)) {
        // If already liked, remove the like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('events')
            .doc(eventId)
            .update({
          'likes': FieldValue.arrayRemove([_userId])
        });
      } else {
        // Add a like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('events')
            .doc(eventId)
            .update({
          'likes': FieldValue.arrayUnion([_userId])
        });
      }

      // Refresh personal activities
      _fetchPersonalActivities();
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Method to build the home page with the gradient
  Widget _buildHomePage() {
    final isDarkMode = ref.watch(themeModeProvider);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Background gradient that covers the entire screen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [darkTop, darkBottom]
                    : [
                        lightTop,
                        lightBottom,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Scrollable content above the gradient
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildProgramSummarySection(), // Display the next program
                  const SizedBox(height: 16),
                  if (_userId != null)
                    StreaksWidget(
                        userId:
                            _userId!), // Display the streaks widget if the user is connected
                  const SizedBox(height: 16),
                  _buildLikesSection(), // Display the likes section
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;

    // Determine which page to display based on the selected index
    switch (_selectedIndex) {
      case 0:
        currentPage = _buildHomePage();
        break;
      case 1:
        currentPage = const ExercisesPage();
        break;
      case 2:
        currentPage = const StatisticsPage();
        break;
      case 3:
        currentPage = const SessionPage();
        break;
      case 4:
        currentPage = const ProfilePage();
        break;
      default:
        currentPage = _buildHomePage();
    }

    final isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: isDarkMode
          ? lightTop
          : Colors.white, // Background color based on the theme
      body: currentPage, // Display the current page
      appBar: const AppBarWidget(), // Custom app bar
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 0) {
              _fetchFriendsEvents(); // Refresh events if the Home tab is selected
              _fetchPersonalActivities(); // Refresh personal activities
            }
          });
        },
      ),
    );
  }
}

/// Widget to display the summary of the next program with countdown
class NextProgramSummary extends ConsumerStatefulWidget {
  final Map<String, dynamic> program; // The program to display
  final List<String> daysOfWeek; // List of days of the week

  const NextProgramSummary({
    super.key,
    required this.program,
    required this.daysOfWeek,
  });

  @override
  NextProgramSummaryState createState() => NextProgramSummaryState();
}

class NextProgramSummaryState extends ConsumerState<NextProgramSummary> {
  late DateTime _nextProgramDateTime; // Date and time of the next program
  late Duration _timeRemaining; // Time remaining before the program
  Timer? _timer; // Timer for the countdown

  @override
  void initState() {
    super.initState();
    _nextProgramDateTime =
        _calculateNextProgramDateTime(); // Calculate the date of the next program
    _timeRemaining = _nextProgramDateTime
        .difference(DateTime.now()); // Calculate the remaining time
    _startCountdown(); // Start the countdown
  }

  @override
  void didUpdateWidget(covariant NextProgramSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program['day'] != widget.program['day']) {
      // If the program day has changed, recalculate the dates
      _nextProgramDateTime = _calculateNextProgramDateTime();
      _timeRemaining = _nextProgramDateTime.difference(DateTime.now());
      _timer?.cancel();
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing the widget
    super.dispose();
  }

  /// Method to calculate the next DateTime of the program based on the day
  DateTime _calculateNextProgramDateTime() {
    String programDay =
        widget.program['day']; // Example: 'Wednesday' or 'Mercredi'

    // Map to associate day names in English and French to weekday numbers
    final Map<String, int> dayNameToWeekday = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
      'Lundi': 1,
      'Mardi': 2,
      'Mercredi': 3,
      'Jeudi': 4,
      'Vendredi': 5,
      'Samedi': 6,
      'Dimanche': 7,
    };

    int programWeekday = dayNameToWeekday[programDay] ?? 0;

    if (programWeekday == 0) {
      // If the day is not found, return a distant date
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday

    // Calculate the number of days until the next program day
    int daysUntilNext = (programWeekday - currentWeekday + 7) % 7 + 1;

    // Calculate the date of the next program
    DateTime nextProgramDate = DateTime(
      now.year,
      now.month,
      now.day,
      8, // Specific hour for the start of the program (8:00 AM)
      0,
      0,
    ).add(Duration(days: daysUntilNext));

    // If the date of the next program has already passed today, schedule it for the next week
    if (nextProgramDate.isBefore(now)) {
      nextProgramDate = nextProgramDate.add(const Duration(days: 7));
    }

    return nextProgramDate;
  }

  /// Method to start the countdown
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _timeRemaining = _nextProgramDateTime.difference(now);
        if (_timeRemaining.isNegative) {
          _timeRemaining = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    String iconPath = widget.program['icon'] ??
        'lib/data/icon_images/chest_part.png'; // Default path
    String programName = widget.program['name'] ?? 'Program Name';
    List<dynamic> exercises = widget.program['exercises'] ?? [];

    // Format of the countdown
    String countdownText = _formatDuration(_timeRemaining);

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? darkWidget
            : lightWidget, // Background color based on the theme
        borderRadius: BorderRadius.circular(16.0), // Rounded borders
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown at the top
          Text(
            'Next session in $countdownText',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Image and program information
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category image
              Column(
                children: [
                  Image.asset(
                    iconPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 80);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    programName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Dynamic color
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // List of exercises
              Expanded(
                child: exercises.isEmpty
                    ? const Text(
                        'No exercise available',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(
                          maxHeight: 300, // Maximum height (in pixels)
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            var exercise = exercises[index];
                            String exerciseName =
                                exercise['name'] ?? 'Exercise';
                            int sets = exercise['sets'] ?? 0;
                            int reps = exercise['reps'] ?? 0;
                            double weight =
                                (exercise['weight'] ?? 0).toDouble();
                            int rest = exercise['restBetweenExercises'] ?? 0;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exerciseName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // Dynamic color
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sets: $sets • Reps: $reps • Weight: ${weight}kg • Rest: ${rest}s',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Method to format the duration into days, hours, minutes, seconds
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inDays > 1) {
      return '${duration.inDays} days';
    } else {
      int hours = duration.inHours.remainder(24);
      int minutes = duration.inMinutes.remainder(60);
      return '${twoDigits(hours)} hours ${twoDigits(minutes)} minutes';
    }
  }
}

/// Widget for personal activities with the number of likes
class PersonalActivityItem extends StatefulWidget {
  final String profileImage;
  final String description;
  final int likesCount;
  final VoidCallback onLike;
  final bool isLiked;

  const PersonalActivityItem({
    super.key,
    required this.profileImage,
    required this.description,
    required this.likesCount,
    required this.onLike,
    required this.isLiked,
  });

  @override
  PersonalActivityItemState createState() => PersonalActivityItemState();
}

class PersonalActivityItemState extends State<PersonalActivityItem>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (_isLiked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PersonalActivityItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      setState(() {
        _isLiked = widget.isLiked;
        if (_isLiked) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() {
    widget.onLike();
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Brightness.dark; // Ensure the text adapts to the theme

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.profileImage),
      ),
      title: Text(
        widget.description,
        style: const TextStyle(
          color: Colors.black, // Dynamic color
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _handleLike,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.likesCount}',
            style: const TextStyle(
              color: Colors.black87, // Dynamic color
            ),
          ),
        ],
      ),
    );
  }
}
