// exercise_session_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

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
  ExerciseSessionPageState createState() => ExerciseSessionPageState();
}

class ExerciseSessionPageState extends State<ExerciseSessionPage> {
  int _currentExerciseIndex = 0;
  int _currentSet = 0;
  bool _isResting = false;
  bool _isTimerRunning = true;
  late int _restTimeBetweenSets;
  late int _restTimeBetweenExercises;
  late int _timerSeconds;
  late Map<String, dynamic> _currentExercise;
  bool _isBetweenExercises = false;
  int _bonusTime = 0; // Variable pour le temps bonus ajouté

  // Déclarer _isSaving dans la classe State
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentExercise = widget.program['exercises'][_currentExerciseIndex];
    _restTimeBetweenExercises =
        (_currentExercise['restBetweenExercises'] as int?) ?? 60;
    _restTimeBetweenSets = (_currentExercise['restTime'] as int?) ?? 60;
    _timerSeconds = _restTimeBetweenSets;
    _startTimer();
  }

  void _startTimer() {
    if (_isResting && _isTimerRunning) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return; // Vérifie si le widget est toujours monté
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
        _bonusTime = 0; // Réinitialise le temps bonus
      });
    }
  }

  void _completeSet() {
    if (_currentSet < (_currentExercise['sets']?.toInt() ?? 3) - 1) {
      setState(() {
        _currentSet++;
        _isResting = true;
        _isTimerRunning = true;
        _timerSeconds = _restTimeBetweenSets;
        _bonusTime = 0; // Réinitialise le temps bonus
      });
      _startTimer();
    } else {
      if (_currentExerciseIndex <
          (widget.program['exercises']?.length ?? 0) - 1) {
        setState(() {
          _currentSet = 0;
          _isResting = true;
          _isBetweenExercises = true;
          _isTimerRunning = true;
          _timerSeconds = _restTimeBetweenExercises;
          _bonusTime = 0; // Réinitialise le temps bonus
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
          (_currentExercise['restBetweenExercises'] as int?) ?? 60;
      _restTimeBetweenSets = (_currentExercise['restTime'] as int?) ?? 60;
      _currentSet = 0;
      _isResting = false;
      _isBetweenExercises = false;
      _timerSeconds = _restTimeBetweenSets;
      _bonusTime = 0; // Réinitialise le temps bonus
    });
  }

  Future<void> _showProgressScreen() async {
    // Créer une copie locale des exercices pour gérer les poids dans le popup
    List<Map<String, dynamic>> localExercises = widget.program['exercises']
        .map<Map<String, dynamic>>(
            (exercise) => Map<String, dynamic>.from(exercise))
        .toList();

    if (!mounted) return;

    bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible:
          false, // L'utilisateur doit appuyer sur "Enregistrer" pour fermer
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
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
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: localExercises.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> exercise =
                                localExercises[index];
                            if (exercise['weight'] == null) {
                              exercise['weight'] = 0.0;
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
                                    child: Text(
                                      exercise['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _showDecimalInputPicker(
                                            context,
                                            'Poids (kg)',
                                            exercise['weight'].toDouble(),
                                            0.0,
                                            500.0,
                                            0.5,
                                            (newWeight) {
                                              setStateLocal(() {
                                                localExercises[index]
                                                    ['weight'] = newWeight;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      Text(
                                          '${exercise['weight'].toStringAsFixed(1)} kg'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _handleSaveButtonPressed(
                                  setStateLocal, dialogContext, localExercises),
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                                const Size.fromHeight(50), // Hauteur du bouton
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(fontSize: 18),
                                ),
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
      },
    );

    // Après l'attente du showDialog, vérifier le résultat
    if (success == true && mounted) {
      // Naviguer vers l'écran précédent
      Navigator.of(context).pop(); // Fermer ExerciseSessionPage

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Séance terminée, félicitations!'),
        ),
      );

      // Appeler la fonction de rappel pour notifier que la session est complétée
      widget.onSessionComplete();
    }
  }

  Future<void> _handleSaveButtonPressed(
      Function setStateLocal,
      BuildContext dialogContext,
      List<Map<String, dynamic>> localExercises) async {
    setStateLocal(() {
      _isSaving = true; // Indicateur pour empêcher les clics multiples
    });

    // Mettre à jour les poids dans le programme
    for (int i = 0; i < localExercises.length; i++) {
      widget.program['exercises'][i]['weight'] = localExercises[i]['weight'];
    }

    bool success = false; // Indicateur de succès

    try {
      // Mettre à jour la base de données avec les nouveaux poids
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('programs')
          .doc(widget.program['id'])
          .update({
        'exercises': widget.program['exercises'],
        'isDone': true,
      });

      // Appeler la méthode pour mettre à jour le streak
      await _checkAndUpdateStreak();

      // Indiquer que l'opération a réussi
      success = true;
    } catch (e) {
      // Gérer les erreurs de mise à jour
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setStateLocal(() {
          _isSaving = false; // Réinitialise l'indicateur
        });
      }
    }

    if (success && mounted) {
      // Fermer le popup "Des progrès ?"
      // ignore: use_build_context_synchronously
      Navigator.of(dialogContext)
          .pop(true); // Fermer le popup et retourner 'true'
    }
  }

  Future<void> _checkAndUpdateStreak() async {
    try {
      // Vérifier si toutes les séances de la semaine sont terminées
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('programs')
          .get();

      bool allProgramsDone =
          snapshot.docs.every((doc) => doc['isDone'] == true);

      if (allProgramsDone) {
        // Récupérer la dernière date de streak
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

        DateTime lastStreakDate;
        if (userDoc.exists &&
            userDoc.data() != null &&
            (userDoc.data() as Map<String, dynamic>)
                .containsKey('lastStreakDate') &&
            (userDoc.data() as Map<String, dynamic>)['lastStreakDate'] !=
                null) {
          Timestamp lastStreakTimestamp =
              (userDoc.data() as Map<String, dynamic>)['lastStreakDate'];
          lastStreakDate = lastStreakTimestamp.toDate();
        } else {
          // Si 'lastStreakDate' n'existe pas, initialiser
          lastStreakDate = DateTime.now();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'streakCount': 1,
            'lastStreakDate': Timestamp.now(),
          });
          return; // Sortir tôt car streak est initialisé
        }

        // Obtenir la date actuelle sans l'heure
        DateTime today = DateTime.now();
        DateTime todayDate = DateTime(today.year, today.month, today.day);

        // Obtenir la date de la dernière streak sans l'heure
        DateTime lastStreakDateOnly = DateTime(
            lastStreakDate.year, lastStreakDate.month, lastStreakDate.day);

        // Calculer la différence en jours
        int difference = todayDate.difference(lastStreakDateOnly).inDays;

        if (difference == 1) {
          // Si le dernier streak date d'hier, incrémenter le compteur
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'streakCount': FieldValue.increment(1),
            'lastStreakDate': Timestamp.now(),
          });
        } else if (difference > 1) {
          // Réinitialiser le compteur si plus d'un jour est passé
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({
            'streakCount': 1,
            'lastStreakDate': Timestamp.now(),
          });
        }
        // Si difference == 0, ne rien faire
      }
    } catch (e) {
      // Gérer les exceptions et les loguer si nécessaire
      debugPrint('Erreur dans _checkAndUpdateStreak: $e');
    }
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _pauseTimer();
    } else {
      _resumeTimer();
    }
  }

  // Méthode pour afficher le DecimalInputPicker
  void _showDecimalInputPicker(
      BuildContext context,
      String title,
      double initialValue,
      double minValue,
      double maxValue,
      double step,
      ValueChanged<double> onValueChanged) {
    double currentValue = initialValue; // Valeur courante initialisée

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: Colors.white, // Couleur de fond
          child: Column(
            children: [
              // Titre du picker
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: ((currentValue - minValue) / step)
                        .round()
                        .clamp(0, ((maxValue - minValue) / step).round()),
                  ),
                  onSelectedItemChanged: (int value) {
                    currentValue = minValue +
                        value * step; // Met à jour la valeur sélectionnée
                  },
                  children: List<Widget>.generate(
                    ((maxValue - minValue) / step).round() +
                        1, // Nombre d'éléments à générer
                    (int index) {
                      double value = minValue + index * step;
                      return Text(
                          '${value.toStringAsFixed(1)} kg'); // Affiche chaque valeur
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Lorsque le picker est fermé, appelle la fonction de rappel avec la nouvelle valeur
      onValueChanged(currentValue);
    });
  }

  Widget _buildExerciseView() {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _currentExercise['image'] != null &&
                    (_currentExercise['image'] is String) &&
                    (_currentExercise['image'] as String).isNotEmpty
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _completeSet,
              child: Text('Terminer la série ${_currentSet + 1}'),
            ),
          ],
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
        if (_bonusTime > 0)
          Text(
            'Bonus temps ajouté: ${_bonusTime}s',
            style: const TextStyle(fontSize: 16),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Couleur de fond
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Text(
                  '+10s',
                  style: TextStyle(
                      fontSize: 16, color: Colors.black), // Texte noir
                ),
                onPressed: () {
                  setState(() {
                    _timerSeconds += 10;
                    _bonusTime += 10;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Couleur de fond
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Text(
                  '+30s',
                  style: TextStyle(
                      fontSize: 16, color: Colors.black), // Texte noir
                ),
                onPressed: () {
                  setState(() {
                    _timerSeconds += 30;
                    _bonusTime += 30;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _endRest,
          child: const Text('Passer le repos'),
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
                'Répétitions: ${_currentExercise['reps']}  Poids: ${_currentExercise['weight'].toStringAsFixed(1)} kg',
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
