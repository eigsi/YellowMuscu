// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/login_page.dart'; // Met à jour l'import pour LoginPage
import 'package:yellowmuscu/Screens/main_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Import de ThemeProvider

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
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'YellowMuscu',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: isDarkMode
            ? Colors.grey[900]
            : Colors.yellow, // Ajustez selon votre thème
        scaffoldBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.yellow,
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
          const AuthWrapper(), // Afficher LoginPage ou MainPage selon l'authentification
      routes: {
        '/login': (context) =>
            const LoginPage(), // Met à jour la route pour LoginPage
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
            return const LoginPage(); // Remplace SignInPage par LoginPage
          } else {
            return const MainPage(); // Redirige vers la page principale
          }
        }
        return const Scaffold(
          body: Center(
              child:
                  CircularProgressIndicator()), // Affiche un indicateur de chargement
        );
      },
    );
  }
}
