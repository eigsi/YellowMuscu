import 'package:flutter/material.dart';
import 'package:yellowmuscu/data/exercises_data.dart';
import 'package:yellowmuscu/Exercise_Page_Widgets/ExerciseCategoryList.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

import 'package:yellowmuscu/Screens/ProgramDetailPage.dart';

class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
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
            'icon': data['icon'] ?? 'lib/data/icon_images/chest_part.png',
            'iconName': data['iconName'] ?? 'Chest part',
            'day': data['day'] ?? '',
            'isFavorite': data['isFavorite'] ?? false,
            'exercises': exercises,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des programmes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showExercises(String category) {
    List<Map<String, String>> exercises;

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

    final isDarkMode = ref.watch(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
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
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.info_outline,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                            onPressed: () {
                              _showExerciseInfo(exercise);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.add,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
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
    final isDarkMode = ref.watch(themeProvider);

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
    final isDarkMode = ref.watch(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: _user == null
              ? Center(
                  child: Text(
                    'Veuillez vous connecter pour ajouter des exercices aux programmes.',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sélectionnez un programme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _programs.isEmpty
                        ? Text(
                            'Aucun programme disponible. Ajoutez-en un nouveau.',
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
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
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
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

  void _showRestTimePopup(Map<String, String> exercise, int programIndex) {
    int restBetweenExercises = 60;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = ref.watch(themeProvider);
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          title: Text(
            'Temps de repos entre exercices',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
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
                  Text(
                    '$restBetweenExercises s',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
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
                  Navigator.of(context).pop();
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

  Future<void> _addExerciseToProgram(int programIndex,
      Map<String, String> exercise, int restBetweenExercises) async {
    if (_user != null) {
      final program = _programs[programIndex];
      program['exercises'].add({
        'name': exercise['name'],
        'image': exercise['image'],
        'sets': 3,
        'reps': 10,
        'restTime': 60,
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
        rethrow;
      }

      if (!mounted) return;
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

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'isFavorite': program['isFavorite'],
        });
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

    final isDarkMode = ref.watch(themeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
          title: Text(
            'Ajouter un nouveau programme',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: programController,
                      decoration: InputDecoration(
                        labelText: 'Nom du programme',
                        labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionner une catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: InputDecoration(
                        labelText: selectedDay == null
                            ? 'Sélectionner un jour'
                            : 'Jour sélectionné',
                        labelStyle: TextStyle(
                          color: selectedDay == null
                              ? Colors.red
                              : isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: selectedDay == null
                                ? Colors.red
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.grey,
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
                      hint: Text(
                        'Sélectionner un jour',
                        style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
                      ),
                      dropdownColor: isDarkMode ? Colors.black54 : Colors.white,
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
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
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
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
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
                    'icon': selectedImage,
                    'iconName': selectedLabel,
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
                    Navigator.of(context).pop();
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

  Widget _buildProgramItem(String programName, String iconPath, String day,
      bool isFavorite, VoidCallback onFavoriteToggle) {
    final isDarkMode = ref.watch(themeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Affichage de l'image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    day,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Bouton favori
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite
                  ? Colors.yellow[700]
                  : isDarkMode
                      ? Colors.white
                      : Colors.black,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Stack(
      children: [
        // Dégradé de fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [const Color.fromRGBO(255, 204, 0, 1.0), Colors.black]
                  : [
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
                      Text(
                        'Bibliothèque',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Liste des catégories d'exercices
                      Expanded(
                        flex: 1,
                        child: Card(
                          color: isDarkMode ? Colors.black54 : Colors.white,
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: ExerciseCategoryList(
                            categories: _categories,
                            onCategoryTap: _showExercises,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Section "Mes Programmes" avec bouton d'ajout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mes Programmes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
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
                            ? Center(
                                child: Text(
                                  'Aucun programme disponible. Ajoutez-en un nouveau.',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
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
                                        program['icon'],
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
