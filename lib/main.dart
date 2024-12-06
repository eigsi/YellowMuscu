// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/login_page.dart';
import 'package:yellowmuscu/Screens/main_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure proper initialization of Flutter binding

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      // Wrap the application with ProviderScope for managing providers
      child: MyApp(),
    ),
  );
}

// Root widget of the application
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme state (dark mode or light mode)
    final isDarkMode = ref.watch(themeModeProvider);

    // Define the application's theme dynamically based on the dark mode state
    final ThemeData currentTheme = ThemeData(
      brightness:
          isDarkMode ? Brightness.dark : Brightness.light, // Set brightness
      scaffoldBackgroundColor: Colors.white, // Set scaffold background color
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDarkMode ? darkTop : lightTop, // AppBar background color
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black, // Title text color
          fontSize: 22, // Font size of AppBar title
          fontWeight: FontWeight.bold, // Font weight of AppBar title
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black, // Icon color
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkMode
            ? darkNavBar
            : lightNavBar, // BottomNavigationBar background color
        selectedItemColor:
            isDarkMode ? darkWidget : lightWidget, // Color for selected items
        unselectedItemColor: isDarkMode
            ? Colors.grey
            : Colors.black54, // Color for unselected items
      ),
    );

    // Build MaterialApp with the current theme and routing configurations
    return MaterialApp(
      title: 'YellowMuscu', // Application title
      theme: currentTheme, // Apply the dynamically defined theme
      home:
          const AuthWrapper(), // Display authentication wrapper as the home page
      routes: {
        '/login': (context) => const LoginPage(), // Route for the login page
        '/mainPage': (context) => const MainPage(), // Route for the main page
      },
    );
  }
}

// Widget to handle authentication state and navigate accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Listen to authentication state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          // If the connection to the stream is active
          final user = snapshot.data;
          if (user == null) {
            // If no user is authenticated, show the login page
            return const LoginPage();
          } else {
            // If a user is authenticated, navigate to the main page
            return const MainPage();
          }
        }
        // Display a loading indicator while waiting for authentication state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(), // Show a spinner
          ),
        );
      },
    );
  }
}
