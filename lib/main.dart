import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/sign_in_page.dart';
import 'package:yellowmuscu/authentification/sign_up_page.dart'; // Import SignUpPage
import 'package:yellowmuscu/Screens/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YellowMuscu',
      home:
          const AuthWrapper(), // Show SignIn or MainPage based on authentication
      routes: {
        '/signIn': (context) => SignInPage(),
        '/signUp': (context) => SignUpPage(), // Register the SignUpPage route
        '/mainPage': (context) => const MainPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is authenticated, go to the main page
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignInPage(); // Show SignInPage if not authenticated
          } else {
            return const MainPage(); // Show MainPage if authenticated
          }
        }

        // Otherwise, show a loading spinner
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
