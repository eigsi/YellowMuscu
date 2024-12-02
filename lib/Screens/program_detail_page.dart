// Importation des packages nécessaires
import 'package:flutter/material.dart'; // Bibliothèque de widgets matériels de Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore de Firebase
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Pour la gestion de l'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour gérer le thème (clair/sombre)
import 'package:flutter/cupertino.dart'; // Widgets Cupertino pour le style iOS
import 'package:yellowmuscu/Exercise/exercise_category_list.dart'; // Widget pour la liste des catégories
import 'package:yellowmuscu/data/exercises_data.dart'; // Données des exercices

// Définition de la classe ProgramDetailPage, un ConsumerStatefulWidget pour intégrer Riverpod
class ProgramDetailPage extends ConsumerStatefulWidget {
  // Variables finales pour stocker le programme, l'ID utilisateur et une fonction de mise à jour
  final Map<String, dynamic> program; // Le programme d'exercices
  final String userId; // L'identifiant de l'utilisateur actuel
  final VoidCallback
      onUpdate; // Fonction de rappel pour notifier les mises à jour

  // Constructeur de la classe avec paramètres requis
  const ProgramDetailPage({
    super.key,
    required this.program,
    required this.userId,
    required this.onUpdate,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

// État associé à la classe ProgramDetailPage
class _ProgramDetailPageState extends ConsumerState<ProgramDetailPage> {
  late List<Map<String, dynamic>> exercises; // Liste des exercices du programme
  bool _isEditingOrder =
      false; // Indique si l'utilisateur est en mode d'édition de l'ordre des exercices
  bool _hasChanges = false; // Indique si des modifications ont été apportées

  @override
  void initState() {
    super.initState();
    // Initialise la liste des exercices en copiant depuis le programme fourni
    // Si 'exercises' est absent ou null, initialise à une liste vide
    exercises = widget.program['exercises'] != null
        ? List<Map<String, dynamic>>.from(widget.program['exercises'])
        : [];

    // Parcourt chaque exercice pour s'assurer que certaines clés existent
    for (var exercise in exercises) {
      exercise['restBetweenExercises'] = exercise['restBetweenExercises'] ??
          60; // Définit une valeur par défaut de 60 secondes
      exercise['restTime'] = exercise['restTime'] ??
          60; // Définit une valeur par défaut de 60 secondes
      exercise['sets'] =
          exercise['sets'] ?? 3; // Définit une valeur par défaut de 3 séries
      exercise['reps'] = exercise['reps'] ??
          10; // Définit une valeur par défaut de 10 répétitions
      exercise['weight'] = exercise['weight']?.toDouble() ??
          0.0; // Définit une valeur par défaut de 0.0 kg
      exercise['image'] = exercise['image'] ??
          'assets/images/default_exercise.png'; // Définit une image par défaut
      exercise['name'] =
          exercise['name'] ?? 'Exercice'; // Définit un nom par défaut
      exercise['id'] = exercise['id'] ??
          UniqueKey().toString(); // Génère un identifiant unique si absent
      exercise['multipleWeights'] =
          exercise['multipleWeights'] ?? false; // Définit par défaut à false
      if (exercise['multipleWeights']) {
        // Si multipleWeights est activé, initialise weightsPerSet
        exercise['weightsPerSet'] = exercise['weightsPerSet'] != null
            ? List<double>.from(
                exercise['weightsPerSet'].map((w) => w.toDouble()))
            : List<double>.filled(
                exercise['sets'], exercise['weight'].toDouble());
      }
    }
  }

  // Méthode asynchrone pour sauvegarder les exercices modifiés dans Firestore
  Future<void> _saveExercises() async {
    try {
      // Vérifie si le programme a un identifiant unique
      String programId = widget.program['id'];
      if (programId.isEmpty) {
        // Si 'id' est absent, génère un nouvel identifiant et crée le document
        DocumentReference newProgramRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('programs')
            .doc(); // Génère un nouvel identifiant
        programId = newProgramRef.id;
        await newProgramRef.set({
          'id': programId,
          'name': widget.program['name'] ?? 'New Program',
          'exercises': exercises,
        });
      } else {
        // Si 'id' existe, met à jour le document existant avec 'set' et 'merge: true'
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('programs')
            .doc(programId)
            .set({'exercises': exercises}, SetOptions(merge: true));
      }

      widget
          .onUpdate(); // Appelle la fonction de mise à jour pour notifier les changements

      // Affiche une confirmation visuelle que les exercices ont été sauvegardés
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercices saved'),
        ),
      );
    } catch (e) {
      // Gère les erreurs de Firestore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour afficher un sélecteur de temps de repos (style iOS)
  void _showRestTimePicker(BuildContext context, int currentRestTime,
      ValueChanged<int> onRestTimeChanged) {
    int currentMinutes = currentRestTime ~/ 60; // Calcule les minutes initiales
    int currentSeconds = currentRestTime % 60; // Calcule les secondes initiales

    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: isDarkMode ? Colors.black : Colors.white, // Couleur de fond
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Picker pour les minutes
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: currentMinutes, // Valeur initiale en minutes
                  ),
                  onSelectedItemChanged: (int value) {
                    currentMinutes =
                        value; // Met à jour les minutes sélectionnées
                  },
                  children: List<Widget>.generate(
                    61, // Génère des minutes de 0 à 60
                    (int index) {
                      return Text('$index min'); // Affiche le texte des minutes
                    },
                  ),
                ),
              ),
              // Picker pour les secondes
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: (currentSeconds / 10)
                        .floor(), // Valeur initiale en secondes (par tranche de 10)
                  ),
                  onSelectedItemChanged: (int value) {
                    currentSeconds =
                        value * 10; // Met à jour les secondes sélectionnées
                  },
                  children: List<Widget>.generate(
                    6, // Génère des secondes de 0 à 50 (par tranches de 10)
                    (int index) {
                      return Text(
                          '${index * 10} sec'); // Affiche le texte des secondes
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Lorsque le picker est fermé, calcule le temps total en secondes
      int totalTimeInSeconds = (currentMinutes * 60) + currentSeconds;
      onRestTimeChanged(
          totalTimeInSeconds); // Appelle la fonction de rappel avec la nouvelle valeur
    });
  }

  // Méthode pour afficher un sélecteur numérique générique
  void _showInputPicker(BuildContext context, String title, int initialValue,
      int minValue, int maxValue, int step, ValueChanged<int> onValueChanged) {
    int currentValue = initialValue; // Valeur courante initialisée

    final isDarkMode = ref.watch(themeModeProvider);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: isDarkMode ? Colors.black : Colors.white, // Couleur de fond
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
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: ((currentValue - minValue) ~/ step)
                        .clamp(0, ((maxValue - minValue) ~/ step)),
                  ),
                  onSelectedItemChanged: (int value) {
                    currentValue = minValue +
                        value * step; // Met à jour la valeur sélectionnée
                  },
                  children: List<Widget>.generate(
                    ((maxValue - minValue) ~/ step) +
                        1, // Nombre d'éléments à générer
                    (int index) {
                      return Text(
                          '${minValue + index * step}'); // Affiche chaque valeur
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

  // Méthode pour afficher un sélecteur numérique avec des demi-unités (par exemple, 0.5 kg)
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
          color: isDarkMode ? Colors.black : Colors.white,
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
                  backgroundColor: isDarkMode ? Colors.black : Colors.white,
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

  // Méthode pour éditer un exercice spécifique
  void _editExercise(int index) {
    final exercise = exercises[index]; // Récupère l'exercice à l'index donné
    int sets = exercise['sets']; // Nombre de séries
    int reps = exercise['reps']; // Nombre de répétitions
    double weight =
        exercise['weight']?.toDouble() ?? 0.0; // Poids, par défaut 0.0
    int restTime = exercise['restTime']?.toInt() ??
        60; // Temps de repos entre séries, par défaut 60 secondes
    bool multipleWeights =
        exercise['multipleWeights'] ?? false; // Poids multiples
    List<double> weightsPerSet = multipleWeights
        ? List<double>.from(
            exercise['weightsPerSet']?.map((w) => w.toDouble()) ??
                List<double>.filled(sets, weight))
        : [weight.toDouble()]; // Poids par série

    final isDarkMode =
        ref.watch(themeModeProvider); // Vérifie si le thème sombre est activé

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          // Utilise un StatefulBuilder pour gérer l'état local dans le dialogue
          return AlertDialog(
            backgroundColor: isDarkMode
                ? Colors.black
                : Colors.white, // Couleur de fond selon le thème
            title: Text(
              'Modifier ${exercise['name']}', // Titre du dialogue
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modification du nombre de séries
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Séries:'), // Libellé
                      GestureDetector(
                        onTap: () {
                          _showInputPicker(
                            context,
                            'Séries', // Titre du picker
                            sets, // Valeur initiale
                            1, // Valeur minimale
                            99, // Valeur maximale
                            1, // Pas
                            (newSets) {
                              setStateDialog(() {
                                sets =
                                    newSets; // Met à jour le nombre de séries
                                if (multipleWeights) {
                                  // Ajuste la liste des poids par série
                                  if (newSets > weightsPerSet.length) {
                                    weightsPerSet.addAll(List<double>.filled(
                                        newSets - weightsPerSet.length,
                                        weight));
                                  } else if (newSets < weightsPerSet.length) {
                                    weightsPerSet =
                                        weightsPerSet.sublist(0, newSets);
                                  }
                                }
                              });
                            },
                          );
                        },
                        child:
                            Text('$sets séries'), // Affiche la valeur actuelle
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Espace entre les champs
                  // Modification du nombre de répétitions
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
                              setStateDialog(() {
                                reps =
                                    newReps; // Met à jour le nombre de répétitions
                              });
                            },
                          );
                        },
                        child: Text('$reps répétitions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Modification du poids
                  if (!multipleWeights)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Poids (kg):'),
                        GestureDetector(
                          onTap: () {
                            _showDecimalInputPicker(
                              context,
                              'Poids (kg)',
                              weight,
                              0.0,
                              500.0,
                              0.5,
                              (newWeight) {
                                setStateDialog(() {
                                  weight = newWeight; // Met à jour le poids
                                });
                              },
                            );
                          },
                          child: Text(
                              '${weight.toStringAsFixed(1)} kg'), // Affiche la valeur actuelle avec une décimale
                        ),
                      ],
                    ),
                  if (multipleWeights)
                    Column(
                      children: List.generate(sets, (s) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Poids série ${s + 1}:'),
                            GestureDetector(
                              onTap: () {
                                _showDecimalInputPicker(
                                  context,
                                  'Poids série ${s + 1}',
                                  weightsPerSet[s],
                                  0.0,
                                  500.0,
                                  0.5,
                                  (newWeight) {
                                    setStateDialog(() {
                                      weightsPerSet[s] =
                                          newWeight; // Met à jour le poids de la série
                                    });
                                  },
                                );
                              },
                              child: Text(
                                  '${weightsPerSet[s].toStringAsFixed(1)} kg'), // Affiche le poids de la série
                            ),
                          ],
                        );
                      }),
                    ),
                  const SizedBox(height: 16),
                  // Modification du temps de repos entre séries
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repos entre séries:'),
                      GestureDetector(
                        onTap: () {
                          _showRestTimePicker(context, restTime, (newRestTime) {
                            setStateDialog(() {
                              restTime =
                                  newRestTime; // Met à jour le temps de repos
                            });
                          });
                        },
                        child: Text(_formatDuration(
                            restTime)), // Affiche le temps de repos formaté
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bouton pour activer/désactiver les poids multiples
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Poids multiples:'),
                      CupertinoSwitch(
                        value: multipleWeights,
                        onChanged: (bool value) {
                          setStateDialog(() {
                            multipleWeights = value;
                            if (value) {
                              // Initialiser weightsPerSet si activé
                              weightsPerSet = List<double>.filled(sets, weight);
                            } else {
                              // Réinitialiser weight si désactivé
                              weight = weightsPerSet.isNotEmpty
                                  ? weightsPerSet[0]
                                  : 0.0;
                              weightsPerSet = [];
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              // Bouton pour annuler les modifications
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                ),
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              // Bouton pour enregistrer les modifications
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                ),
                child: const Text('Save'),
                onPressed: () async {
                  setState(() {
                    // Met à jour les valeurs de l'exercice dans la liste
                    exercises[index]['sets'] = sets;
                    exercises[index]['reps'] = reps;
                    exercises[index]['restTime'] = restTime;
                    exercises[index]['multipleWeights'] = multipleWeights;
                    if (multipleWeights) {
                      exercises[index]['weightsPerSet'] = weightsPerSet;
                      exercises[index]['weight'] =
                          weightsPerSet.isNotEmpty ? weightsPerSet[0] : 0.0;
                    } else {
                      exercises[index]['weight'] = weight;
                      exercises[index].remove('weightsPerSet');
                    }
                  });

                  // Sauvegarde les modifications dans Firestore
                  await _saveExercises();

                  setState(() {
                    _hasChanges =
                        true; // Indique que des modifications ont été effectuées
                  });

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Méthode pour modifier le temps de repos entre les exercices
  void _changeRestBetweenExercises(int index, int change) {
    setState(() {
      int newRest = (exercises[index]['restBetweenExercises'] + change)
          .clamp(0, 3600); // Limite entre 0 et 3600 secondes
      exercises[index]['restBetweenExercises'] =
          newRest; // Met à jour le temps de repos
      _hasChanges = true; // Indique que des modifications ont été effectuées
    });
    _saveExercises(); // Sauvegarde les modifications
  }

  // Méthode pour réordonner les exercices dans la liste
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1; // Ajuste l'index si nécessaire
      final item = exercises
          .removeAt(oldIndex); // Supprime l'exercice de sa position actuelle
      exercises.insert(
          newIndex, item); // Insère l'exercice à la nouvelle position
      _hasChanges = true; // Indique que des modifications ont été effectuées
    });
    _saveExercises(); // Sauvegarde les modifications
  }

  // Méthode pour basculer le mode d'édition de l'ordre des exercices
  void _toggleEditingOrder() {
    setState(() {
      _isEditingOrder = !_isEditingOrder; // Inverse la valeur booléenne
      if (!_isEditingOrder) {
        _saveExercises(); // Sauvegarde les modifications si on quitte le mode édition
      }
    });
  }

  // Méthode pour formater la durée en minutes et secondes
  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '$totalSeconds sec'; // Si moins d'une minute, affiche les secondes
    } else {
      int minutes = totalSeconds ~/ 60; // Calcule les minutes
      int seconds = totalSeconds % 60; // Calcule les secondes restantes
      String minutesPart =
          '$minutes min${minutes > 1 ? 's' : ''}'; // Gère le pluriel
      String secondsPart =
          seconds > 0 ? ' $seconds sec' : ''; // Affiche les secondes si > 0
      return secondsPart.isNotEmpty
          ? '$minutesPart $secondsPart'
          : minutesPart; // Combine les deux
    }
  }

  // Méthode pour afficher le menu des catégories d'exercices
  void _addNewExercises() {
    final isDarkMode = ref.watch(themeModeProvider);
    final List<Map<String, dynamic>> categories = [
      {'name': 'Chest', 'icon': Icons.fitness_center},
      {'name': 'Back', 'icon': Icons.fitness_center},
      {'name': 'Shoulders', 'icon': Icons.fitness_center},
      {'name': 'Biceps', 'icon': Icons.fitness_center},
      {'name': 'Triceps', 'icon': Icons.fitness_center},
      {'name': 'Legs & Glutes', 'icon': Icons.fitness_center},
      {'name': 'Calves', 'icon': Icons.fitness_center},
      {'name': 'Abs', 'icon': Icons.fitness_center},
      {'name': 'Stretching', 'icon': Icons.fitness_center},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled:
          true, // Les modales prennent toute la hauteur de la page
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            children: [
              // Petite croix en haut à gauche
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme le modal
                  },
                ),
              ),
              Expanded(
                child: ExerciseCategoryList(
                  categories: categories,
                  onCategoryTap: (category) {
                    Navigator.of(context)
                        .pop(); // Ferme le modal des catégories
                    _showExercises(category);
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour afficher la liste des exercices d'une catégorie
  void _showExercises(String category) {
    List<Map<String, String>> exercisesList;

    // Sélection des exercices en fonction de la catégorie
    if (category == 'Biceps') {
      exercisesList = ExercisesData.bicepsExercises;
    } else if (category == 'Abs') {
      exercisesList = ExercisesData.abExercises;
    } else if (category == 'Triceps') {
      exercisesList = ExercisesData.tricepsExercises;
    } else if (category == 'Legs & Glutes') {
      exercisesList = ExercisesData.legExercises;
    } else if (category == 'Chest') {
      exercisesList = ExercisesData.chestExercises;
    } else if (category == 'Back') {
      exercisesList = ExercisesData.backExercises;
    } else if (category == 'Shoulders') {
      exercisesList = ExercisesData.shoulderExercises;
    } else if (category == 'Calves') {
      exercisesList = ExercisesData.calfExercises;
    } else if (category == 'Stretching') {
      exercisesList = ExercisesData.stretchingExercises;
    } else {
      exercisesList = [];
    }

    final isDarkMode = ref.watch(themeModeProvider);

    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredExercises = List.from(exercisesList);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled:
          true, // Les modales prennent toute la hauteur de la page
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  // Petite croix en haut à gauche
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(); // Ferme le modal
                      },
                    ),
                  ),
                  // Titre de la catégorie
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un exercice',
                        hintStyle: TextStyle(
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.white : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white70 : Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isDarkMode ? Colors.white : Colors.blue),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black),
                      onChanged: (value) {
                        setStateModal(() {
                          filteredExercises = exercisesList
                              .where((exercise) => exercise['name']!
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredExercises.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun exercice trouvé.',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];
                              return ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Image.asset(
                                        exercise['image']!,
                                        width: 40,
                                        height: 40,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                              Icons.image_not_supported);
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  exercise['name']!,
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showExerciseInfo(exercise);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Ferme le modal des exercices
                                        _showRestTimePopup(exercise);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Méthode pour afficher les détails d'un exercice
  void _showExerciseInfo(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeModeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          contentPadding: const EdgeInsets.all(16.0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Image.asset(
                    exercise['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 100);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise['description'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Objectifs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise['goals'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour afficher le popup de temps de repos entre exercices
  void _showRestTimePopup(Map<String, String> exercise) {
    int restBetweenExercises = 60;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = ref.watch(themeModeProvider);
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          title: Text(
            'Rest time',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restBetweenExercises > 10) {
                        setStateDialog(() {
                          restBetweenExercises -= 10;
                        });
                      }
                    },
                  ),
                  Text(
                    '$restBetweenExercises s',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setStateDialog(() {
                        restBetweenExercises += 10;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () async {
                Navigator.of(context).pop(); // Ferme le dialogue
                _addExerciseToProgramWithRest(exercise, restBetweenExercises);
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour ajouter un exercice au programme avec le temps de repos
  void _addExerciseToProgramWithRest(
      Map<String, String> exercise, int restBetweenExercises) async {
    // Ajout des valeurs par défaut à l'exercice
    Map<String, dynamic> newExercise = {
      'name': exercise['name'],
      'image': exercise['image'],
      'sets': 3,
      'reps': 10,
      'restTime': 60,
      'restBetweenExercises': restBetweenExercises,
      'weight': 0.0,
      'description': exercise['description'] ?? '',
      'goals': exercise['goals'] ?? '',
      'id': UniqueKey().toString(),
      'multipleWeights': false,
    };

    setState(() {
      exercises.add(newExercise);
      _hasChanges = true;
    });

    await _saveExercises();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeModeProvider); // Vérifie si le thème sombre est activé

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // Gère le comportement lors du retour arrière
        Navigator.of(context).pop(
            _hasChanges); // Retourne à la page précédente en passant l'indicateur de changements
        return false; // Empêche la fermeture automatique
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.black54
              : null, // Couleur de fond selon le thème
          title: Text(widget.program['name'] ??
              'Programme'), // Affiche le nom du programme dans la barre d'applications
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Icône de retour
            onPressed: () {
              Navigator.of(context).pop(
                  _hasChanges); // Retourne à la page précédente en passant l'indicateur de changements
            },
            tooltip: 'Retour',
          ),
          actions: [
            // Bouton pour basculer le mode d'édition de l'ordre
            IconButton(
              icon: Icon(_isEditingOrder
                  ? Icons.check
                  : Icons.reorder), // Icône changeante
              onPressed:
                  _toggleEditingOrder, // Appelle la méthode pour basculer le mode
              tooltip: _isEditingOrder
                  ? 'Terminer l\'édition'
                  : 'Réorganiser les exercices',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: exercises.isEmpty
                  ? Center(
                      // Si la liste des exercices est vide, affiche un message
                      child: Text(
                        'Aucun exercice ajouté au programme',
                        style: TextStyle(
                            fontSize: 18,
                            color:
                                isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : _isEditingOrder
                      ? ReorderableListView(
                          onReorder: _reorderExercises,
                          buildDefaultDragHandles: false,
                          children: [
                            for (int index = 0;
                                index < exercises.length;
                                index++)
                              Dismissible(
                                key: ValueKey(exercises[index]['id'] ?? index),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  setState(() {
                                    final removedItem =
                                        exercises.removeAt(index);
                                    _hasChanges = true;
                                    _saveExercises();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${removedItem['name']} supprimé'),
                                      ),
                                    );
                                  });
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                child: ListTile(
                                  leading: Semantics(
                                    label:
                                        'Image de l\'exercice ${exercises[index]['name']}',
                                    child: CircleAvatar(
                                      backgroundImage:
                                          AssetImage(exercises[index]['image']),
                                    ),
                                  ),
                                  title: Text(
                                    exercises[index]['name'] ?? 'Exercice',
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  trailing: ReorderableDragStartListener(
                                    index: index,
                                    child: Semantics(
                                      label: 'Déplacer l\'exercice',
                                      child: const Icon(Icons.drag_handle),
                                    ),
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
                                  leading: Semantics(
                                    label:
                                        'Image de l\'exercice ${exercise['name']}',
                                    child: CircleAvatar(
                                      backgroundImage: AssetImage(
                                        exercise['image'],
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    exercise['name'] ?? 'Exercice',
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!exercise['multipleWeights'])
                                        Text(
                                          '${exercise['sets']} séries x ${exercise['reps']} répétitions\n'
                                          'Poids: ${exercise['weight']?.toStringAsFixed(1) ?? '0.0'} kg\n'
                                          'Repos entre séries: ${_formatDuration(exercise['restTime'] ?? 60)}',
                                          style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black87),
                                        ),
                                      if (exercise['multipleWeights'])
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${exercise['sets']} séries x ${exercise['reps']} répétitions',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                            Text(
                                              'Poids par série:',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                            ...List.generate(
                                              (exercise['weightsPerSet']
                                                      as List<dynamic>)
                                                  .length,
                                              (s) => Text(
                                                '  Série ${s + 1}: ${((exercise['weightsPerSet'] as List<dynamic>)[s] as double).toStringAsFixed(1)} kg',
                                                style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white70
                                                        : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              'Repos entre séries: ${_formatDuration(exercise['restTime'] ?? 60)}',
                                              style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black87),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editExercise(index),
                                    tooltip: 'Modifier l\'exercice',
                                  ),
                                ),
                                if (index < exercises.length - 1)
                                  // Si ce n'est pas le dernier exercice, affiche le temps de repos entre exercices
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () =>
                                              _changeRestBetweenExercises(
                                                  index, -10),
                                          tooltip: 'Change Rest time',
                                        ),
                                        Text(
                                          'Rest time: ${_formatDuration(exercises[index]['restBetweenExercises'] ?? 60)}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () =>
                                              _changeRestBetweenExercises(
                                                  index, 10),
                                          tooltip:
                                              'Augmenter le temps de repos entre les exercices',
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: CupertinoButton(
                    color: darkWidget,
                    borderRadius: BorderRadius.circular(30.0),
                    onPressed: _addNewExercises,
                    child: const Text(
                      'Add new exercises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
