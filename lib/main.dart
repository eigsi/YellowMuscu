// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/sign_in_page.dart';
import 'package:yellowmuscu/authentification/sign_up_page.dart';
import 'package:yellowmuscu/Screens/main_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Import ThemeProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      // Envelopper l'application avec ProviderScope
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  // Convertir MyApp en ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'YellowMuscu',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: isDarkMode
            ? Colors.grey[900]
            : const Color.fromRGBO(255, 204, 0, 1.0),
        scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: isDarkMode ? appBarDarkColor : appBarLightColor,
          titleTextStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
      home:
          const AuthWrapper(), // Show SignIn or MainPage based on authentication
      routes: {
        '/signIn': (context) => const SignInPage(),
        '/signUp': (context) =>
            const SignUpPage(), // Register the SignUpPage route
        '/mainPage': (context) => const MainPage(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  // Convertir AuthWrapper en ConsumerWidget
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is authenticated, go to the main page
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const SignInPage(); // Show SignInPage if not authenticated
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
