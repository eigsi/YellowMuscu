// session_page.dart

import 'package:flutter/material.dart'; // Main Flutter widget library
import 'package:cloud_firestore/cloud_firestore.dart'; // To interact with Firebase Firestore database
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:yellowmuscu/Session_page/exercise_session_page.dart'; // Page for the exercise session
import 'package:flutter_riverpod/flutter_riverpod.dart'; // For state management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider for theme (light/dark)

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  SessionPageState createState() => SessionPageState();
}

class SessionPageState extends ConsumerState<SessionPage> {
  // FirebaseAuth instance for authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable to store the currently logged-in user
  List<Map<String, dynamic>> _programs = []; // List of user's programs

  DateTime? sessionStartTime; // Session start time
  bool _isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Retrieves the currently logged-in user
    _fetchPrograms(); // Fetches the user's programs
  }

  // Method to mark a program as completed
  void _markProgramAsDone(String programId, DateTime sessionEndTime) async {
    if (_user == null) {
      return; // If the user is not logged in, do nothing
    }

    try {
      // Retrieve the program from Firestore
      DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .get();

      if (!programSnapshot.exists) {
        if (!mounted) return;
        // If the program does not exist, display an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Retrieve the program data
      Map<String, dynamic> programData =
          programSnapshot.data() as Map<String, dynamic>;

      // Calculate the total weight lifted during the session
      List<dynamic> exercises = programData['exercises'] ?? [];
      double totalWeight = 0.0;
      for (var exercise in exercises) {
        // Retrieve weight, number of reps, and sets
        double weight = double.tryParse(exercise['weight'].toString()) ?? 0.0;
        int reps = int.tryParse(exercise['reps'].toString()) ?? 0;
        int sets = int.tryParse(exercise['sets'].toString()) ?? 0;

        totalWeight += weight * reps * sets; // Calculate total weight
      }

      // Calculate the duration of the session
      Duration sessionDuration = sessionEndTime.difference(sessionStartTime!);
      // Format the duration into hours, minutes, and seconds
      String durationFormatted =
          "${sessionDuration.inHours}:${sessionDuration.inMinutes.remainder(60)}:${sessionDuration.inSeconds.remainder(60)}";

      // Save the completed session in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('completedSessions')
          .add({
        'programName': programData['name'] ?? 'Untitled Program',
        'programId': programId, // Add programId to identify the program
        'date': sessionEndTime,
        'duration': durationFormatted,
        'totalWeight': totalWeight,
        'userId': _user!.uid,
      });

      // **Add an event to the user's events subcollection**
      // Retrieve the user's name from their document
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      String userName = 'User';
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          String firstName = userData['first_name'] ?? '';
          String lastName = userData['last_name'] ?? '';
          userName = '$firstName $lastName'.trim();
        }
      }

      // Add the event to the user's events subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('events')
          .add({
        'type': 'program_completed',
        'timestamp': FieldValue.serverTimestamp(),
        'programName': programData['name'] ?? 'Untitled Program',
        'totalWeight': totalWeight,
        'description':
            '$userName lifted ${totalWeight.toStringAsFixed(2)} kg during the session "${programData['name']}"',
        'likes': [], // Initialize likes as empty list
      });

      if (!mounted) return;

      // Display a success message with session details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Session completed! Duration: $durationFormatted, Total weight lifted: ${totalWeight.toStringAsFixed(2)} kg'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the programs list to update the checkboxes
      _fetchPrograms();
    } catch (e) {
      if (!mounted) return;
      // In case of an error, display a more detailed error message
      String errorMessage =
          'An error occurred while saving the completed session. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to start a training session
  void _startSession(Map<String, dynamic> program) {
    if (program['exercises'].length < 2) {
      // If the program has zero or one exercise, display a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You have to add more than one exercise to the program to begin a session!'),
        ),
      );
    } else {
      // Display a confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final isDarkMode = ref.watch(themeModeProvider);
          return AlertDialog(
            backgroundColor: isDarkMode ? darkNavBar : Colors.white,
            title: Text(
              'Begin session?',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Text(
              'Do you really want to begin session "${program['name']}"?',
              style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the dialog
                },
              ),
              TextButton(
                child: Text(
                  'Start',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the dialog
                  sessionStartTime = DateTime.now(); // Records the start time
                  // Navigates to the ExerciseSessionPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseSessionPage(
                        program: program,
                        userId: _user!.uid,
                        onSessionComplete: () {
                          // Callback when the session is completed
                          DateTime sessionEndTime = DateTime.now();
                          _markProgramAsDone(program['id'], sessionEndTime);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Method to fetch the user's programs and their completion status for this week
  void _fetchPrograms() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true; // Starts loading
    });

    try {
      // Fetch programs and completed sessions in parallel
      final userProgramsFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .get();

      // Get the start and end of the current week
      DateTime now = DateTime.now();
      DateTime startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // Start on Monday
      DateTime endOfWeek =
          startOfWeek.add(Duration(days: 7)); // End on next Monday

      Timestamp startTimestamp = Timestamp.fromDate(DateTime(
          startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0));
      Timestamp endTimestamp = Timestamp.fromDate(
          DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 0, 0, 0));

      final completedSessionsFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('completedSessions')
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThan: endTimestamp)
          .get();

      // Wait for both futures
      final results = await Future.wait([
        userProgramsFuture,
        completedSessionsFuture,
      ]);

      final userProgramsSnapshot = results[0] as QuerySnapshot;
      final completedSessionsSnapshot = results[1] as QuerySnapshot;

      if (!mounted) return;

      // Build set of program IDs for which the user has completed sessions this week
      Set<String> completedProgramIdsThisWeek = {};
      for (var doc in completedSessionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String programId = data['programId'] ?? '';
        if (programId.isNotEmpty) {
          completedProgramIdsThisWeek.add(programId);
        }
      }

      setState(() {
        // Updates the list of programs with the retrieved data
        _programs = userProgramsSnapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            // If data is null, return a default program
            return {
              'id': doc.id,
              'name': 'Untitled Program',
              'isFavorite': false,
              'isDone': false,
              'exercises': [],
              'isCompletedThisWeek': false,
            };
          }

          // Retrieve the list of exercises in the program
          List<dynamic> exercisesData = data['exercises'] ?? [];
          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is Map<String, dynamic>) {
                  // Converts the exercise to Map<String, dynamic>
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return {};
                }
              })
              .cast<Map<String, dynamic>>()
              .toList();

          // Check if the program has been completed this week
          bool isCompletedThisWeek =
              completedProgramIdsThisWeek.contains(doc.id);

          // Returns the program with its details
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Untitled Program',
            'isFavorite': data['isFavorite'] ?? false,
            'isDone': data['isDone'] ?? false,
            'exercises': exercises,
            'isCompletedThisWeek': isCompletedThisWeek,
          };
        }).toList();
        _isLoading = false; // Ends loading
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Ends loading in case of error
      });
      // In case of an error, display a more detailed error message
      String errorMessage =
          'An error occurred while fetching programs. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeModeProvider); // Checks if dark theme is enabled

    return Scaffold(
      body: Container(
        // Applies a background gradient
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
        child: _isLoading
            ? Center(
                // Loading indicator
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? Colors.white : Colors.black),
                ),
              )
            : _programs.isEmpty
                ? const Center(
                    // Message if no programs are available
                    child: Text(
                      'No programs available.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _programs.length, // Number of programs
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return GestureDetector(
                        onTap: () {
                          _startSession(program);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(16.0), // Rounded corners
                            color: isDarkMode ? darkWidget : lightWidget,
                          ),
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(
                              program['name'] ?? 'Untitled Program',
                              style: const TextStyle(
                                color: darkTop,
                              ),
                            ),
                            trailing: CheckboxTheme(
                              data: CheckboxThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      4.0), // Define the BorderRadius
                                ),
                                side: const BorderSide(
                                  color: darkTop,
                                  width: 2.0,
                                ),
                              ),
                              child: Checkbox(
                                value: program['isCompletedThisWeek'] ?? false,
                                onChanged: null,
                                checkColor:
                                    isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
