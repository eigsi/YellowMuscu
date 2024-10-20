// lib/Exercise_Page_Widgets/ProgramList.dart
import 'package:flutter/material.dart';

class ProgramList extends StatelessWidget {
  final List<Map<String, dynamic>> programs;
  final Function(String) onProgramTap;

  const ProgramList({
    super.key,
    required this.programs,
    required this.onProgramTap,
  });

  @override
  Widget build(BuildContext context) {
    // Récupère le thème actuel
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return ListView.builder(
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return ListTile(
          leading: Icon(
            Icons.fitness_center,
            color:
                isDarkMode ? Colors.white : Colors.black, // Couleur adaptative
          ),
          title: Text(
            program['name'],
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white
                  : Colors.black, // Couleur adaptative
            ),
          ),
          onTap: () => onProgramTap(program['name']),
          trailing: Icon(
            isDarkMode ? Icons.arrow_forward_ios : Icons.arrow_forward,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          // Optionnel : Ajouter un fond au survol ou au clic
          tileColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        );
      },
    );
  }
}
