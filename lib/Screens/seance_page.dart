import 'package:flutter/material.dart';

class SeancePage extends StatelessWidget {
  // Sample list of programs
  final List<String> _programs = [
    'Program 1: Full Body Workout',
    'Program 2: Upper Body Strength',
    'Program 3: Lower Body Burn',
    'Program 4: Cardio Blast',
    'Program 5: HIIT Routine',
    'Program 6: Core Training',
    'Program 7: Flexibility and Stretching',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a program for your session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _programs.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(_programs[index]),
                      onTap: () {
                        // Handle program selection
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Program Selected'),
                            content: Text('You selected: ${_programs[index]}'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
