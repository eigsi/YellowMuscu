import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Light mode
const Color lightTop = Color.fromRGBO(255, 212, 41, 1);
const Color lightBottom = Color.fromRGBO(255, 227, 134, 1);
const Color lightNavBar = Color.fromRGBO(255, 243, 187, 1);
const Color lightWidget = Color.fromRGBO(255, 255, 255, 1);

// Dark mode
const Color darkTop = Color.fromRGBO(20, 20, 20, 1);
const Color darkBottom = Color.fromRGBO(30, 30, 30, 1);
const Color darkNavBar = Color.fromRGBO(20, 20, 20, 1);
const Color darkWidget = Color.fromRGBO(255, 227, 134, 1);

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// Classe qui gère l'état du thème
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false);

  void toggleTheme(bool isDarkMode) {
    state = isDarkMode;
  }
}
