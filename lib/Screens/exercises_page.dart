// ExercisesPage.dart

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
  // Liste des catégories avec des icônes IconData (Peut être utilisé ailleurs)
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

  // Liste des programmes récupérés depuis Firestore
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

  // Méthode pour récupérer les programmes depuis Firestore
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
            'icon': data['icon'] ??
                'lib/data/icon_images/chest_part.png', // Valeur par défaut en String
            'iconName': data['iconName'] ?? 'Chest part', // Nom de l'icône
            'day': data['day'] ?? '',
            'isFavorite': data['isFavorite'] ?? false,
            'exercises': exercises,
          };
        }).toList();
      });
    } catch (e) {
      // Gérer les erreurs si nécessaire
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des programmes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour afficher les exercices d'une catégorie
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
      isScrollControlled: true, // Permet à la modal de s'étendre
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height *
              0.7, // Définir une hauteur maximale
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

  // Méthode pour afficher les informations d'un exercice
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

  // Méthode pour sélectionner un programme et ajouter un exercice
  void _showProgramSelection(Map<String, String> exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
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
                    _programs.isEmpty
                        ? const Text(
                            'Aucun programme disponible. Ajoutez-en un nouveau.',
                            style: TextStyle(color: Colors.white),
                          )
                        : Expanded(
                            child: ListView.builder(
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
                          ),
                  ],
                ),
        );
      },
    );
  }

  // Méthode pour afficher le popup de temps de repos
  void _showRestTimePopup(Map<String, String> exercise, int programIndex) {
    int restBetweenExercises = 60; // Valeur par défaut
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Temps de repos entre exercices'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _addExerciseToProgram(
                      programIndex, exercise, restBetweenExercises);
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Ferme le popup après ajout
                } catch (e) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de l\'ajout de l\'exercice.'),
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

  // Méthode pour ajouter un exercice à un programme
  Future<void> _addExerciseToProgram(int programIndex,
      Map<String, String> exercise, int restBetweenExercises) async {
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

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'exercises': program['exercises'],
        });
      } catch (e) {
        rethrow; // Propager l'erreur pour qu'elle soit capturée dans le caller
      }

      if (!mounted) return;
      setState(() {
        _programs[programIndex] = program;
      });
    }
  }

  // Méthode pour afficher les détails d'un programme
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

  // Méthode pour basculer l'état favori d'un programme
  void _toggleFavorite(int index) async {
    if (_user != null) {
      final program = _programs[index];
      program['isFavorite'] = !program['isFavorite'];

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'isFavorite': program['isFavorite'],
        });
        // ignore: empty_catches
      } catch (e) {}

      if (!mounted) return;
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

  // Méthode pour supprimer un programme
  void _deleteProgram(int index) async {
    if (_user != null) {
      final programId = _programs[index]['id'];
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(programId)
            .delete();
        // ignore: empty_catches
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _programs.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Programme "${_programs[index]['name']}" a été supprimé'),
        ),
      );
    }
  }

  // Méthode pour ajouter un nouveau programme
  void _addNewProgram(BuildContext context) {
    final TextEditingController programController = TextEditingController();
    String? selectedDay;
    String? selectedImage;
    String? selectedLabel;

    final List<Map<String, dynamic>> imageOptions = [
      {'name': 'Chest part', 'image': 'lib/data/icon_images/chest_part.png'},
      {'name': 'Back part', 'image': 'lib/data/icon_images/back_part.png'},
      {'name': 'Leg part', 'image': 'lib/data/icon_images/leg_part.png'},
    ];

    final List<String> daysOfWeek = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter un nouveau programme'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Champ pour le nom du programme
                    TextField(
                      controller: programController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du programme',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sélection de l'image avec texte
                    const Text(
                      'Sélectionner une catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Utilisation de Wrap avec images et textes
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: imageOptions.map((option) {
                        final isSelected = selectedImage == option['image'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = option['image'];
                              selectedLabel = option['name'];
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.black, width: 3)
                                      : null,
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    option['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Sélection du jour avec message si non sélectionné
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: InputDecoration(
                        // Le texte change en fonction de la sélection
                        labelText: selectedDay == null
                            ? 'Sélectionner un jour'
                            : 'Jour sélectionné',
                        labelStyle: TextStyle(
                          color: selectedDay == null
                              ? Colors.red
                              : Colors
                                  .black, // Rouge si non sélectionné, noir sinon
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                selectedDay == null ? Colors.red : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                selectedDay == null ? Colors.red : Colors.blue,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      hint: const Text(
                        'Sélectionner un jour',
                        style: TextStyle(color: Colors.black),
                      ),
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDay = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sélectionner un jour';
                        }
                        return null;
                      },
                      items: daysOfWeek
                          .map<DropdownMenuItem<String>>((String day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(
                            day,
                            style: const TextStyle(color: Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            // Bouton Annuler
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Bouton Ajouter
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (programController.text.isEmpty ||
                    selectedImage == null ||
                    selectedDay == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs.'),
                    ),
                  );
                  return;
                }

                if (_user != null) {
                  final newProgram = {
                    'name': programController.text,
                    'icon':
                        selectedImage, // Stockage de l'image en tant que String
                    'iconName': selectedLabel, // Stockage du nom de l'image
                    'day': selectedDay,
                    'isFavorite': false,
                    'exercises': [],
                  };

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('programs')
                        .add(newProgram);
                    _fetchPrograms();
                    Navigator.of(context).pop(); // Ferme le pop-up après ajout
                  } catch (e) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de l\'ajout du programme.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour construire un widget de programme
  Widget _buildProgramItem(String programName, String iconPath, String day,
      bool isFavorite, VoidCallback onFavoriteToggle) {
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
          // Informations du programme
          Row(
            children: [
              // Affichage de l'image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: AssetImage(iconPath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Affichage du nom et du jour
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          // Bouton favori
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
                      // Liste des catégories d'exercices
                      Expanded(
                        flex: 1,
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
                      // Section "Mes Programmes" avec bouton d'ajout
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
                      // Liste des programmes
                      Expanded(
                        flex: 1,
                        child: _programs.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun programme disponible. Ajoutez-en un nouveau.',
                                  style: TextStyle(color: Colors.black),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _programs.length,
                                itemBuilder: (context, index) {
                                  final program = _programs[index];
                                  return Dismissible(
                                    key: UniqueKey(),
                                    direction: DismissDirection.startToEnd,
                                    onDismissed: (direction) {
                                      _deleteProgram(index);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                        program['icon'], // Chemin de l'image
                                        program['day'] ?? '',
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
