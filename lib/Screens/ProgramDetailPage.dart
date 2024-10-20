import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

class ProgramDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> program;
  final String userId;
  final VoidCallback onUpdate;

  const ProgramDetailPage({
    super.key,
    required this.program,
    required this.userId,
    required this.onUpdate,
  });

  @override
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends ConsumerState<ProgramDetailPage> {
  late List<Map<String, dynamic>> exercises;
  bool _isEditingOrder = false;

  @override
  void initState() {
    super.initState();
    exercises = List<Map<String, dynamic>>.from(widget.program['exercises']);

    for (var exercise in exercises) {
      if (!exercise.containsKey('restBetweenExercises')) {
        exercise['restBetweenExercises'] = 60;
      }
      if (!exercise.containsKey('restTime')) {
        exercise['restTime'] = 60;
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

    final isDarkMode = ref.watch(themeProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
            title: Text(
              'Modifier ${exercise['name']}',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: setsController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de séries',
                    labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: repsController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de répétitions',
                    labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Poids (kg)',
                    labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Repos entre séries: ${_formatDuration(restTime)}',
                  style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          restTime = (restTime - 10).clamp(0, 3600);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          restTime = (restTime + 10).clamp(0, 3600);
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
      int newRest =
          (exercises[index]['restBetweenExercises'] + change).clamp(0, 3600);
      exercises[index]['restBetweenExercises'] = newRest;
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

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds sec';
    } else {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      String minutesPart = '$minutes min${minutes > 1 ? 's' : ''}';
      String secondsPart = seconds > 0 ? ' $seconds sec' : '';
      return '$minutesPart$secondsPart';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black54 : null,
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
                style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white70 : Colors.black54),
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
                          title: Text(
                            exercises[index]['name'],
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
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
                          title: Text(
                            exercise['name'],
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
                          subtitle: Text(
                            '${exercise['sets']} séries x ${exercise['reps']} répétitions\n'
                            'Poids: ${exercise['weight'] ?? 0} kg\n'
                            'Repos entre séries: ${_formatDuration(exercise['restTime'] ?? 60)}',
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                          ),
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
                                    _changeRestBetweenExercises(index, -10),
                              ),
                              Text(
                                'Repos entre exercices: ${_formatDuration(exercises[index]['restBetweenExercises'])}',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () =>
                                    _changeRestBetweenExercises(index, 10),
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
