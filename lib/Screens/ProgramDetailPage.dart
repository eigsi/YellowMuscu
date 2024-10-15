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

    // Initialiser 'restBetweenExercises' et 'restTime' pour chaque exercice si non présent
    for (var exercise in exercises) {
      if (!exercise.containsKey('restBetweenExercises')) {
        exercise['restBetweenExercises'] =
            60; // Temps de repos entre exercices par défaut
      }
      if (!exercise.containsKey('restTime')) {
        exercise['restTime'] = 60; // Temps de repos entre séries par défaut
      }
    }
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
    final weightController =
        TextEditingController(text: exercise['weight']?.toString() ?? '0');
    int restTime = exercise['restTime'] ?? 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Modifier ${exercise['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: setsController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de séries'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: repsController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de répétitions'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Repos entre séries: $restTime sec',
                  style: const TextStyle(fontSize: 16),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          restTime = (restTime - 10).clamp(0, 600);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          restTime = (restTime + 10).clamp(0, 600);
                        });
                      },
                    ),
                  ],
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
                    exercises[index]['weight'] =
                        double.parse(weightController.text);
                    exercises[index]['restTime'] = restTime;
                  });
                  _saveExercises();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _changeRestBetweenExercises(int index, int change) {
    setState(() {
      exercises[index]['restBetweenExercises'] =
          (exercises[index]['restBetweenExercises'] + change).clamp(0, 600);
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
      body: exercises.isEmpty
          ? Center(
              child: Text(
                'Aucun exercice ajouté au programme',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : _isEditingOrder
              ? ReorderableListView(
                  onReorder: _reorderExercises,
                  buildDefaultDragHandles: false,
                  children: [
                    for (int index = 0; index < exercises.length; index++)
                      Dismissible(
                        key: ValueKey(exercises[index]['id'] ?? index),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            final removedItem = exercises.removeAt(index);
                            _saveExercises();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${removedItem['name']} supprimé'),
                              ),
                            );
                          });
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(exercises[index]['image']),
                          ),
                          title: Text(exercises[index]['name']),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ),
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
                              '${exercise['sets']} séries x ${exercise['reps']} répétitions\nPoids: ${exercise['weight'] ?? 0} kg\nRepos entre séries: ${exercise['restTime'] ?? 60} sec'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editExercise(index),
                          ),
                        ),
                        // Afficher le temps de repos entre exercices sauf pour le dernier exercice
                        if (index < exercises.length - 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _changeRestBetweenExercises(
                                    index, -10), // Diminue de 10s
                              ),
                              Text(
                                'Repos entre exercices: ${exercises[index]['restBetweenExercises']} sec',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _changeRestBetweenExercises(
                                    index, 10), // Augmente de 10s
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
