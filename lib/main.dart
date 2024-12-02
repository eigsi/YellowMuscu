// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/authentification/sign_in_page.dart';
import 'package:yellowmuscu/authentification/sign_up_page.dart';
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
          const AuthWrapper(), // Afficher SignIn ou MainPage selon l'authentification
      routes: {
        '/signIn': (context) => const SignInPage(),
        '/signUp': (context) => const SignUpPage(),
        '/mainPage': (context) => const MainPage(),
        // Supprimez la route '/tutorial' pour éviter l'erreur
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  // Convertir AuthWrapper en StatelessWidget
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si l'utilisateur est authentifié, afficher MainPage
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const SignInPage(); // Afficher SignInPage si non authentifié
          } else {
            return const MainPage(); // Afficher MainPage si authentifié
          }
        }

        // Sinon, afficher un indicateur de chargement
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
