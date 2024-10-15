// program_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramDetailPage extends StatefulWidget {
  final Map<String, dynamic> program;
  final String userId;
  final VoidCallback onUpdate;

  const ProgramDetailPage({
    Key? key,
    required this.program,
    required this.userId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  late List<Map<String, dynamic>> exercises;
  bool _isEditingOrder = false;

  @override
  void initState() {
    super.initState();
    exercises = List<Map<String, dynamic>>.from(widget.program['exercises']);
  }

  Future<void> _saveExercises() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('programs')
        .doc(widget.program['id'])
        .update({'exercises': exercises});

    widget.onUpdate();
  }

  void _editExercise(int index) {
    final exercise = exercises[index];
    final setsController =
        TextEditingController(text: exercise['sets'].toString());
    final repsController =
        TextEditingController(text: exercise['reps'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${exercise['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Nombre de séries'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              decoration:
                  const InputDecoration(labelText: 'Nombre de répétitions'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              setState(() {
                exercises[index]['sets'] = int.parse(setsController.text);
                exercises[index]['reps'] = int.parse(repsController.text);
              });
              _saveExercises();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _changeRestTime(int index, int change) {
    setState(() {
      exercises[index]['restTime'] =
          (exercises[index]['restTime'] + change).clamp(0, 600);
    });
    _saveExercises();
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
    });
  }

  void _toggleEditingOrder() {
    setState(() {
      _isEditingOrder = !_isEditingOrder;
    });
    if (!_isEditingOrder) {
      _saveExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program['name']),
        actions: [
          IconButton(
            icon: Icon(_isEditingOrder ? Icons.check : Icons.reorder),
            onPressed: _toggleEditingOrder,
          ),
        ],
      ),
      body: _isEditingOrder
          ? ReorderableListView(
              onReorder: _reorderExercises,
              children: [
                for (int index = 0; index < exercises.length; index++)
                  ListTile(
                    key: ValueKey(exercises[index]),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(exercises[index]['image']),
                    ),
                    title: Text(exercises[index]['name']),
                    trailing: const Icon(Icons.drag_handle),
                  ),
              ],
            )
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(exercise['image']),
                      ),
                      title: Text(exercise['name']),
                      subtitle: Text(
                          '${exercise['sets']} séries x ${exercise['reps']} répétitions'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editExercise(index),
                      ),
                    ),
                    if (index < exercises.length - 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () =>
                                _changeRestTime(index, -10), // Diminue de 10s
                          ),
                          Text(
                            '${exercises[index]['restTime']} sec',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () =>
                                _changeRestTime(index, 10), // Augmente de 10s
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
    );
  }
}
