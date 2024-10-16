import 'package:flutter/material.dart';
import 'package:yellowmuscu/data/exercises_data.dart'; // Remplacez par l'import de vos données
import 'package:yellowmuscu/Exercise_Page_Widgets/ExerciseCategoryList.dart'; // Remplacez par votre import réel
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'ProgramDetailPage.dart'; // Import pour la page de détail du programme

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final List<Map<String, dynamic>> _categories = [
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

  List<Map<String, dynamic>> _programs = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchPrograms();
    }
  }

  void _fetchPrograms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .get();

      setState(() {
        _programs = snapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data();

          List<dynamic> exercisesData = data['exercises'] ?? [];

          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is String) {
                  // Convertir la chaîne en map avec des valeurs par défaut
                  return {
                    'name': exercise,
                    'image': '',
                    'sets': 3,
                    'reps': 10,
                    'restTime': 60,
                    'restBetweenExercises': 60,
                    'weight': 0,
                    'description': '',
                    'goals': '',
                  };
                } else if (exercise is Map<String, dynamic>) {
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>()
              .toList();

          return {
            'id': doc.id,
            'name': data['name'] ?? 'Programme sans nom',
            'isFavorite': data['isFavorite'] ?? false,
            'exercises': exercises,
          };
        }).toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des programmes : $e');
    }
  }

  void _showExercises(String category) {
    List<Map<String, String>> exercises;

    // Remplacez par vos données réelles pour chaque catégorie
    if (category == 'Biceps') {
      exercises = ExercisesData.bicepsExercises;
    } else if (category == 'Abs') {
      exercises = ExercisesData.abExercises;
    } else if (category == 'Triceps') {
      exercises = ExercisesData.tricepsExercises;
    } else if (category == 'Legs & Glutes') {
      exercises = ExercisesData.legExercises;
    } else if (category == 'Chest') {
      exercises = ExercisesData.chestExercises;
    } else if (category == 'Back') {
      exercises = ExercisesData.backExercises;
    } else if (category == 'Shoulders') {
      exercises = ExercisesData.shoulderExercises;
    } else if (category == 'Calves') {
      exercises = ExercisesData.calfExercises;
    } else if (category == 'Stretching') {
      exercises = ExercisesData.stretchingExercises;
    } else {
      exercises = [];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
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
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported);
                              },
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        exercise['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info_outline,
                                color: Colors.white),
                            onPressed: () {
                              _showExerciseInfo(exercise);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              _showProgramSelection(exercise);
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
  }

  void _showExerciseInfo(Map<String, String> exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(exercise['description'] ?? ''),
                const SizedBox(height: 16),
                const Text(
                  'Objectifs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(exercise['goals'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showProgramSelection(Map<String, String> exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _user == null
              ? const Center(
                  child: Text(
                    'Veuillez vous connecter pour ajouter des exercices aux programmes.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sélectionnez un programme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _programs.length,
                      itemBuilder: (context, index) {
                        final program = _programs[index];
                        return ListTile(
                          title: Text(
                            program['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showRestTimePopup(exercise, index);
                          },
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showRestTimePopup(Map<String, String> exercise, int programIndex) {
    int restBetweenExercises = 60; // Valeur par défaut
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Temps de repos entre exercices'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restBetweenExercises > 10) {
                        setState(() {
                          restBetweenExercises -= 10;
                        });
                      }
                    },
                  ),
                  Text('$restBetweenExercises s'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
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
              onPressed: () {
                _addExerciseToProgram(
                    programIndex, exercise, restBetweenExercises);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addExerciseToProgram(int programIndex, Map<String, String> exercise,
      int restBetweenExercises) async {
    if (_user != null) {
      final program = _programs[programIndex];
      program['exercises'].add({
        'name': exercise['name'],
        'image': exercise['image'],
        'sets': 3,
        'reps': 10,
        'restTime': 60, // Temps de repos entre séries par défaut
        'restBetweenExercises': restBetweenExercises,
        'weight': 0,
        'description': exercise['description'] ?? '',
        'goals': exercise['goals'] ?? '',
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(program['id'])
          .update({
        'exercises': program['exercises'],
      });

      setState(() {
        _programs[programIndex] = program;
      });
    }
  }

  void _showProgramDetail(Map<String, dynamic> program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailPage(
          program: program,
          userId: _user!.uid,
          onUpdate: _fetchPrograms,
        ),
      ),
    );
  }

  void _toggleFavorite(int index) async {
    if (_user != null) {
      final program = _programs[index];
      program['isFavorite'] = !program['isFavorite'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(program['id'])
          .update({
        'isFavorite': program['isFavorite'],
      });

      setState(() {
        _programs.sort((a, b) {
          if (a['isFavorite'] && !b['isFavorite']) {
            return -1;
          } else if (!a['isFavorite'] && b['isFavorite']) {
            return 1;
          } else {
            return 0;
          }
        });
      });
    }
  }

  void _deleteProgram(int index) async {
    if (_user != null) {
      final programId = _programs[index]['id'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .delete();

      setState(() {
        _programs.removeAt(index);
      });
    }
  }

  void _addNewProgram(BuildContext context) {
    final TextEditingController programController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un nouveau programme'),
          content: TextField(
            controller: programController,
            decoration: const InputDecoration(
              labelText: 'Nom du programme',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Ferme le pop-up quand "Annuler" est pressé
              },
            ),
            TextButton(
              child: const Text('Ajouter'), // Le bouton "Ajouter"
              onPressed: () async {
                // Vérifier que le champ de texte n'est pas vide
                if (programController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer un nom de programme.'),
                    ),
                  );
                  return; // Arrêter si le nom est vide
                }

                if (_user != null) {
                  final newProgram = {
                    'name': programController.text,
                    'isFavorite': false,
                    'exercises': [],
                  };

                  // Ajouter le nouveau programme dans Firestore
                  DocumentReference programRef = await FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('programs')
                      .add(newProgram);

                  // Enregistrer l'événement de création de programme dans Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('events')
                      .add({
                    'description':
                        'Création d\'un nouveau programme: ${programController.text}',
                    'timestamp': FieldValue.serverTimestamp(),
                    //'profileImage': _selectedProfilePicture ?? '', // Optionnel
                    'programId': programRef.id, // Référence au programme créé
                  });

                  // Mettre à jour la liste des programmes
                  _fetchPrograms();

                  // Fermer le pop-up après avoir ajouté le programme
                  Navigator.of(context).pop();

                  // Afficher un message de succès
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Programme "${programController.text}" créé avec succès.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgramItem(
      String programName, bool isFavorite, VoidCallback onFavoriteToggle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            programName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.yellow[700] : Colors.black,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dégradé de fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromRGBO(255, 204, 0, 1.0),
                const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _user == null
                ? Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signIn');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                      ),
                      child: const Text('Se connecter'),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bibliothèque',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: ExerciseCategoryList(
                            categories: _categories,
                            onCategoryTap: _showExercises,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ligne pour 'Mes Programmes' et le bouton '+'
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mes Programmes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.black),
                            onPressed: () {
                              _addNewProgram(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _programs.length,
                          itemBuilder: (context, index) {
                            final program = _programs[index];
                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (direction) {
                                _deleteProgram(index);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${program['name']} a été supprimé'),
                                  ),
                                );
                              },
                              background: Container(
                                padding: const EdgeInsets.only(left: 16),
                                alignment: Alignment.centerLeft,
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () => _showProgramDetail(program),
                                child: _buildProgramItem(
                                  program['name'],
                                  program['isFavorite'],
                                  () => _toggleFavorite(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
