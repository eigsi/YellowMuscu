// exercise_session_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Assurez-vous que ce fichier contient 'themeModeProvider' et 'displayProvider'

class ExerciseSessionPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> program;
  final String userId;
  final VoidCallback onSessionComplete;

  const ExerciseSessionPage({
    Key? key,
    required this.program,
    required this.userId,
    required this.onSessionComplete,
  }) : super(key: key);

  @override
  ExerciseSessionPageState createState() => ExerciseSessionPageState();
}

class ExerciseSessionPageState extends ConsumerState<ExerciseSessionPage> {
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
    // Démarrer le minuteur si nécessaire
    if (_isResting) {
      _startTimer();
    }
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
        _currentSet++; // Incrémenter _currentSet ici
      });
    }
  }

  void _completeSet() {
    if (_currentSet < (_currentExercise['sets']?.toInt() ?? 3) - 1) {
      setState(() {
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
          _isResting = true;
          _isBetweenExercises = true;
          _isTimerRunning = true;
          _timerSeconds = _restTimeBetweenExercises;
          _bonusTime = 0; // Réinitialise le temps bonus
          _currentSet =
              0; // Réinitialiser _currentSet pour le prochain exercice
        });
        _startTimer();
      } else {
        // Dernier exercice terminé, afficher l'écran "Stronger?"
        _showProgressScreen();
      }
    }
  }

  void _moveToNextExercise() {
    setState(() {
      _currentExerciseIndex++;
      if (_currentExerciseIndex < widget.program['exercises'].length) {
        _currentExercise = widget.program['exercises'][_currentExerciseIndex];
        _restTimeBetweenExercises =
            (_currentExercise['restBetweenExercises'] as int?) ?? 60;
        _restTimeBetweenSets = (_currentExercise['restTime'] as int?) ?? 60;
        _currentSet = 0;
        _isResting = false;
        _isBetweenExercises = false;
        _timerSeconds = _restTimeBetweenSets;
        _bonusTime = 0; // Réinitialise le temps bonus
      }
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
          false, // L'utilisateur doit appuyer sur "Save" pour fermer
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateLocal) {
            final isDarkMode = ref.watch(themeModeProvider);
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16.0), // Ajout du border radius
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [darkTop, darkBottom]
                        : [lightTop, lightBottom],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(
                      16.0), // Assurez-vous que le border radius est appliqué
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Stronger?',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black),
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
                                color: isDarkMode ? darkBottom : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12), // Coins arrondis
                              ),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 0),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise['name'] ?? '',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                      ),
                                      if (exercise['multipleWeights'] == true &&
                                          exercise['weightsPerSet'] != null)
                                        SizedBox.shrink() // Pas d'icône
                                      else
                                        GestureDetector(
                                          onTap: () {
                                            _showDecimalInputPicker(
                                              context,
                                              'Weight (kg)',
                                              exercise['weight'].toDouble(),
                                              0.0,
                                              500.0,
                                              0.5,
                                              (newWeight) {
                                                setStateLocal(() {
                                                  exercise['weight'] =
                                                      newWeight;
                                                });
                                              },
                                            );
                                          },
                                          child: Text(
                                            '${exercise['weight'].toStringAsFixed(1)} kg',
                                            style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (exercise['multipleWeights'] == true &&
                                      exercise['weightsPerSet'] != null)
                                    Column(
                                      children: List<Widget>.generate(
                                          exercise['weightsPerSet'].length,
                                          (setIndex) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Set ${setIndex + 1}',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _showDecimalInputPicker(
                                                  context,
                                                  'Weight (kg)',
                                                  exercise['weightsPerSet']
                                                          [setIndex]
                                                      .toDouble(),
                                                  0.0,
                                                  500.0,
                                                  0.5,
                                                  (newWeight) {
                                                    setStateLocal(() {
                                                      exercise['weightsPerSet']
                                                              [setIndex] =
                                                          newWeight;
                                                    });
                                                  },
                                                );
                                              },
                                              child: Text(
                                                '${exercise['weightsPerSet'][setIndex].toStringAsFixed(1)} kg',
                                                style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    decoration: TextDecoration
                                                        .underline),
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
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
                                const Size(100, 50), // Hauteur du bouton
                            backgroundColor:
                                isDarkMode ? darkWidget : lightWidget,
                            foregroundColor: Colors.black, // Texte en noir
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black), // Texte en noir
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
          content: Text('Session done, good job!'),
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
      widget.program['exercises'][i]['weightsPerSet'] =
          localExercises[i]['weightsPerSet'];
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
            content: Text('Error: $e'),
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
      // Fermer le popup "Stronger?"
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
      debugPrint('Error in _checkAndUpdateStreak: $e');
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
    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: isDarkMode ? darkBottom : Colors.white, // Couleur de fond
          child: Column(
            children: [
              // Titre du picker
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(title,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black)),
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? darkBottom : Colors.white,
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
                        '${value.toStringAsFixed(1)} kg',
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ); // Affiche chaque valeur
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

  // Méthode pour éditer les poids par set
  void _showWeightsPerSetEditor(BuildContext context,
      Map<String, dynamic> exercise, Function setStateLocal) {
    final isDarkMode = ref.watch(themeModeProvider);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [darkTop, darkBottom]
                      : [lightTop, lightBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit weights per set',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: exercise['weightsPerSet'].length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Set ${index + 1}',
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: isDarkMode ? Colors.white : Colors.black,
                                onPressed: () {
                                  _showDecimalInputPicker(
                                    context,
                                    'Weight (kg)',
                                    exercise['weightsPerSet'][index].toDouble(),
                                    0.0,
                                    500.0,
                                    0.5,
                                    (newWeight) {
                                      setStateDialog(() {
                                        exercise['weightsPerSet'][index] =
                                            newWeight;
                                      });
                                      setStateLocal(() {
                                        exercise['weightsPerSet'][index] =
                                            newWeight;
                                      });
                                    },
                                  );
                                },
                              ),
                              Text(
                                '${exercise['weightsPerSet'][index].toStringAsFixed(1)} kg',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(50), // Hauteur du bouton
                      backgroundColor: isDarkMode ? darkWidget : lightWidget,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.black : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Méthode pour obtenir le poids pour le set actuel
  double _getWeightForSet(Map<String, dynamic> exercise, int setIndex) {
    if (exercise['multipleWeights'] == true &&
        exercise['weightsPerSet'] != null &&
        exercise['weightsPerSet'].length > setIndex) {
      return exercise['weightsPerSet'][setIndex] ?? 0.0;
    } else {
      return exercise['weight'] ?? 0.0;
    }
  }

  Widget _buildExerciseView() {
    final isDarkMode = ref.watch(themeModeProvider);
    final isDisplay = ref.watch(displayProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Première case blanche avec les informations principales
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : lightWidget, // Couleur de fond
              borderRadius: BorderRadius.circular(16.0), // Coins arrondis
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alignement à gauche
              children: [
                // Titre "Set x/y" en haut de la case blanche
                Text(
                  'Set ${_currentSet + 1} / ${_currentExercise['sets']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Toujours afficher le titre de l'exercice
                Text(
                  _currentExercise['name'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                if (isDisplay) ...[
                  // Centrer l'image
                  Center(
                    child: _currentExercise['image'] != null &&
                            (_currentExercise['image'] is String) &&
                            (_currentExercise['image'] as String).isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16.0), // Coins arrondis
                            child: Image.asset(
                              _currentExercise['image'],
                              height: 200,
                              fit: BoxFit
                                  .cover, // Ajuste l'image à l'espace disponible
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported,
                                    size: 200);
                              },
                            ),
                          )
                        : const Icon(Icons.image_not_supported, size: 200),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentExercise['description'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Goals:\n${_currentExercise['goals'] ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Checkbox pour cacher/afficher les informations de l'exercice
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: !isDisplay,
                      onChanged: (bool? value) {
                        ref
                            .read(displayProvider.notifier)
                            .toggleDisplay(!value!);
                      },
                      activeColor: isDarkMode ? darkWidget : Colors.black,
                    ),
                    Text(
                      'Hide exercise information',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                // Centrer le bouton
                Center(
                  child: ElevatedButton(
                    onPressed: _completeSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkWidget,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Finish series ${_currentSet + 1}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nouvelle case blanche en dessous avec les informations de l'exercice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : lightWidget, // Couleur de fond
              borderRadius: BorderRadius.circular(16.0), // Coins arrondis
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alignement à gauche
              children: [
                Text(
                  'Current set',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight used: ${_getWeightForSet(_currentExercise, _currentSet).toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sets: ${_currentSet + 1} / ${_currentExercise['sets']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Repetitions: ${_currentExercise['reps']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestView() {
    final isDarkMode = ref.watch(themeModeProvider);
    return SingleChildScrollView(
      child: Column(
        children: [
          // Boîte blanche pour le minuteur et les contrôles
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : lightWidget, // Couleur de fond
              borderRadius: BorderRadius.circular(16.0), // Coins arrondis
            ),
            child: Column(
              children: [
                Text(
                  _isBetweenExercises
                      ? 'Rest between exercises'
                      : 'Rest between sets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 36,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  color: isDarkMode ? Colors.white : Colors.black,
                  onPressed: _toggleTimer,
                ),
                const SizedBox(height: 16),
                if (_bonusTime > 0)
                  Text(
                    'Bonus time added: ${_bonusTime}s',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: darkWidget,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          '+10s',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.black : Colors.black,
                          ),
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
                        color: darkWidget,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text(
                          '+30s',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.black : Colors.black,
                          ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkWidget,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: const Text(
                    'Skip rest',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Boîte blanche pour les informations de la prochaine série ou exercice
          if (_isBetweenExercises)
            // Repos entre exercices
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : lightWidget,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentExerciseIndex + 1 <
                      widget.program['exercises'].length)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next exercise',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Utiliser une variable locale pour le prochain exercice
                        Builder(
                          builder: (context) {
                            final nextExercise = widget.program['exercises']
                                [_currentExerciseIndex + 1];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        nextExercise['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sets: ${nextExercise['sets']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fiber_manual_record,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Repetitions: ${nextExercise['reps']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Weight: ${_getWeightForSet(nextExercise, 0).toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Center(
                      child: Text(
                        'This was the last exercise',
                        style: TextStyle(
                          fontSize: 20,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            // Repos entre séries
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : lightWidget,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming set',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Weight: ${_getWeightForSet(_currentExercise, _currentSet + 1).toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Set: ${_currentSet + 2} / ${_currentExercise['sets']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Repetitions: ${_currentExercise['reps']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentExercise['name'] ?? ''),
        backgroundColor: isDarkMode ? darkNavBar : lightTop,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode ? [darkTop, darkBottom] : [lightTop, lightBottom],
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
