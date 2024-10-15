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
    return ListView.builder(
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center, color: Colors.black),
          title: Text(program['name']),
          onTap: () => onProgramTap(program['name']),
        );
      },
    );
  }
}
