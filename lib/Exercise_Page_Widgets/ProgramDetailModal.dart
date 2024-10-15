// lib/Exercise_Page_Widgets/ProgramDetailModal.dart

import 'package:flutter/material.dart';

class ProgramDetailModal extends StatelessWidget {
  final String programName;
  final List<String> exercises;

  const ProgramDetailModal({
    super.key,
    required this.programName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            programName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          exercises.isEmpty
              ? const Text(
                  'No exercises added yet.',
                  style: TextStyle(color: Colors.white),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        exercises[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
