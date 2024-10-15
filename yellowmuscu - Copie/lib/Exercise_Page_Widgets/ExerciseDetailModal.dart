// lib/Exercise_Page_Widgets/ExerciseDetailModal.dart

import 'package:flutter/material.dart';

class ExerciseDetailModal extends StatelessWidget {
  final String category;
  final List<Map<String, String>> exercises;
  final Function(String) onAddToProgram;

  const ExerciseDetailModal({
    Key? key,
    required this.category,
    required this.exercises,
    required this.onAddToProgram,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(exercise['image']!),
                ),
                title: Text(
                  exercise['name']!,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => onAddToProgram(exercise['name']!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
