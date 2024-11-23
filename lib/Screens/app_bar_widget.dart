// lib/Screens/app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Screens/notifications_page.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  // Méthode pour afficher les notifications
  void _showNotifications(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Notifications",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 0),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const NotificationsPage();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Méthode pour afficher les réglages
  void _showSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final isDarkMode = ref.watch(themeProvider);
            return AlertDialog(
              title: const Text('Settings'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark Mode'),
                  Switch(
                    value: isDarkMode,
                    activeColor: lightTop,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).toggleTheme(value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDarkMode
                        ? Colors.white
                        : Colors.black, // Couleur du texte
                  ),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer l'état actuel du thème
    final isDarkMode = ref.watch(themeProvider);

    return AppBar(
      backgroundColor: isDarkMode ? darkTop : lightTop,
      shadowColor: Colors.black, // Shadow color remains noir
      elevation: 0, // Pas d'ombre
      centerTitle: true, // Centrer le titre
      title: Text(
        'YelloMuscu',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.person,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () {
          _showNotifications(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.settings,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            _showSettings(context, ref);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
