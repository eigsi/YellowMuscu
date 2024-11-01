// Importation des packages nécessaires
import 'package:flutter/material.dart'; // Bibliothèque de widgets matériels de Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore de Firebase
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Pour la gestion de l'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour gérer le thème (clair/sombre)
import 'package:flutter/cupertino.dart'; // Widgets Cupertino pour le style iOS

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
    exercises = List<Map<String, dynamic>>.from(widget.program['exercises']);

    // Parcourt chaque exercice pour s'assurer que certaines clés existent
    for (var exercise in exercises) {
      if (!exercise.containsKey('restBetweenExercises')) {
        exercise['restBetweenExercises'] =
            60; // Définit une valeur par défaut de 60 secondes
      }
      if (!exercise.containsKey('restTime')) {
        exercise['restTime'] =
            60; // Définit une valeur par défaut de 60 secondes
      }
    }
  }

  // Méthode asynchrone pour sauvegarder les exercices modifiés dans Firestore
  Future<void> _saveExercises() async {
    await FirebaseFirestore.instance
        .collection('users') // Accède à la collection 'users'
        .doc(widget.userId) // Sélectionne le document de l'utilisateur actuel
        .collection('programs') // Accède à la sous-collection 'programs'
        .doc(widget.program['id']) // Sélectionne le programme spécifique
        .update({'exercises': exercises}); // Met à jour la liste des exercices

    widget
        .onUpdate(); // Appelle la fonction de mise à jour pour notifier les changements
  }

  // Méthode pour afficher un sélecteur de temps de repos (style iOS)
  void _showRestTimePicker(BuildContext context, int currentRestTime,
      ValueChanged<int> onRestTimeChanged) {
    int currentMinutes = currentRestTime ~/ 60; // Calcule les minutes initiales
    int currentSeconds = currentRestTime % 60; // Calcule les secondes initiales

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: Colors.white, // Couleur de fond
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Picker pour les minutes
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
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
                  backgroundColor: Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: currentSeconds ~/
                        10, // Valeur initiale en secondes (par tranche de 10)
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

    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250, // Hauteur du modal
          color: Colors.white, // Couleur de fond
          child: Column(
            children: [
              // Titre du picker
              Text(title, style: const TextStyle(fontSize: 20)),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.white,
                  itemExtent: 32.0, // Hauteur de chaque élément
                  scrollController: FixedExtentScrollController(
                    initialItem: (currentValue - minValue) ~/
                        step, // Position initiale du picker
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

  // Méthode pour éditer un exercice spécifique
  void _editExercise(int index) {
    final exercise = exercises[index]; // Récupère l'exercice à l'index donné
    int sets = exercise['sets']; // Nombre de séries
    int reps = exercise['reps']; // Nombre de répétitions
    double weight = exercise['weight'] ?? 0.0; // Poids, par défaut 0.0
    int restTime = exercise['restTime'] ??
        60; // Temps de repos entre séries, par défaut 60 secondes

    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Utilise un StatefulBuilder pour gérer l'état local dans le dialogue
          return AlertDialog(
            backgroundColor: isDarkMode
                ? Colors.black54
                : Colors.white, // Couleur de fond selon le thème
            title: Text(
              'Modifier ${exercise['name']}', // Titre du dialogue
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Column(
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
                            setState(() {
                              sets = newSets; // Met à jour le nombre de séries
                            });
                          },
                        );
                      },
                      child: Text('$sets séries'), // Affiche la valeur actuelle
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
                            setState(() {
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
                              weight =
                                  newWeight.toDouble(); // Met à jour le poids
                            });
                          },
                        );
                      },
                      child: Text('$weight kg'),
                    ),
                  ],
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
                          setState(() {
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
              ],
            ),
            actions: [
              // Bouton pour annuler les modifications
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              // Bouton pour enregistrer les modifications
              TextButton(
                child: const Text('Enregistrer'),
                onPressed: () async {
                  setState(() {
                    // Met à jour les valeurs de l'exercice dans la liste
                    exercises[index]['sets'] = sets;
                    exercises[index]['reps'] = reps;
                    exercises[index]['weight'] = weight;
                    exercises[index]['restTime'] = restTime;
                  });

                  // Sauvegarde les modifications dans Firestore
                  await _saveExercises();

                  _hasChanges =
                      true; // Indique que des modifications ont été effectuées

                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      _saveExercises(); // Sauvegarde les données après fermeture du modal
    });
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
          .removeAt(oldIndex); // Supprime l'exercice de son ancienne position
      exercises.insert(
          newIndex, item); // Insère l'exercice à la nouvelle position
      _hasChanges = true; // Indique que des modifications ont été effectuées
    });
  }

  // Méthode pour basculer le mode d'édition de l'ordre des exercices
  void _toggleEditingOrder() {
    setState(() {
      _isEditingOrder = !_isEditingOrder; // Inverse la valeur booléenne
      if (!_isEditingOrder) {
        _saveExercises(); // Sauvegarde les modifications si on quitte le mode édition
        if (!_hasChanges) {
          _hasChanges =
              true; // Indique que des modifications ont été effectuées
        }
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

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
          title: Text(widget.program[
              'name']), // Affiche le nom du programme dans la barre d'applications
          leading: IconButton(
            icon: const Icon(Icons.arrow_back), // Icône de retour
            onPressed: () {
              Navigator.of(context).pop(
                  _hasChanges); // Retourne à la page précédente en passant l'indicateur de changements
            },
          ),
          actions: [
            // Bouton pour basculer le mode d'édition de l'ordre
            IconButton(
              icon: Icon(_isEditingOrder
                  ? Icons.check
                  : Icons.reorder), // Icône changeante
              onPressed:
                  _toggleEditingOrder, // Appelle la méthode pour basculer le mode
            ),
          ],
        ),
        body: exercises.isEmpty
            ? Center(
                // Si la liste des exercices est vide, affiche un message
                child: Text(
                  'Aucun exercice ajouté au programme',
                  style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
              )
            : _isEditingOrder
                ? ReorderableListView(
                    // Si en mode d'édition de l'ordre, affiche une liste réorganisable
                    onReorder:
                        _reorderExercises, // Méthode pour gérer le réordonnancement
                    buildDefaultDragHandles:
                        false, // Désactive les poignées de glissement par défaut
                    children: [
                      for (int index = 0; index < exercises.length; index++)
                        Dismissible(
                          key: ValueKey(exercises[index]['id'] ??
                              index), // Clé unique pour chaque élément
                          direction: DismissDirection
                              .endToStart, // Direction du glissement pour supprimer
                          onDismissed: (direction) {
                            setState(() {
                              final removedItem = exercises.removeAt(
                                  index); // Supprime l'exercice de la liste
                              _hasChanges =
                                  true; // Indique que des modifications ont été effectuées
                              _saveExercises(); // Sauvegarde les modifications
                              // Affiche un message indiquant que l'exercice a été supprimé
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${removedItem['name']} supprimé'),
                                ),
                              );
                            });
                          },
                          background: Container(
                            color: Colors
                                .red, // Couleur de fond lors du glissement
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.delete,
                                color: Colors.white), // Icône de suppression
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(exercises[index]
                                  ['image']), // Affiche l'image de l'exercice
                            ),
                            title: Text(
                              exercises[index]['name'], // Nom de l'exercice
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black),
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index, // Index de l'élément
                              child: const Icon(Icons
                                  .drag_handle), // Icône pour indiquer que l'élément est déplaçable
                            ),
                          ),
                        ),
                    ],
                  )
                : ListView.builder(
                    // Si pas en mode d'édition de l'ordre, affiche une liste standard
                    itemCount:
                        exercises.length, // Nombre d'éléments dans la liste
                    itemBuilder: (context, index) {
                      final exercise = exercises[
                          index]; // Récupère l'exercice à l'index donné
                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(exercise[
                                  'image']), // Affiche l'image de l'exercice
                            ),
                            title: Text(
                              exercise['name'], // Nom de l'exercice
                              style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black),
                            ),
                            subtitle: Text(
                              // Affiche les détails de l'exercice
                              '${exercise['sets']} séries x ${exercise['reps']} répétitions\n'
                              'Poids: ${exercise['weight'] ?? 0} kg\n'
                              'Repos entre séries: ${_formatDuration(exercise['restTime'] ?? 60)}',
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                  Icons.edit), // Icône pour éditer l'exercice
                              onPressed: () => _editExercise(
                                  index), // Appelle la méthode pour éditer l'exercice
                            ),
                          ),
                          if (index < exercises.length - 1)
                            // Si ce n'est pas le dernier exercice, affiche le temps de repos entre exercices
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons
                                      .remove), // Icône pour diminuer le temps
                                  onPressed: () => _changeRestBetweenExercises(
                                      index, -10), // Diminue de 10 secondes
                                ),
                                Text(
                                  'Repos entre exercices: ${_formatDuration(exercises[index]['restBetweenExercises'])}', // Affiche le temps de repos
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                IconButton(
                                  icon: const Icon(Icons
                                      .add), // Icône pour augmenter le temps
                                  onPressed: () => _changeRestBetweenExercises(
                                      index, 10), // Augmente de 10 secondes
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
