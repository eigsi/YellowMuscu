// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Définir les couleurs personnalisées pour l'AppBar
// Couleur de l'AppBar en mode clair
const Color appBarLightColor = Color.fromRGBO(154, 123, 24, 1.0);

// Couleur de l'AppBar en mode sombre
Color appBarDarkColor = const Color.fromRGBO(66, 53, 4, 1); // Gris foncé

// Fournisseur d'état pour le thème
// `themeProvider` est un `StateNotifierProvider` qui gère l'état du thème de l'application
// Il utilise `ThemeNotifier` pour notifier les modifications de thème
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// Classe qui gère l'état du thème
class ThemeNotifier extends StateNotifier<bool> {
  // Initialise le thème en mode clair (false)
  ThemeNotifier() : super(false);

  // Méthode pour basculer le thème
  // `isDarkMode` est un booléen qui, lorsqu'il est vrai, active le mode sombre
  void toggleTheme(bool isDarkMode) {
    state =
        isDarkMode; // Met à jour l'état pour activer/désactiver le mode sombre
  }
}
