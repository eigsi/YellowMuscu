// ExerciseSessionPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSessionPage extends StatefulWidget {
  final Map<String, dynamic> program;
  final String userId;
  final VoidCallback onSessionComplete;

  const ExerciseSessionPage({
    super.key,
    required this.program,
    required this.userId,
    required this.onSessionComplete,
  });

  @override
  _ExerciseSessionPageState createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  int _currentExerciseIndex = 0;
  int _currentSet = 0;
  bool _isResting = false;
  bool _isTimerRunning = true;
  late int _restTimeBetweenSets;
  late int _restTimeBetweenExercises;
  late int _timerSeconds;
  late Map<String, dynamic> _currentExercise;
  bool _isBetweenExercises = false;

  @override
  void initState() {
    super.initState();
    _currentExercise = widget.program['exercises'][_currentExerciseIndex];
    _restTimeBetweenExercises = _currentExercise['restBetweenExercises'] ?? 60;
    _restTimeBetweenSets = _currentExercise['restTime'] ?? 60;
    _timerSeconds = _restTimeBetweenSets;
  }

  void _startTimer() {
    if (_isResting && _isTimerRunning) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isTimerRunning && _timerSeconds > 0) {
          setState(() {
            _timerSeconds--;
          });
          _startTimer();
        } else if (_timerSeconds == 0) {
          _endRest();
        }
      });
    }
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _startTimer();
  }

  void _endRest() {
    if (_isBetweenExercises) {
      _isBetweenExercises = false;
      _moveToNextExercise();
    } else {
      setState(() {
        _isResting = false;
        _timerSeconds = _restTimeBetweenSets;
      });
    }
  }

  void _completeSet() {
    if (_currentSet < _currentExercise['sets'] - 1) {
      setState(() {
        _currentSet++;
        _isResting = true;
        _isTimerRunning = true;
        _timerSeconds = _restTimeBetweenSets;
      });
      _startTimer();
    } else {
      if (_currentExerciseIndex < widget.program['exercises'].length - 1) {
        setState(() {
          _currentSet = 0;
          _isResting = true;
          _isBetweenExercises = true;
          _isTimerRunning = true;
          _timerSeconds = _restTimeBetweenExercises;
        });
        _startTimer();
      } else {
        // Dernier exercice terminé, afficher l'écran "Des progrès ?"
        _showProgressScreen();
      }
    }
  }

  void _moveToNextExercise() {
    setState(() {
      _currentExerciseIndex++;
      _currentExercise = widget.program['exercises'][_currentExerciseIndex];
      _restTimeBetweenExercises =
          _currentExercise['restBetweenExercises'] ?? 60;
      _restTimeBetweenSets = _currentExercise['restTime'] ?? 60;
      _currentSet = 0;
      _isResting = false;
      _isBetweenExercises = false;
      _timerSeconds = _restTimeBetweenSets;
    });
  }

  Future<void> _showProgressScreen() async {
    await showDialog(
      context: context,
      barrierDismissible:
          false, // L'utilisateur doit appuyer sur "Valider" ou "Fermer"
      builder: (context) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade200, Colors.yellow.shade600],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Des progrès ?',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.program['exercises'].length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> exercise =
                                widget.program['exercises'][index];
                            if (exercise['weight'] == null) {
                              exercise['weight'] = 0;
                            }
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12), // Coins arrondis
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 0),
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(exercise['name'] ?? ''),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () async {
                                          setState(() {
                                            if (exercise['weight'] > 0) {
                                              exercise['weight'] -= 1;
                                            }
                                          });
                                          await _updateExerciseWeight(
                                              index, exercise['weight']);
                                        },
                                      ),
                                      Text('${exercise['weight']} kg'),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () async {
                                          setState(() {
                                            exercise['weight'] += 1;
                                          });
                                          await _updateExerciseWeight(
                                              index, exercise['weight']);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Marquer le programme comme terminé
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('programs')
                                .doc(widget.program['id'])
                                .update({'isDone': true});

                            widget.onSessionComplete();

                            // Appeler la méthode pour mettre à jour le streak
                            await _checkAndUpdateStreak();

                            Navigator.of(context)
                                .pop(); // Fermer le popup "Des progrès ?"
                            _showCongratulationDialog();
                          },
                          child: const Text('Valider'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Fermer le popup

                            // Utiliser Future.delayed pour s'assurer que le popup est fermé avant de naviguer
                            Future.delayed(Duration.zero, () {
                              Navigator.of(context)
                                  .pop(); // Retourner à la page ExercicePage
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .grey, // Optionnel: changer la couleur du bouton
                          ),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateExerciseWeight(int index, int weight) async {
    widget.program['exercises'][index]['weight'] = weight;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('programs')
        .doc(widget.program['id'])
        .update({
      'exercises': widget.program['exercises'],
    });
  }

  Future<void> _checkAndUpdateStreak() async {
    // Vérifier si toutes les séances de la semaine sont terminées
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('programs')
        .get();

    bool allProgramsDone = snapshot.docs.every((doc) => doc['isDone'] == true);

    if (allProgramsDone) {
      // Récupérer la dernière date de streak
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      DateTime lastStreakDate =
          userDoc['lastStreakDate']?.toDate() ?? DateTime.now();

      // Si le dernier streak date d'hier, incrémenter le compteur
      if (DateTime.now().difference(lastStreakDate).inDays == 1) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'streakCount': FieldValue.increment(1),
          'lastStreakDate': Timestamp.now(),
        });
      } else if (DateTime.now().difference(lastStreakDate).inDays > 1) {
        // Réinitialiser le compteur si plus d'un jour est passé
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'streakCount': 1,
          'lastStreakDate': Timestamp.now(),
        });
      }
    }
  }

  void _showCongratulationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Séance terminée, félicitations!'),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  void _showRestTimePopup() {
    showDialog(
      context: context,
      builder: (context) {
        int restTime = _restTimeBetweenSets;
        return AlertDialog(
          title: const Text('Temps de repos entre séries'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restTime > 10) {
                        setState(() {
                          restTime -= 10;
                        });
                      }
                    },
                  ),
                  Text('$restTime s'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        restTime += 10;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                setState(() {
                  _restTimeBetweenSets = restTime;
                  _currentExercise['restTime'] = restTime;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  Widget _buildExerciseView() {
    return GestureDetector(
      onTap: () {
        _showRestTimePopup();
      },
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _currentExercise['image'] != null &&
                      _currentExercise['image'].isNotEmpty
                  ? Image.asset(
                      _currentExercise['image'],
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, size: 200);
                      },
                    )
                  : const Icon(Icons.image_not_supported, size: 200),
              const SizedBox(height: 16),
              Text(
                _currentExercise['name'] ?? '',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _currentExercise['description'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                'Objectifs:\n${_currentExercise['goals'] ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // On ne permet plus de changer le temps de repos entre exercices ici
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _completeSet,
                child: Text('Terminer la série ${_currentSet + 1}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isBetweenExercises ? 'Repos entre exercices' : 'Repos entre séries',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 36),
        ),
        const SizedBox(height: 8),
        IconButton(
          icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
          iconSize: 48,
          onPressed: _toggleTimer,
        ),
        const SizedBox(height: 16),
        if (!_isBetweenExercises)
          Column(
            children: [
              Text(
                'Séries complétées: $_currentSet / ${_currentExercise['sets']}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Répétitions: ${_currentExercise['reps']}  Poids: ${_currentExercise['weight']} kg',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentExercise['name'] ?? ''),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade200, Colors.yellow.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isResting ? _buildRestView() : _buildExerciseView(),
        ),
      ),
    );
  }
}
