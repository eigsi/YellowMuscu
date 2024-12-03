// login_page.dart

// Importing necessary packages for Flutter and Firebase functionalities
import 'package:flutter/material.dart'; // Provides Flutter's Material Design widgets
import 'package:firebase_auth/firebase_auth.dart'; // Provides Firebase Authentication functionalities

// Defining the LoginPage as a StatefulWidget to manage dynamic state changes
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() =>
      _LoginPageState(); // Creates the mutable state for LoginPage
}

// The state class associated with LoginPage
class _LoginPageState extends State<LoginPage> {
  // Controllers to capture user input from TextFields
  final TextEditingController emailController =
      TextEditingController(); // Controller for email input
  final TextEditingController passwordController =
      TextEditingController(); // Controller for password input

  // Variable to track loading state (used to show a spinner while authenticating)
  bool _isLoading = false;

  // Method to validate input fields before performing login or sign-up
  bool _validateFields() {
    // Check if either email or password field is empty
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'), // Error message
          backgroundColor: Colors.red, // Red background for error
        ),
      );
      return false; // Validation failed
    }

    // Check if email format is valid
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'), // Error message
          backgroundColor: Colors.red,
        ),
      );
      return false; // Validation failed
    }

    // Check if password length is at least 6 characters
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Password must be at least 6 characters'), // Error message
          backgroundColor: Colors.red,
        ),
      );
      return false; // Validation failed
    }

    return true; // Validation passed
  }

  // Combined method for login and sign-up functionalities
  Future<void> _authenticate({required bool isSignUp}) async {
    // Validate input fields
    if (!_validateFields()) return;

    // Show loading spinner
    setState(() {
      _isLoading = true;
    });

    try {
      if (isSignUp) {
        // Create a new user with Firebase Authentication
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // Log in an existing user with Firebase Authentication
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      // Navigate to the main page after successful authentication
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/mainPage');
    } catch (e) {
      // Handle errors and display specific error messages
      String errorMessage = 'An error occurred'; // Default error message
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage =
                'No user found with this email.'; // Error message for non-existent user
            break;
          case 'wrong-password':
            errorMessage =
                'Incorrect password.'; // Error message for wrong password
            break;
          case 'email-already-in-use':
            errorMessage =
                'This email is already in use.'; // Error message for email already registered
            break;
          case 'weak-password':
            errorMessage =
                'Password is too weak.'; // Error message for weak password
            break;
          default:
            errorMessage =
                e.message ?? 'Authentication error'; // Fallback error message
        }
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage), // Display the error message
          backgroundColor: Colors.red, // Red background for error
        ),
      );
    } finally {
      // Hide loading spinner
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Building the UI of the LoginPage
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'), // Title displayed in the app bar
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(), // Show loading spinner if authenticating
            )
          : Padding(
              padding:
                  const EdgeInsets.all(16.0), // Add padding around the body
              child: Column(
                children: [
                  // TextField for email input
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                        labelText: 'Email'), // Label for the email field
                    keyboardType:
                        TextInputType.emailAddress, // Show email keyboard
                  ),
                  // TextField for password input
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Hide the password input for security
                    decoration: const InputDecoration(
                        labelText: 'Password'), // Label for the password field
                  ),
                  const SizedBox(
                      height:
                          20), // Add vertical space between fields and buttons
                  // Button to initiate login
                  ElevatedButton(
                    onPressed: () =>
                        _authenticate(isSignUp: false), // Trigger login
                    child: const Text('Login'),
                  ),
                  const SizedBox(
                      height: 10), // Add vertical space between buttons
                  // Button to initiate sign-up
                  ElevatedButton(
                    onPressed: () =>
                        _authenticate(isSignUp: true), // Trigger sign-up
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources when the widget is removed
    emailController.dispose();
    passwordController.dispose();
    super.dispose(); // Call the superclass's dispose method
  }
}
