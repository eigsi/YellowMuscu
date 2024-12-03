// login_page.dart

// Importing necessary packages for Flutter and Firebase functionalities
import 'package:flutter/material.dart'; // Provides Flutter's Material Design widgets
import 'package:firebase_auth/firebase_auth.dart'; // Provides Firebase Authentication functionalities
import 'package:yellowmuscu/authentification/sign_up_page.dart'; // Importing the SignUpPage

// Defining the LoginPage as a StatefulWidget to manage dynamic state changes
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() =>
      _LoginPageState(); // Creates the mutable state for LoginPage
}

// The state class associated with LoginPage
class _LoginPageState extends State<LoginPage> {
  // Controllers to capture user input from TextFields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variable to track loading state (used to show a spinner while authenticating)
  bool _isLoading = false;

  // Method to validate input fields before performing login
  bool _validateFields() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'), // Error message
          backgroundColor: Colors.red, // Red background for error
        ),
      );
      return false; // Validation failed
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'), // Error message
          backgroundColor: Colors.red,
        ),
      );
      return false; // Validation failed
    }

    return true; // Validation passed
  }

  // Method to log in an existing user
  Future<void> _login() async {
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Navigate to the main page after successful login
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/mainPage');
    } catch (e) {
      String errorMessage = 'An error occurred';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          default:
            errorMessage = e.message ?? 'Authentication error';
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
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _login, // Trigger login
                    child: const Text('Login'),
                  ),
                  const SizedBox(
                      height: 10), // Add vertical space between buttons
                  // Button to navigate to SignUpPage
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const SignUpPage()), // Navigate to SignUpPage
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose(); // Call the superclass's dispose method
  }
}
