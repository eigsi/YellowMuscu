import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight); // Standard app bar height

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(
          255, 204, 0, 1.0), // Yellow background for the Scaffold
      appBar: AppBar(
        backgroundColor:
            Colors.black.withOpacity(0.3), // Overlay black with opacity
        shadowColor: Colors.black, // Shadow color
        elevation: 0, // No shadow
        centerTitle: true, // Center the title
        title: const Text(
          'YelloMuscu',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Title color
          ),
        ),
      ),
    );
  }
}
