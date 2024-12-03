// lib/authentication/sign_up_page.dart

// Importing necessary packages for Flutter and Firebase functionalities
import 'package:flutter/material.dart'; // Flutter's material design widgets
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore package for database interactions
import 'package:yellowmuscu/tutorial/tutorial_page.dart'; // Importing the TutorialPage screen

// Defining the SignUpPage as a StatefulWidget to manage dynamic state changes
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // Creating the mutable state for this widget
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

// The state class associated with SignUpPage
class _SignUpPageState extends State<SignUpPage> {
  // Initializing Firebase Authentication and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Controllers to capture user input from TextFields
  final TextEditingController _firstNameController =
      TextEditingController(); // Controller for first name input
  final TextEditingController _lastNameController =
      TextEditingController(); // Controller for last name input
  final TextEditingController _emailController =
      TextEditingController(); // Controller for email input
  final TextEditingController _passwordController =
      TextEditingController(); // Controller for password input
  final TextEditingController _weightController =
      TextEditingController(); // Controller for weight input
  final TextEditingController _heightController =
      TextEditingController(); // Controller for height input
  final TextEditingController _dobController =
      TextEditingController(); // Controller for date of birth input

  int _selectedProfileImageIndex = 0; // Index of the selected profile image

  // List of predefined profile image URLs for user selection
  final List<String> _profileImages = [
    'https://i.pinimg.com/564x/a4/54/16/a45416714096b6b224e939c2d1e6e842.jpg',
    'https://i.pinimg.com/564x/a0/02/78/a0027883fe995b3bf3b44d71b355f8a8.jpg',
    'https://i.pinimg.com/564x/99/dd/28/99dd28115c9a95b0c09813763a511aca.jpg',
    'https://i.pinimg.com/564x/7a/52/67/7a5267576242661fbe79954bea91946c.jpg',
    'https://i.pinimg.com/736x/02/4a/5b/024a5b0df5d2c2462ff8c73bebb418f3.jpg',
  ];

  DateTime? _selectedBirthdate; // Variable to store the selected birthdate

  // Asynchronous method to handle user sign-up (account creation)
  void _signUp() async {
    // Validate that all fields are filled
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _dobController.text.isEmpty) {
      _showError(
          'Please fill in all the fields.'); // Display error if any field is empty
      return; // Exit the method early
    }

    try {
      // Attempt to create a new user with the provided email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text
            .trim(), // Trimming whitespace from email input
        password: _passwordController.text
            .trim(), // Trimming whitespace from password input
      );

      String uid = userCredential
          .user!.uid; // Receive the unique user ID from Firebase Auth

      // Store additional user data in Firestore under the 'users' collection with the user's UID as the document ID
      await _firestore.collection('users').doc(uid).set({
        'first_name': _firstNameController.text.trim(), // User's first name
        'last_name': _lastNameController.text.trim(), // User's last name
        'email': _emailController.text.trim(), // User's email
        'weight':
            double.parse(_weightController.text.trim()), // User's weight in kg
        'height':
            double.parse(_heightController.text.trim()), // User's height in cm
        'birthdate': _selectedBirthdate?.toIso8601String() ??
            '', // User's birthdate in ISO format
        'profilePicture': _profileImages[
            _selectedProfileImageIndex], // URL of the selected profile picture
        'created_at': Timestamp.now(), // Timestamp of account creation
        'friends': [], // Initialize an empty list for friends
        'sentRequests': [], // Initialize an empty list for sent friend requests
        'streakCount': 0, // Initialize streak count to zero
        'lastStreakDate': Timestamp.fromDate(
            DateTime(1970)), // Initialize last streak date to epoch
        'completedSessions':
            [], // Initialize an empty list for completed sessions
      });

      // Redirect the user to the TutorialPage after successful sign-up
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context, // Current BuildContext
        MaterialPageRoute(
          builder: (context) => const TutorialPage(), // Route to TutorialPage
        ),
      );
    } catch (e) {
      // If an error occurs during sign-up, display an error message
      _showError('Error while creating the account. Please try again.');
    }
  }

  // Method to display an error message using a SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), // Error message content
        backgroundColor: Colors.red, // Red background to indicate error
      ),
    );
  }

  // Asynchronous method to allow users to select their birthdate using a date picker
  Future<void> _selectBirthdate(BuildContext context) async {
    // Define the initial, first, and last dates for the date picker
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 20)); // 20 years ago
    DateTime firstDate = DateTime(1900); // Earliest selectable date
    DateTime lastDate = DateTime.now(); // Latest selectable date is today

    // Display the date picker dialog
    final DateTime? pickedDate = await showDatePicker(
      context: context, // Current BuildContext
      initialDate: _selectedBirthdate ?? initialDate, // Initial date selection
      firstDate: firstDate, // Earliest date selectable
      lastDate: lastDate, // Latest date selectable
    );

    if (pickedDate != null) {
      // If a date is picked, update the state with the selected date
      setState(() {
        _selectedBirthdate = pickedDate; // Store the selected date
        _dobController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}'; // Format the date for display
      });
    }
  }

  @override
  void dispose() {
    // Delete/clean all TextEditingControllers to free up resources
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dobController.dispose();
    super.dispose(); // Call the superclass's dispose method
  }

  @override
  Widget build(BuildContext context) {
    // Building the UI of the SignUpPage
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create an Account'), // App bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adding padding around the body
        child: SingleChildScrollView(
          // Allows the content to be scrollable if it overflows
          child: Column(
            children: [
              // First Name Input Field
              TextField(
                controller:
                    _firstNameController, // Linking to firstNameController
                decoration: const InputDecoration(
                    labelText: 'First Name'), // Placeholder label
              ),
              // Last Name Input Field
              TextField(
                controller:
                    _lastNameController, // Linking to lastNameController
                decoration: const InputDecoration(
                    labelText: 'Last Name'), // Placeholder label
              ),
              // Email Input Field
              TextField(
                controller: _emailController, // Linking to emailController
                decoration: const InputDecoration(
                    labelText: 'Email'), // Placeholder label
                keyboardType: TextInputType
                    .emailAddress, // Optimizing keyboard for email input
              ),
              // Password Input Field
              TextField(
                controller:
                    _passwordController, // Linking to passwordController
                decoration: const InputDecoration(
                    labelText: 'Password'), // Placeholder label
                obscureText: true, // Hiding the password input for security
              ),
              // Weight Input Field
              TextField(
                controller: _weightController, // Linking to weightController
                decoration: const InputDecoration(
                    labelText: 'Weight (kg)'), // Placeholder label
                keyboardType: TextInputType
                    .number, // Optimizing keyboard for numeric input
              ),
              // Height Input Field
              TextField(
                controller: _heightController, // Linking to heightController
                decoration: const InputDecoration(
                    labelText: 'Height (cm)'), // Placeholder label
                keyboardType: TextInputType
                    .number, // Optimizing keyboard for numeric input
              ),
              // Birthdate Input Field with Calendar Picker
              GestureDetector(
                onTap: () => _selectBirthdate(
                    context), // Trigger the birthdate picker on tap
                child: AbsorbPointer(
                  // Prevents the TextField from being directly editable
                  child: TextField(
                    controller: _dobController, // Linking to dobController
                    decoration: const InputDecoration(
                      labelText: 'Birthdate', // Placeholder label
                      hintText: 'DD/MM/YYYY', // Hint text for date format
                    ),
                  ),
                ),
              ),
              const SizedBox(
                  height:
                      20), // Adding vertical space between fields and profile picture section

              // Profile Picture Selection Section
              const Text(
                'Select a Profile Picture',
                style: TextStyle(fontSize: 16), // Styling the text
              ),
              const SizedBox(
                  height: 10), // Adding vertical space before profile images

              // Horizontally scrollable list of profile images
              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal, // Scrolling direction set to horizontal
                child: Row(
                  children: List.generate(_profileImages.length, (index) {
                    // Generating a list of profile image widgets
                    return GestureDetector(
                      onTap: () {
                        // Update the selected profile image index when an image is tapped
                        setState(() {
                          _selectedProfileImageIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal:
                                8.0), // Adding horizontal margin between images
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedProfileImageIndex == index
                                ? Colors
                                    .yellow // Highlight border color if selected
                                : Colors
                                    .transparent, // Transparent border if not selected
                            width: 3, // Border width
                          ),
                          shape: BoxShape
                              .circle, // Circular shape for the container
                        ),
                        child: CircleAvatar(
                          radius: 30, // Radius of the CircleAvatar
                          backgroundImage: NetworkImage(_profileImages[
                              index]), // Setting the profile image
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(
                  height:
                      20), // Adding vertical space before the Create Account button

              // Create Account Button
              ElevatedButton(
                onPressed: _signUp, // Calling the _signUp method when pressed
                child: const Text('Create Account'), // Button label
              ),
            ],
          ),
        ),
      ),
    );
  }
}
