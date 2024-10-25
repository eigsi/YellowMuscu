import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';

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
  bool _hasChanges = false; // Variable to track changes

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

  void _showRestTimePicker(BuildContext context, int currentRestTime,
      ValueChanged<int> onRestTimeChanged) {
    int currentMinutes = currentRestTime ~/ 60; // Minutes initiales
    int currentSeconds = currentRestTime % 60; // Secondes initiales

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Picker pour les minutes
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: currentMinutes, // Valeur initiale en minutes
                  ),
                  onSelectedItemChanged: (int value) {
                    currentMinutes = value; // Mettre à jour les minutes
                  },
                  children: List<Widget>.generate(
                    61, // Limite à 60 minutes
                    (int index) {
                      return Text('$index min');
                    },
                  ),
                ),
              ),
              // Picker pour les secondes
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem:
                        currentSeconds ~/ 10, // Valeur initiale en secondes
                  ),
                  onSelectedItemChanged: (int value) {
                    currentSeconds = value *
                        10; // Mettre à jour les secondes (par tranches de 10)
                  },
                  children: List<Widget>.generate(
                    6, // Limite à 50 secondes (de 0 à 50 par tranche de 10)
                    (int index) {
                      return Text('${index * 10} sec');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Lorsque le picker est fermé, envoyer la valeur totale en secondes
      int totalTimeInSeconds = (currentMinutes * 60) + currentSeconds;
      onRestTimeChanged(totalTimeInSeconds);
    });
  }

  void _showInputPicker(BuildContext context, String title, int initialValue,
      int minValue, int maxValue, int step, ValueChanged<int> onValueChanged) {
    int currentValue = initialValue;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 20)),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: (currentValue - minValue) ~/ step,
                  ),
                  onSelectedItemChanged: (int value) {
                    currentValue = minValue +
                        value * step; // Mise à jour de la valeur sélectionnée
                  },
                  children: List<Widget>.generate(
                    ((maxValue - minValue) ~/ step) + 1,
                    (int index) {
                      return Text('${minValue + index * step}');
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Envoyer la nouvelle valeur sélectionnée
      onValueChanged(currentValue);
    });
  }

  void _editExercise(int index) {
    final exercise = exercises[index];
    int sets = exercise['sets'];
    int reps = exercise['reps'];
    double weight = exercise['weight'] ?? 0.0;
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
                // Séries
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Séries:'),
                    GestureDetector(
                      onTap: () {
                        _showInputPicker(
                          context,
                          'Séries',
                          sets,
                          1,
                          99,
                          1,
                          (newSets) {
                            setState(() {
                              sets = newSets;
                            });
                          },
                        );
                      },
                      child: Text('$sets séries'),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Espace entre les données
                // Répétitions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Répétitions:'),
                    GestureDetector(
                      onTap: () {
                        _showInputPicker(
                          context,
                          'Répétitions',
                          reps,
                          1,
                          99,
                          1,
                          (newReps) {
                            setState(() {
                              reps = newReps;
                            });
                          },
                        );
                      },
                      child: Text('$reps répétitions'),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Espace entre les données
                // Poids
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Poids (kg):'),
                    GestureDetector(
                      onTap: () {
                        _showInputPicker(
                          context,
                          'Poids (kg)',
                          weight.toInt(),
                          0,
                          500,
                          1,
                          (newWeight) {
                            setState(() {
                              weight = newWeight.toDouble();
                            });
                          },
                        );
                      },
                      child: Text('$weight kg'),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Espace entre les données
                // Repos entre séries avec le picker Apple-style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Repos entre séries:'),
                    GestureDetector(
                      onTap: () {
                        _showRestTimePicker(context, restTime, (newRestTime) {
                          setState(() {
                            restTime = newRestTime;
                          });
                        });
                      },
                      child: Text(_formatDuration(restTime)),
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
                onPressed: () async {
                  setState(() {
                    // Mettre à jour les valeurs de l'exercice après modification
                    exercises[index]['sets'] = sets;
                    exercises[index]['reps'] = reps;
                    exercises[index]['weight'] = weight;
                    exercises[index]['restTime'] = restTime;
                  });

                  // Sauvegarder les modifications
                  await _saveExercises();

                  // Indiquer que des changements ont été effectués
                  _hasChanges = true;

                  // Fermer la page et retourner à la page précédente
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      _saveExercises(); // Sauvegarde des données après fermeture du modal
    });
  }

  void _changeRestBetweenExercises(int index, int change) {
    setState(() {
      int newRest =
          (exercises[index]['restBetweenExercises'] + change).clamp(0, 3600);
      exercises[index]['restBetweenExercises'] = newRest;
      _hasChanges = true; // Indiquer que des changements ont été effectués
    });
    _saveExercises();
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
      _hasChanges = true; // Indiquer que des changements ont été effectués
    });
  }

  void _toggleEditingOrder() {
    setState(() {
      _isEditingOrder = !_isEditingOrder;
      if (!_isEditingOrder) {
        _saveExercises();
        if (!_hasChanges) {
          _hasChanges = true; // Indiquer que des changements ont été effectués
        }
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds sec';
    } else {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      String minutesPart = '$minutes min${minutes > 1 ? 's' : ''}';
      String secondsPart = seconds > 0 ? ' $seconds sec' : '';
      return secondsPart.isNotEmpty ? '$minutesPart $secondsPart' : minutesPart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black54 : null,
          title: Text(widget.program['name']),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_hasChanges);
            },
          ),
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
                              _hasChanges =
                                  true; // Indiquer que des changements ont été effectués
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
                            child:
                                const Icon(Icons.delete, color: Colors.white),
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
      ),
    );
  }
}
