// lib/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Définir les couleurs personnalisées pour l'AppBar
const Color appBarLightColor = Color.fromRGBO(154, 123, 24, 1.0);

Color appBarDarkColor = Color.fromRGBO(66, 53, 4, 1); // Gris foncé

// Fournisseur d'état pour le thème
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false);

  void toggleTheme(bool isDarkMode) {
    state = isDarkMode;
  }
}
