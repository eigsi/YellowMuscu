import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart'; // Import your profile page
import 'login_page.dart'; // Import login page

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          // Check if user is signed in
          if (user == null) {
            return LoginPage(); // Show login page if not logged in
          }
          return ProfilePage(); // Show profile page if logged in
        } else {
          return CircularProgressIndicator(); // Show loading spinner
        }
      },
    );
  }
}
