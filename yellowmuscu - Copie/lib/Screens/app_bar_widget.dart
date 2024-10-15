// import 'package:flutter/material.dart';

// class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   const AppBarWidget({super.key});

//   @override
//   Size get preferredSize =>
//       const Size.fromHeight(kToolbarHeight); // Standard app bar height

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromRGBO(
//           255, 204, 0, 1.0), // Yellow background for the Scaffold
//       appBar: AppBar(
//         backgroundColor:
//             Colors.black.withOpacity(0.3), // Overlay black with opacity
//         shadowColor: Colors.black, // Shadow color
//         elevation: 0, // No shadow
//         centerTitle: true, // Center the title
//         title: const Text(
//           'YelloMuscu',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.black, // Title color
//           ),
//         ),
//       ),
//     );
//   }
// }

// // app_bar_widget.dart

// import 'package:flutter/material.dart';
// import 'package:yellowmuscu/Screens/notifications_page.dart';

// class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
//   const AppBarWidget({super.key});

//   void _showNotifications(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return NotificationsPage();
//       },
//     );
//   }

//   @override
//   Size get preferredSize => Size.fromHeight(kToolbarHeight);

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       leading: IconButton(
//         icon: const Icon(Icons.person),
//         onPressed: () {
//           _showNotifications(context);
//         },
//       ),
//       title: const Text('Votre Titre d\'Application'),
//       centerTitle: true,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:yellowmuscu/Screens/notifications_page.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
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

  // Taille de l'AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 204, 0, 1.0), // Fond jaune
      appBar: AppBar(
        backgroundColor:
            Colors.black.withOpacity(0.3), // Couleur noire avec opacité
        shadowColor: Colors.black, // Couleur de l'ombre
        elevation: 0, // Pas d'ombre
        centerTitle: true, // Centrer le titre
        title: const Text(
          'YelloMuscu',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Couleur du titre
          ),
        ),
        // Icône 'profile' à gauche pour ouvrir la page de notifications
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            _showNotifications(context); // Ouvre la pop-up des notifications
          },
        ),
      ),
      body: Container(), // Contenu principal de la page (vous pouvez l'adapter)
    );
  }
}
