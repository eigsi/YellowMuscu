import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Light mode
const Color lightTop = Color.fromRGBO(255, 212, 41, 1);
const Color lightBottom = Color.fromRGBO(255, 224, 120, 1);
const Color lightNavBar = Color.fromRGBO(30, 30, 30, 1);
const Color lightWidget = Color.fromRGBO(255, 255, 255, 1);

// Dark mode
const Color darkTop = Color.fromRGBO(20, 20, 20, 1);
const Color darkBottom = Color.fromRGBO(30, 30, 30, 1);
const Color darkNavBar = Color.fromRGBO(20, 20, 20, 1);
const Color darkWidget = Color.fromRGBO(255, 212, 41, 1);

// Provider pour gérer l'état du mode sombre
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier();
});

// Provider pour gérer l'état de l'affichage
final displayProvider = StateNotifierProvider<DisplayNotifier, bool>((ref) {
  return DisplayNotifier();
});

// Classe qui gère l'état du mode sombre
class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier() : super(false);

  void toggleTheme(bool isDarkMode) {
    state = isDarkMode;
  }
}

// Classe qui gère l'état d'affichage
class DisplayNotifier extends StateNotifier<bool> {
  DisplayNotifier() : super(true);

  void toggleDisplay(bool isDisplay) {
    state = isDisplay;
  }
}
