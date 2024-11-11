// Importation des bibliothèques nécessaires
import 'package:flutter/material.dart'; // Widgets et thèmes Material Design
import 'package:yellowmuscu/data/exercises_data.dart'; // Données des exercices
import 'package:yellowmuscu/Exercise/exercise_category_list.dart'; // Widget personnalisé pour la liste des catégories d'exercices
import 'package:firebase_auth/firebase_auth.dart'; // Authentification Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de données Cloud Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Gestion d'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour le thème (mode clair/sombre)
import 'package:yellowmuscu/Screens/ProgramDetailPage.dart'; // Page de détail d'un programme

// Déclaration de la classe principale de la page des exercices
class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key}); // Constructeur de la classe

  @override
  ExercisesPageState createState() =>
      ExercisesPageState(); // Création de l'état associé
}

// Classe d'état pour ExercisesPage
class ExercisesPageState extends ConsumerState<ExercisesPage> {
  // Liste des catégories d'exercices avec leur nom et icône
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

  // Liste des programmes de l'utilisateur
  List<Map<String, dynamic>> _programs = [];

  // Instance de FirebaseAuth pour l'authentification
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Utilisateur actuellement connecté

  @override
  void initState() {
    super.initState(); // Appel de la méthode initState de la classe parente
    _user = _auth.currentUser; // Récupération de l'utilisateur connecté
    if (_user != null) {
      _fetchPrograms(); // Si un utilisateur est connecté, récupération de ses programmes
    }
  }

  // Méthode pour récupérer les programmes de l'utilisateur depuis Firestore
  void _fetchPrograms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users') // Accès à la collection 'users'
          .doc(_user!.uid) // Document correspondant à l'utilisateur connecté
          .collection('programs') // Sous-collection 'programs' de l'utilisateur
          .get(); // Récupération des documents

      // Mise à jour de l'état avec la liste des programmes
      if (!mounted) return;
      setState(() {
        _programs = snapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data(); // Données du document

          // Récupération des exercices du programme
          List<dynamic> exercisesData = data['exercises'] ?? [];

          // Transformation des exercices en liste de Map<String, dynamic>
          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is String) {
                  // Si l'exercice est une chaîne, création d'une Map par défaut
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
                  // Si c'est déjà une Map, la convertir
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return null; // Sinon, ignorer
                }
              })
              .whereType<Map<String, dynamic>>() // Filtrer les null
              .toList();

          // Retourner une Map représentant le programme
          return {
            'id': doc.id, // Identifiant du document
            'name': data['name'] ?? 'Programme sans nom', // Nom du programme
            'icon':
                data['icon'] ?? 'lib/data/icon_images/chest_part.png', // Icône
            'iconName': data['iconName'] ?? 'Chest part', // Nom de l'icône
            'day': data['day'] ?? '', // Jour associé au programme
            'isFavorite': data['isFavorite'] ?? false, // Statut favori
            'exercises': exercises, // Liste des exercices
          };
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      // En cas d'erreur, afficher un message à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des programmes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour afficher les exercices d'une catégorie sélectionnée
  void _showExercises(String category) {
    List<Map<String, String>> exercises; // Liste des exercices à afficher

    // Sélection des exercices en fonction de la catégorie
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
      exercises = []; // Si la catégorie n'est pas reconnue, liste vide
    }

    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

    // Ajout d'un contrôleur pour la recherche
    TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredExercises = List.from(exercises);

    // Affichage d'une feuille de bas (modal bottom sheet) avec la liste des exercices
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16.0)), // Coins arrondis
      ),
      isScrollControlled:
          true, // Permet le scroll si le contenu dépasse la hauteur
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: const EdgeInsets.all(16.0), // Marges internes
              height: MediaQuery.of(context).size.height *
                  0.8, // Hauteur de 80% de l'écran
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alignement à gauche
                children: [
                  // Titre de la catégorie
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16), // Espacement vertical
                  // Barre de recherche
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un exercice',
                      hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : Colors.grey[600]), // Couleur du placeholder
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
                        filteredExercises = exercises
                            .where((exercise) => exercise['name']!
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16), // Espacement vertical
                  // Liste des exercices
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
                            shrinkWrap: true,
                            physics:
                                const BouncingScrollPhysics(), // Effet de rebond
                            itemCount:
                                filteredExercises.length, // Nombre d'éléments
                            itemBuilder: (context, index) {
                              final exercise =
                                  filteredExercises[index]; // Exercice actuel
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
                                        exercise[
                                            'image']!, // Image de l'exercice
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
                                  exercise['name']!, // Nom de l'exercice
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                trailing: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Ajuste la taille
                                  children: [
                                    // Bouton pour afficher les détails de l'exercice
                                    IconButton(
                                      icon: Icon(Icons.info_outline,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showExerciseInfo(
                                            exercise); // Affiche les infos
                                      },
                                    ),
                                    // Bouton pour ajouter l'exercice à un programme
                                    IconButton(
                                      icon: Icon(Icons.add,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                      onPressed: () {
                                        _showProgramSelection(
                                            exercise); // Sélection du programme
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

  // Méthode pour afficher les informations détaillées d'un exercice
  void _showExerciseInfo(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

    // Affichage d'une boîte de dialogue avec les détails de l'exercice
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
          contentPadding: const EdgeInsets.all(16.0), // Marges internes
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ajuste la taille
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Alignement à gauche
              children: [
                // Affichage de l'image de l'exercice
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
                const SizedBox(height: 16), // Espacement vertical
                // Titre "Description"
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8), // Espacement vertical
                // Texte de la description
                Text(
                  exercise['description'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16), // Espacement vertical
                // Titre "Objectifs"
                Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8), // Espacement vertical
                // Texte des objectifs
                Text(
                  exercise['goals'] ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
          actions: [
            // Bouton pour fermer la boîte de dialogue
            TextButton(
              child: const Text('Fermer'),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
          ],
        );
      },
    );
  }

  // Méthode pour sélectionner un programme auquel ajouter l'exercice
  void _showProgramSelection(Map<String, String> exercise) {
    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

    // Tri des programmes par ordre alphabétique
    List<Map<String, dynamic>> sortedPrograms = List.from(_programs);
    sortedPrograms.sort((a, b) => a['name'].compareTo(b['name']));

    // Affichage d'une feuille de bas avec la liste des programmes
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16.0)), // Coins arrondis
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0), // Marges internes
          child: _user == null
              ? Center(
                  // Message si l'utilisateur n'est pas connecté
                  child: Text(
                    'Veuillez vous connecter pour ajouter des exercices aux programmes.',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                )
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Alignement à gauche
                  mainAxisSize: MainAxisSize.min, // Ajuste la taille
                  children: [
                    // Titre
                    Text(
                      'Sélectionnez un programme',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16), // Espacement vertical
                    sortedPrograms.isEmpty
                        ? Text(
                            // Message si aucun programme n'est disponible
                            'Aucun programme disponible. Ajoutez-en un nouveau.',
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          )
                        : Expanded(
                            // Liste des programmes disponibles
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: sortedPrograms.length,
                              itemBuilder: (context, index) {
                                final program =
                                    sortedPrograms[index]; // Programme actuel
                                return ListTile(
                                  title: Text(
                                    program['name'], // Nom du programme
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  onTap: () {
                                    Navigator.of(context)
                                        .pop(); // Ferme la feuille de bas
                                    _showRestTimePopup(
                                        exercise,
                                        _programs.indexWhere((p) =>
                                            p['id'] ==
                                            program[
                                                'id'])); // Demande le temps de repos
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

  // Méthode pour demander le temps de repos entre les exercices
  void _showRestTimePopup(Map<String, String> exercise, int programIndex) {
    int restBetweenExercises = 60; // Temps de repos par défaut
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = ref.watch(themeProvider); // Vérification du thème
        return AlertDialog(
          backgroundColor:
              isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
          title: Text(
            'Temps de repos entre exercices',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centré horizontalement
                children: [
                  // Bouton pour diminuer le temps de repos
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (restBetweenExercises > 10) {
                        setStateDialog(() {
                          restBetweenExercises -= 10; // Diminue de 10 secondes
                        });
                      }
                    },
                  ),
                  // Affichage du temps de repos actuel
                  Text(
                    '$restBetweenExercises s',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  // Bouton pour augmenter le temps de repos
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setStateDialog(() {
                        restBetweenExercises += 10; // Augmente de 10 secondes
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            // Bouton pour ajouter l'exercice au programme
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () async {
                final messenger =
                    ScaffoldMessenger.of(context); // Pour afficher des messages
                try {
                  await _addExerciseToProgram(
                      programIndex, exercise, restBetweenExercises); // Ajout
                  if (!mounted)
                    return; // Vérifie que le widget est toujours monté
                  Navigator.of(context).pop(); // Ferme la boîte de dialogue
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text('Erreur lors de l\'ajout de l\'exercice: $e'),
                      backgroundColor: Colors.red,
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

  // Méthode pour ajouter l'exercice au programme sélectionné
  Future<void> _addExerciseToProgram(int programIndex,
      Map<String, String> exercise, int restBetweenExercises) async {
    if (_user != null) {
      final program = _programs[programIndex]; // Programme sélectionné
      // Ajout de l'exercice à la liste des exercices du programme
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
        // Mise à jour du programme dans Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'exercises': program['exercises'],
        });
      } catch (e) {
        rethrow; // Relance l'exception
      }

      if (!mounted) return; // Vérifie que le widget est toujours monté
      setState(() {
        _programs[programIndex] = program; // Mise à jour de l'état local
      });
    }
  }

  // Méthode pour supprimer un programme
  void _deleteProgram(int index) async {
    if (_user != null) {
      final program = _programs[index]; // Programme sélectionné
      final programId = program['id']; // Identifiant du programme
      try {
        // Suppression du programme dans Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(programId)
            .delete();
      } catch (e) {
        if (!mounted) return;
        // En cas d'erreur, afficher un message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return; // Vérifie que le widget est toujours monté
      setState(() {
        _programs.removeAt(index); // Retire le programme de la liste locale
      });

      // Affiche un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programme "${program['name']}" a été supprimé'),
        ),
      );
    }
  }

  // Méthode pour ajouter un nouveau programme
  void _addNewProgram(BuildContext context) {
    final TextEditingController programController =
        TextEditingController(); // Contrôleur pour le champ de texte
    String? selectedDay; // Jour sélectionné
    String? selectedImage; // Image sélectionnée
    String? selectedLabel; // Nom de l'image sélectionnée

    // Liste des options d'images disponibles
    final List<Map<String, dynamic>> imageOptions = [
      {'name': 'Chest part', 'image': 'lib/data/icon_images/chest_part.png'},
      {'name': 'Back part', 'image': 'lib/data/icon_images/back_part.png'},
      {'name': 'Leg part', 'image': 'lib/data/icon_images/leg_part.png'},
    ];

    // Liste des jours de la semaine
    final List<String> daysOfWeek = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];

    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

    // Affichage d'une boîte de dialogue pour ajouter un programme
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
          title: Text(
            'Ajouter un nouveau programme',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ajuste la taille
                  children: [
                    // Champ de texte pour le nom du programme
                    TextField(
                      controller: programController,
                      decoration: InputDecoration(
                        labelText: 'Nom du programme',
                        labelStyle: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black),
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
                    ),
                    const SizedBox(height: 16), // Espacement vertical
                    // Titre "Sélectionner une catégorie"
                    Text(
                      'Sélectionner une catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8), // Espacement vertical
                    // Options d'images
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: imageOptions.map((option) {
                        final isSelected = selectedImage ==
                            option[
                                'image']; // Vérifie si l'image est sélectionnée
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              selectedImage = option[
                                  'image']; // Met à jour l'image sélectionnée
                              selectedLabel = option[
                                  'name']; // Met à jour le nom de l'image
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Ajuste la taille
                            children: [
                              // Image de la catégorie
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.black,
                                          width: 3) // Bordure si sélectionnée
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
                              const SizedBox(height: 4), // Espacement vertical
                              // Nom de la catégorie
                              Text(
                                option['name'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.black.withOpacity(
                                          0.3), // Opacité réduite si non sélectionnée
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16), // Espacement vertical
                    // Menu déroulant pour sélectionner le jour
                    DropdownButtonFormField<String>(
                      value: selectedDay, // Jour actuellement sélectionné
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
                      dropdownColor: isDarkMode
                          ? Colors.black54
                          : Colors.white, // Couleur du menu déroulant
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedDay =
                              newValue; // Met à jour le jour sélectionné
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sélectionner un jour'; // Message d'erreur si aucun jour sélectionné
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
            // Bouton "Annuler"
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop(); // Ferme la boîte de dialogue
              },
            ),
            // Bouton "Ajouter"
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () async {
                final messenger =
                    ScaffoldMessenger.of(context); // Pour afficher des messages
                // Vérifie que tous les champs sont remplis
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
                    'name': programController.text, // Nom du programme
                    'icon': selectedImage, // Image sélectionnée
                    'iconName': selectedLabel, // Nom de l'image
                    'day': selectedDay, // Jour sélectionné
                    'isFavorite': false, // Par défaut, non favori
                    'exercises': [], // Liste vide d'exercices
                  };

                  try {
                    // Ajoute le nouveau programme à Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('programs')
                        .add(newProgram);
                    if (!mounted)
                      return; // Vérifie que le widget est toujours monté
                    _fetchPrograms(); // Rafraîchit la liste des programmes
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            "Programme '${programController.text}' ajouté avec succès."),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text('Erreur lors de l\'ajout du programme: $e'),
                        backgroundColor: Colors.red,
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

  // Méthode pour construire l'élément visuel d'un programme dans la liste
  Widget _buildProgramItem(String programName, String iconPath, String day,
      bool isFavorite, VoidCallback onFavoriteToggle) {
    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0), // Marges externes
      padding: const EdgeInsets.all(12.0), // Marges internes
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white, // Couleur de fond
        borderRadius: BorderRadius.circular(16.0), // Coins arrondis
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Répartition horizontale
        children: [
          Row(
            children: [
              // Image du programme
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
              const SizedBox(width: 16), // Espacement horizontal
              // Nom et jour du programme
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Alignement à gauche
                children: [
                  Text(
                    programName, // Nom du programme
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    day, // Jour du programme
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Bouton pour marquer le programme comme favori
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.star
                  : Icons.star_border, // Icône en fonction du statut
              color: isFavorite
                  ? Colors.yellow[700]
                  : isDarkMode
                      ? Colors.white
                      : Colors.black,
            ),
            onPressed: onFavoriteToggle, // Action lors de l'appui
          ),
        ],
      ),
    );
  }

  // Méthode pour basculer le statut favori d'un programme
  void _toggleFavorite(int index) async {
    if (_user != null) {
      final program = _programs[index]; // Programme sélectionné
      program['isFavorite'] = !program['isFavorite']; // Inverse le statut

      try {
        // Mise à jour dans Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('programs')
            .doc(program['id'])
            .update({
          'isFavorite': program['isFavorite'],
        });
      } catch (e) {
        // Gestion des erreurs (affichage d'un message)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour des favoris: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return; // Vérifie que le widget est toujours monté
      setState(() {
        // Trie les programmes pour que les favoris apparaissent en premier
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

  // Méthode pour afficher les détails d'un programme
  void _showProgramDetail(Map<String, dynamic> program) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramDetailPage(
          program: program, // Programme à afficher
          userId: _user!.uid, // Identifiant de l'utilisateur
          onUpdate: () {
            if (mounted) {
              _fetchPrograms(); // Rafraîchit les programmes si des changements ont été effectués
            }
          }, // Callback lors de la mise à jour
        ),
      ),
    );
    if (result == true && mounted) {
      _fetchPrograms(); // Rafraîchit les programmes si des changements ont été effectués
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider); // Vérification du thème

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
          backgroundColor: Colors.transparent, // Fond transparent
          body: Padding(
            padding: const EdgeInsets.all(16.0), // Marges internes
            child: _user == null
                ? Center(
                    // Si l'utilisateur n'est pas connecté, afficher un bouton de connexion
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context,
                            '/signIn'); // Navigation vers la page de connexion
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.yellow[700], // Couleur du bouton
                      ),
                      child: const Text('Se connecter'),
                    ),
                  )
                : Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Alignement à gauche
                    children: [
                      // Titre "Bibliothèque"
                      Text(
                        'Bibliothèque',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16), // Espacement vertical
                      // Liste des catégories d'exercices
                      Expanded(
                        flex: 1, // Prend l'espace disponible
                        child: Card(
                          color: isDarkMode
                              ? Colors.black54
                              : Colors.white, // Couleur de fond
                          elevation: 4.0, // Élévation pour l'ombre
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16.0), // Coins arrondis
                          ),
                          child: ExerciseCategoryList(
                            categories: _categories, // Liste des catégories
                            onCategoryTap:
                                _showExercises, // Action lors de la sélection d'une catégorie
                            isDarkMode: isDarkMode, // Thème
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Espacement vertical
                      // Titre "Mes Programmes" avec bouton d'ajout
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Répartition horizontale
                        children: [
                          Text(
                            'Mes Programmes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          // Bouton pour ajouter un nouveau programme
                          IconButton(
                            icon: Icon(Icons.add,
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                            onPressed: () {
                              _addNewProgram(
                                  context); // Appel de la méthode d'ajout
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Espacement vertical
                      // Liste des programmes
                      Expanded(
                        flex: 1, // Prend l'espace disponible
                        child: _programs.isEmpty
                            ? Center(
                                // Message si aucun programme n'est disponible
                                child: Text(
                                  'Aucun programme disponible. Ajoutez-en un nouveau.',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              )
                            : ListView.builder(
                                itemCount:
                                    _programs.length, // Nombre de programmes
                                itemBuilder: (context, index) {
                                  final program =
                                      _programs[index]; // Programme actuel
                                  return Dismissible(
                                    key:
                                        UniqueKey(), // Clé unique pour l'élément
                                    direction: DismissDirection
                                        .startToEnd, // Direction du swipe
                                    onDismissed: (direction) {
                                      _deleteProgram(
                                          index); // Suppression du programme
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
                                      color: Colors
                                          .red, // Couleur de fond lors du swipe
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _showProgramDetail(
                                          program), // Affiche les détails du programme
                                      child: _buildProgramItem(
                                        program['name'],
                                        program['icon'],
                                        program['day'] ?? '',
                                        program['isFavorite'],
                                        () => _toggleFavorite(
                                            index), // Bascule le statut favori
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
