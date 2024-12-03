// // login_page.dart

// // Importing necessary packages for Flutter and Firebase functionalities
// import 'package:flutter/material.dart'; // Flutter's material design widgets
// import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package
// import '../Screens/profile_page.dart'; // Importing the ProfilePage screen

// // Defining the LoginPage as a StatefulWidget to manage dynamic state changes
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   // Creating the mutable state for this widget
//   // ignore: library_private_types_in_public_api
//   _LoginPageState createState() => _LoginPageState();
// }

// // The state class associated with LoginPage
// class _LoginPageState extends State<LoginPage> {
//   // Controllers to capture user input from TextFields
//   final TextEditingController emailController =
//       TextEditingController(); // Controller for email input
//   final TextEditingController passwordController =
//       TextEditingController(); // Controller for password input

//   // Asynchronous method to handle user login
//   Future<void> _login() async {
//     try {
//       // Attempting to sign in with the provided email and password
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email:
//             emailController.text.trim(), // Trimming whitespace from email input
//         password: passwordController.text
//             .trim(), // Trimming whitespace from password input
//       );

//       // If sign-in is successful, navigate to the ProfilePage and replace the current page
//       Navigator.pushReplacement(
//         // ignore: use_build_context_synchronously
//         context, // Current BuildContext
//         MaterialPageRoute(
//             builder: (context) => const ProfilePage()), // Route to ProfilePage
//       );
//     } catch (e) {
//       // If an error occurs during sign-in, display a SnackBar with an error message
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Password or email error, try again'), // Error message
//           backgroundColor: Colors.red, // Red background to indicate error
//         ),
//       );
//     }
//   }

//   // Asynchronous method to handle user sign-up (account creation)
//   Future<void> _signUp() async {
//     try {
//       // Attempting to create a new user with the provided email and password
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email:
//             emailController.text.trim(), // Trimming whitespace from email input
//         password: passwordController.text
//             .trim(), // Trimming whitespace from password input
//       );

//       // If sign-up is successful, navigate to the ProfilePage and replace the current page
//       Navigator.pushReplacement(
//         // ignore: use_build_context_synchronously
//         context, // Current BuildContext
//         MaterialPageRoute(
//             builder: (context) => const ProfilePage()), // Route to ProfilePage
//       );
//     } catch (e) {
//       // If an error occurs during sign-up, display a SnackBar with an error message
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//               'Sign-up failed, please retry'), // Error message (translated to English)
//           backgroundColor: Colors.red, // Red background to indicate error
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Building the UI of the LoginPage
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login'), // App bar title
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0), // Adding padding around the body
//         child: Column(
//           children: [
//             // TextField for user to input their email
//             TextField(
//               controller: emailController, // Linking to emailController
//               decoration: const InputDecoration(
//                   labelText: 'Email'), // Placeholder label
//               keyboardType: TextInputType
//                   .emailAddress, // Optimizing keyboard for email input
//             ),
//             // TextField for user to input their password
//             TextField(
//               controller: passwordController, // Linking to passwordController
//               obscureText: true, // Hiding the password input for security
//               decoration: const InputDecoration(
//                   labelText: 'Password'), // Placeholder label
//             ),
//             const SizedBox(
//                 height: 20), // Adding vertical space between fields and buttons
//             // ElevatedButton for user to initiate login
//             ElevatedButton(
//               onPressed: _login, // Calling the _login method when pressed
//               child: const Text('Login'), // Button label
//             ),
//             const SizedBox(height: 10), // Adding vertical space between buttons
//             // ElevatedButton for user to initiate sign-up (create a new account)
//             ElevatedButton(
//               onPressed: _signUp, // Calling the _signUp method when pressed
//               child: const Text('Create Account'), // Button label
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// login_page.dart

// Importing necessary packages for Flutter and Firebase functionalities
import 'package:flutter/material.dart'; // Flutter's material design widgets
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication package

// Defining the LoginPage as a StatefulWidget to manage dynamic state changes
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

// The state class associated with LoginPage
class _LoginPageState extends State<LoginPage> {
  // Controllers to capture user input from TextFields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variable to track loading state
  bool _isLoading = false;

  // Method to validate input fields
  bool _validateFields() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Combined method for login and signup
  Future<void> _authenticate({required bool isSignUp}) async {
    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (isSignUp) {
        // Create a new user
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // Sign in an existing user
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      // Navigate to the main page after success
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/mainPage');
    } catch (e) {
      // Handle errors and display specific messages
      String errorMessage = 'An error occurred';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak.';
            break;
          default:
            errorMessage = e.message ?? 'Authentication error';
        }
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
        title: const Text('Login'), // App bar title
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner when authenticating
          : Padding(
              padding:
                  const EdgeInsets.all(16.0), // Adding padding around the body
              child: Column(
                children: [
                  // TextField for user to input their email
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  // TextField for user to input their password
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Hiding the password input for security
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(
                      height:
                          20), // Adding vertical space between fields and buttons
                  // ElevatedButton for user to initiate login
                  ElevatedButton(
                    onPressed: () => _authenticate(isSignUp: false),
                    child: const Text('Login'),
                  ),
                  const SizedBox(
                      height: 10), // Adding vertical space between buttons
                  // ElevatedButton for user to initiate sign-up
                  ElevatedButton(
                    onPressed: () => _authenticate(isSignUp: true),
                    child: const Text('Create Account'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers to free up resources
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
