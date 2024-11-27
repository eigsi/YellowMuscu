// session_page.dart

import 'package:flutter/material.dart'; // Bibliothèque principale de widgets Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore de Firebase
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:yellowmuscu/Session_page/exercise_session_page.dart'; // Page pour la session d'exercice
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Pour la gestion de l'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour le thème (clair/sombre)

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  SessionPageState createState() => SessionPageState();
}

class SessionPageState extends ConsumerState<SessionPage> {
  // Instance de FirebaseAuth pour l'authentification
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable pour stocker l'utilisateur actuellement connecté
  List<Map<String, dynamic>> _programs =
      []; // Liste des programmes de l'utilisateur

  DateTime? sessionStartTime; // Heure de début de la session
  bool _isLoading = true; // Indicateur de chargement

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Récupère l'utilisateur actuellement connecté
    _fetchPrograms(); // Récupère les programmes de l'utilisateur
  }

  // Méthode pour marquer un programme comme terminé
  void _markProgramAsDone(String programId, DateTime sessionEndTime) async {
    if (_user == null) {
      return; // Si l'utilisateur n'est pas connecté, ne rien faire
    }

    try {
      // Récupère le programme depuis Firestore
      DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .get();

      if (!programSnapshot.exists) {
        if (!mounted) return;
        // Si le programme n'existe pas, affiche un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programme non trouvé.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Récupère les données du programme
      Map<String, dynamic> programData =
          programSnapshot.data() as Map<String, dynamic>;

      // Calcule le poids total soulevé pendant la session
      List<dynamic> exercises = programData['exercises'] ?? [];
      double totalWeight = 0.0;
      for (var exercise in exercises) {
        // Récupère le poids, le nombre de répétitions et de séries
        double weight = double.tryParse(exercise['weight'].toString()) ?? 0.0;
        int reps = int.tryParse(exercise['reps'].toString()) ?? 0;
        int sets = int.tryParse(exercise['sets'].toString()) ?? 0;

        totalWeight += weight * reps * sets; // Calcule le poids total
      }

      // Calcule la durée de la session
      Duration sessionDuration = sessionEndTime.difference(sessionStartTime!);
      // Formate la durée en heures, minutes et secondes
      String durationFormatted =
          "${sessionDuration.inHours}:${sessionDuration.inMinutes.remainder(60)}:${sessionDuration.inSeconds.remainder(60)}";

      // Enregistre la session terminée dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('completedSessions')
          .add({
        'programName': programData['name'] ?? 'Programme sans nom',
        'date': sessionEndTime,
        'duration': durationFormatted,
        'totalWeight': totalWeight,
        'userId': _user!.uid,
      });

      if (!mounted) return;

      // Affiche un message de succès avec les détails de la session
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Session terminée! Durée: $durationFormatted, Poids total soulevé: ${totalWeight.toStringAsFixed(2)} kg'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // En cas d'erreur, affiche un message d'erreur plus détaillé
      String errorMessage =
          'Une erreur est survenue lors de la sauvegarde de la session terminée. Veuillez réessayer.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour démarrer une session d'entraînement
  void _startSession(Map<String, dynamic> program) {
    if (program['exercises'].isEmpty) {
      // Si le programme ne contient aucun exercice, affiche un message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ce programme ne contient aucun exercice. Allez dans la page programme pour en ajouter !'),
        ),
      );
    } else {
      // Affiche une boîte de dialogue de confirmation
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final isDarkMode = ref.watch(themeProvider);
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
            title: Text(
              'Commencer la session?',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            content: Text(
              'Voulez-vous vraiment commencer la session "${program['name']}"?',
              style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialogue
                },
              ),
              TextButton(
                child: const Text(
                  'Commencer',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialogue
                  sessionStartTime =
                      DateTime.now(); // Enregistre l'heure de début
                  // Navigue vers la page ExerciseSessionPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseSessionPage(
                        program: program,
                        userId: _user!.uid,
                        onSessionComplete: () {
                          // Callback lorsque la session est terminée
                          DateTime sessionEndTime = DateTime.now();
                          _markProgramAsDone(program['id'], sessionEndTime);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Méthode pour récupérer les programmes de l'utilisateur depuis Firestore
  void _fetchPrograms() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true; // Démarre le chargement
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .get();

      if (!mounted) return;

      setState(() {
        // Met à jour la liste des programmes avec les données récupérées
        _programs = snapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            // Si les données sont nulles, retourne un programme par défaut
            return {
              'id': doc.id,
              'name': 'Programme sans nom',
              'isFavorite': false,
              'isDone': false,
              'exercises': [],
            };
          }

          // Récupère la liste des exercices du programme
          List<dynamic> exercisesData = data['exercises'] ?? [];
          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is Map<String, dynamic>) {
                  // Convertit l'exercice en Map<String, dynamic>
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return {};
                }
              })
              .cast<Map<String, dynamic>>()
              .toList();

          // Retourne le programme avec ses détails
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Programme sans nom',
            'isFavorite': data['isFavorite'] ?? false,
            'isDone': data['isDone'] ?? false,
            'exercises': exercises,
          };
        }).toList();
        _isLoading = false; // Termine le chargement
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Termine le chargement en cas d'erreur
      });
      // En cas d'erreur, affiche un message d'erreur plus détaillé
      String errorMessage =
          'Une erreur est survenue lors de la récupération des programmes. Veuillez réessayer.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

    return Scaffold(
      body: Container(
        // Applique un dégradé de fond
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [darkTop, darkBottom]
                : [
                    lightTop,
                    lightBottom,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                // Indicateur de chargement
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? Colors.white : Colors.black),
                ),
              )
            : _programs.isEmpty
                ? const Center(
                    // Message si aucun programme
                    child: Text(
                      'Aucun programme disponible.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _programs.length, // Nombre de programmes
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return GestureDetector(
                        onTap: () {
                          _startSession(program);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(16.0), // Coins arrondis
                            color: isDarkMode ? darkWidget : lightWidget,
                          ),
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(
                              program['name'] ?? 'Programme sans nom',
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            trailing: Checkbox(
                              value: program['isDone'] ?? false,
                              onChanged: null,
                              checkColor: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
