// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/login_page.dart';
import 'package:yellowmuscu/Screens/main_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        ref.watch(themeModeProvider); // Obtenir l'état du mode sombre

    // Définition des thèmes en fonction de l'état du mode sombre
    final ThemeData currentTheme = ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDarkMode ? darkBottom : lightBottom,
      appBarTheme: AppBarTheme(
        backgroundColor: isDarkMode ? darkTop : lightTop,
        titleTextStyle: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDarkMode ? darkNavBar : lightNavBar,
        selectedItemColor: isDarkMode ? darkWidget : lightWidget,
        unselectedItemColor: isDarkMode ? Colors.grey : Colors.black54,
      ),
    );

    return MaterialApp(
      title: 'YellowMuscu',
      theme: currentTheme, // Applique le thème courant
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
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
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          } else {
            return const MainPage();
          }
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
