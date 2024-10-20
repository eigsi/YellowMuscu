// lib/Screens/app_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Screens/notifications_page.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Assurez-vous du chemin correct

class AppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  // Méthode pour afficher les notifications
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const NotificationsPage();
      },
    );
  }

  // Méthode pour afficher les réglages
  void _showSettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Réglages'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode sombre'),
              Consumer(
                builder: (context, ref, child) {
                  final isDarkMode = ref.watch(themeProvider);
                  return Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).toggleTheme(value);
                      // Fermer le pop-up après le changement
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer l'état actuel du thème
    final isDarkMode = ref.watch(themeProvider);

    return AppBar(
      backgroundColor: isDarkMode ? appBarDarkColor : appBarLightColor,
      shadowColor: Colors.black, // Shadow color remains noir
      elevation: 0, // Pas d'ombre
      centerTitle: true, // Centrer le titre
      title: const Text(
        'YelloMuscu',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Le texte sera noir en mode clair
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
