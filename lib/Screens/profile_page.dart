// profile_page.dart

// Import necessary packages for Flutter and Firebase
import 'package:flutter/material.dart'; // Flutter material widgets library
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For interacting with Firestore database
import 'package:yellowmuscu/Provider/theme_provider.dart';

// Define the ProfilePage class, a StatefulWidget to display and edit user profiles
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // Create the state associated with the ProfilePage class
  ProfilePageState createState() => ProfilePageState();
}

// State associated with the ProfilePage class
class ProfilePageState extends State<ProfilePage> {
  // Instance of FirebaseAuth to manage authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable to store the currently logged-in user
  bool _isEditing = false; // Indicates if the edit mode is enabled

  // Controllers to manage text inputs in TextFields
  final TextEditingController _lastNameController =
      TextEditingController(); // Controller for last name
  final TextEditingController _firstNameController =
      TextEditingController(); // Controller for first name
  final TextEditingController _weightController =
      TextEditingController(); // Controller for weight
  final TextEditingController _heightController =
      TextEditingController(); // Controller for height
  final TextEditingController _birthdateController =
      TextEditingController(); // Controller for birthdate
  final TextEditingController _searchController =
      TextEditingController(); // Controller for search bar

  DateTime? _selectedBirthdate; // Variable to store the selected birthdate
  String _selectedProfilePicture = ''; // URL of the selected profile picture
  String _searchQuery = ''; // Search query for filtering friends

  // Lists to store user data, friends, and friend requests
  List<Map<String, dynamic>> _allUsers = []; // List of all users
  List<dynamic> _friends = []; // List of user's friends
  List<dynamic> _sentRequests = []; // List of sent friend requests
  List<String> _receivedRequests = []; // List of received friend requests

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Get the currently logged-in user
    if (_user != null) {
      _fetchUserData(); // Fetch user data from Firestore
      _fetchReceivedFriendRequests(); // Fetch received friend requests
    }

    // Listen to changes in the search bar
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    // Display a message if passed as an argument when navigating to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Ensure the widget is still mounted
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _lastNameController.dispose();
    _firstNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _birthdateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Method to fetch user data from Firestore
  void _fetchUserData() async {
    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users') // Access the 'users' collection in Firestore
        .doc(_user!.uid) // Get the document of the current user
        .get(); // Retrieve the document data

    if (userData.exists) {
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          // Update controllers with retrieved data
          _lastNameController.text = data['last_name'] ?? '';
          _firstNameController.text = data['first_name'] ?? '';
          _weightController.text = data['weight'] ?? '';
          _heightController.text = data['height'] ?? '';
          _selectedProfilePicture = data['profilePicture'] ?? '';

          // Handle birthdate
          if (data['birthdate'] != null &&
              data['birthdate'].toString().isNotEmpty) {
            _selectedBirthdate = DateTime.parse(data['birthdate']);
            _birthdateController.text =
                '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}';
          } else {
            _selectedBirthdate = null;
            _birthdateController.text = '';
          }

          // Retrieve the list of friends and sent requests
          _friends = data['friends'] ?? [];
          _sentRequests = data['sentRequests'] ?? [];
        });
      }
    }
  }

  // Method to fetch received friend requests
  void _fetchReceivedFriendRequests() async {
    if (_user == null) return;

    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'friendRequest')
        .get();

    List<String> receivedRequests = notificationsSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['fromUserId'] as String;
    }).toList();

    if (mounted) {
      setState(() {
        _receivedRequests = receivedRequests;
      });
    }
  }

  // Method to get the current user's data
  Future<Map<String, dynamic>> _getCurrentUserData() async {
    if (_user == null) {
      return {'last_name': '', 'first_name': '', 'profilePicture': ''};
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {'last_name': '', 'first_name': '', 'profilePicture': ''};
    }
  }

  // Method to send a friend request
  void _sendFriendRequest(String friendId) async {
    if (_user == null) return;

    // Get current user's data
    Map<String, dynamic> currentUserData = await _getCurrentUserData();
    String fromUserName =
        '${currentUserData['last_name'] ?? ''} ${currentUserData['first_name'] ?? ''}'
            .trim();
    String fromUserProfilePicture = currentUserData['profilePicture'] ?? '';

    // Check if a request has already been sent
    if (_sentRequests.contains(friendId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('You have already sent a friend request to this user.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if a request has been received from this user
    if (_receivedRequests.contains(friendId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You already have a pending friend request from this user.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Add the request to the target user's 'notifications' collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .collection('notifications')
        .add({
      'type': 'friendRequest',
      'fromUserId': _user!.uid,
      'fromUserName': fromUserName,
      'fromUserProfilePicture': fromUserProfilePicture,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the current user's sent requests list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({
      'sentRequests': FieldValue.arrayUnion([friendId]),
    });

    if (mounted) {
      setState(() {
        _sentRequests.add(friendId);
      });

      // Display a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Method to save profile changes
  void _saveProfile() async {
    // Retrieve and validate field values
    String lastName = _lastNameController.text.trim();
    String firstName = _firstNameController.text.trim();
    int? weight = int.tryParse(_weightController.text.trim());
    int? height = int.tryParse(_heightController.text.trim());

    // Field validations
    if (lastName.length > 15) {
      _showError('Last name must not exceed 15 characters.');
      return;
    }

    if (firstName.length > 15) {
      _showError('First name must not exceed 15 characters.');
      return;
    }

    if (weight == null || weight < 0 || weight > 200) {
      _showError('Weight must be an integer between 0 and 200.');
      return;
    }

    if (height == null || height < 0 || height > 250) {
      _showError('Height must be an integer between 0 and 250.');
      return;
    }

    if (_user != null) {
      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'last_name': lastName,
        'first_name': firstName,
        'weight': weight.toString(),
        'height': height.toString(),
        'birthdate': _selectedBirthdate?.toIso8601String() ?? '',
        'profilePicture': _selectedProfilePicture,
        'email': _user!.email,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false; // Disable edit mode
        });
        // Refresh user data
        _fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Method to display an error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to sign out the user
  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/signIn');
    }
  }

  // Method to toggle edit mode
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Method to delete the user account
  void _deleteAccount() async {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Display a confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to delete your account? This action is irreversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // The user canceled the deletion
    }

    try {
      // Delete Firestore data
      await _deleteUserData();

      // Delete the user from Firebase Auth
      await _user!.delete();

      if (mounted) {
        // Display a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // After deletion, show a dialog to choose between signing in or creating an account
        showDialog(
          context: context,
          barrierDismissible: false, // Prevents closing by tapping outside
          builder: (context) {
            return AlertDialog(
              title: const Text('Account Deleted'),
              content: const Text(
                  'Your account has been deleted. What would you like to do now?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context)
                        .pushReplacementNamed('/signIn'); // Navigate to sign in
                  },
                  child: const Text('Sign In'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context)
                        .pushReplacementNamed('/signUp'); // Navigate to sign up
                  },
                  child: const Text('Create Account'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showError(
            'Account deletion failed. Please log in again and try again.');
        // Optionally: Navigate to the sign-in page for re-authentication
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signIn');
        }
      } else {
        _showError('Account deletion failed: ${e.message}');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  // Method to delete user data from Firestore
  Future<void> _deleteUserData() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    // Delete user's notifications
    QuerySnapshot notificationsSnapshot =
        await userRef.collection('notifications').get();

    for (var doc in notificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the user document
    batch.delete(userRef);

    // Remove the user from other users' friends lists
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('friends', arrayContains: _user!.uid)
        .get();

    for (var doc in friendsSnapshot.docs) {
      DocumentReference docRef = doc.reference;
      batch.update(docRef, {
        'friends': FieldValue.arrayRemove([_user!.uid])
      });
    }

    // Remove the user from other users' sent requests
    QuerySnapshot sentRequestsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('sentRequests', arrayContains: _user!.uid)
        .get();

    for (var doc in sentRequestsSnapshot.docs) {
      DocumentReference docRef = doc.reference;
      batch.update(docRef, {
        'sentRequests': FieldValue.arrayRemove([_user!.uid])
      });
    }

    // Execute the batch
    await batch.commit();
  }

  // Method to select birthdate using a date picker
  void _selectBirthdate() async {
    DateTime initialDate = _selectedBirthdate ?? DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != _selectedBirthdate) {
      if (mounted) {
        setState(() {
          _selectedBirthdate = picked;
          _birthdateController.text =
              '${picked.day}/${picked.month}/${picked.year}';
        });
      }
    }
  }

  // Widget to display the "Add Friends" section with a search bar
  Widget _buildAddFriendsSection() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Add Friends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Search bar
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search for friends',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            List<DocumentSnapshot> usersDocs = snapshot.data!.docs;
            _allUsers = usersDocs
                .map((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  return {
                    'uid': doc.id,
                    'last_name': data['last_name'] ?? '',
                    'first_name': data['first_name'] ?? '',
                    'profilePicture': data['profilePicture'] ?? '',
                  };
                })
                .where((user) => user['uid'] != _user!.uid)
                .toList();

            // Filter users based on search query
            List<Map<String, dynamic>> filteredUsers = _allUsers.where((user) {
              String fullName =
                  '${user['last_name']} ${user['first_name']}'.toLowerCase();
              return fullName.contains(_searchQuery);
            }).toList();

            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  bool isFriend = _friends.contains(user['uid']);
                  bool requestSent = _sentRequests.contains(user['uid']);
                  bool requestReceived =
                      _receivedRequests.contains(user['uid']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['profilePicture']),
                    ),
                    title: Text('${user['last_name']} ${user['first_name']}'),
                    trailing: isFriend
                        ? const Text('Friend')
                        : requestSent
                            ? const Text('Request Sent')
                            : requestReceived
                                ? const Text('Request Received')
                                : SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _sendFriendRequest(user['uid']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDarkMode
                                            ? darkWidget
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.black),
                                      ),
                                    ),
                                  ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Widget to build the profile display
  Widget _buildProfile() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile picture centered at the top
        Center(
          child: CircleAvatar(
            backgroundImage: NetworkImage(_selectedProfilePicture.isNotEmpty
                ? _selectedProfilePicture
                : 'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg'),
            radius: 50,
          ),
        ),
        const SizedBox(height: 16),
        if (_isEditing)
          // Input fields for editing
          Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                ),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                ),
              ),
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height',
                ),
                keyboardType: TextInputType.number,
              ),
              GestureDetector(
                onTap: _selectBirthdate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _birthdateController,
                    decoration: const InputDecoration(
                      labelText: 'Birthdate',
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Display profile information
          Column(
            children: [
              // First name and last name together, centered
              Center(
                child: Text(
                  '${_firstNameController.text} ${_lastNameController.text}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              // Email address centered
              Center(
                child: Text(
                  _user?.email ?? 'Not defined',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              // Weight, height, and birthdate in white boxes
              _buildStatsSection(),
            ],
          ),
        const SizedBox(height: 20),
        // Buttons for editing profile, saving, signing out, and deleting account

        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _toggleEditing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightWidget,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isEditing ? 'Cancel' : 'Edit Profile',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                _isEditing
                    ? SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDarkMode ? darkWidget : Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: Colors.white,
                              width: isDarkMode ? 1.5 : 0,
                            ),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 14,
                              color: lightWidget,
                            ),
                          ),
                        ),
                      ),
                // Bouton Delete Account
                if (!_isEditing)
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: Colors.white,
                          width: isDarkMode ? 1.5 : 0,
                        ),
                      ),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 14,
                          color: lightWidget,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Display the "Add Friends" section if edit mode is disabled
        if (!_isEditing) _buildAddFriendsSection(),
      ],
    );
  }

  // Modified Widget to display the stats section
  Widget _buildStatsSection() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? darkWidget : lightWidget, // Fond jaune
          borderRadius: BorderRadius.circular(16.0), // Coins arrondis
        ),
        child: Text(
          '${_weightController.text.isNotEmpty ? '${_weightController.text} Kg' : '-'} ·  '
          '${_heightController.text.isNotEmpty ? '${_heightController.text} cm' : '-'} ·  '
          '${_birthdateController.text.isNotEmpty ? _birthdateController.text : '-'}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.black : Colors.black, // Texte noir
          ),
          textAlign: TextAlign.center, // Texte centré
        ),
      ),
    );
  }

  // Widget to display the sign-in screen if the user is not logged in
  Widget _buildSignIn() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Button to sign in
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signIn');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? darkWidget : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Button to create an account
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signUp');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [darkTop, darkBottom]
                  : [
                      lightTop,
                      lightBottom,
                    ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isEditing
              ? AppBar(
                  title: const Text('Edit Profile'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                )
              : null,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _user == null ? _buildSignIn() : _buildProfile(),
            ),
          ),
        ),
      ],
    );
  }
}
