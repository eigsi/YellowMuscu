import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/Session_page/ExerciseSessionPage.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> _programs = [];
// Par défaut, la page session est sélectionnée
// Initialisation des options de pages

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchPrograms();
  }

  // Fonction pour marquer un programme comme complété
  void _markProgramAsDone(String programId) async {
    if (_user == null) return;

    try {
      // Récupérer le programme pour calculer le poids total
      DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .get();

      if (!programSnapshot.exists) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Programme non trouvé.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> programData =
          programSnapshot.data() as Map<String, dynamic>;

      List<dynamic> exercises = programData['exercises'] ?? [];

      // Calculer le poids total soulevé en une seule séance
      double totalWeight = 0.0;
      for (var exercise in exercises) {
        double weight = 0.0;
        int reps = 0;
        int sets = 0;

        if (exercise['weight'] != null) {
          weight = double.tryParse(exercise['weight'].toString()) ?? 0.0;
        }

        if (exercise['reps'] != null) {
          reps = int.tryParse(exercise['reps'].toString()) ?? 0;
        }

        if (exercise['sets'] != null) {
          sets = int.tryParse(exercise['sets'].toString()) ?? 0;
        }

        totalWeight += weight * reps * sets;
      }

      // Mettre à jour le programme comme complété
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .update({'isDone': true});

      // Ajouter la date de complétion à 'completedSessions'
      DateTime today = DateTime.now();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'completedSessions': FieldValue.arrayUnion([Timestamp.fromDate(today)])
      });

      // Créer un événement avec le poids total
      Map<String, dynamic> currentUserData = await _getCurrentUserData();
      String userName =
          '${currentUserData['first_name']} ${currentUserData['last_name']}'
              .trim();

      String eventDescription =
          '$userName a soulevé ${totalWeight.toStringAsFixed(2)} kg pendant la séance d\'aujourd\'hui.';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('events')
          .add({
        'description': eventDescription,
        'timestamp': FieldValue.serverTimestamp(),
        'activityType': 'poids soulevé',
      });

      // Rafraîchir les données
      _fetchPrograms();

      // Afficher un message de succès
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Session terminée! Poids total soulevé: ${totalWeight.toStringAsFixed(2)} kg'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Gérer les erreurs
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    if (_user == null) {
      return {'first_name': '', 'last_name': '', 'profilePicture': ''};
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {'first_name': '', 'last_name': '', 'profilePicture': ''};
    }
  }

  void _startSession(Map<String, dynamic> program) {
    if (program['exercises'].isEmpty) {
      // Afficher un message si le programme est vide
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ce programme ne contient aucun exercice. Allez dans la page programme pour en ajouter !'),
        ),
      );
    } else {
      // Démarrer la session si des exercices sont disponibles
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseSessionPage(
            program: program,
            userId: _user!.uid,
            onSessionComplete: () {
              // Marquer le programme comme complété après la session
              _markProgramAsDone(program['id']);
            },
          ),
        ),
      );
    }
  }

  void _fetchPrograms() async {
    if (_user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .get();

      setState(() {
        _programs = snapshot.docs.map((doc) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

          if (data == null) {
            return {
              'id': doc.id,
              'name': 'Programme sans nom',
              'isFavorite': false,
              'isDone': false,
              'exercises': [],
            };
          }

          // Gestion des exercices
          List<dynamic> exercisesData = data['exercises'] ?? [];
          List<Map<String, dynamic>> exercises = exercisesData
              .map((exercise) {
                if (exercise is Map<String, dynamic>) {
                  return Map<String, dynamic>.from(exercise);
                } else {
                  return {};
                }
              })
              .cast<Map<String, dynamic>>()
              .toList();

          return {
            'id': doc.id,
            'name': data['name'] ?? 'Programme sans nom',
            'isFavorite': data['isFavorite'] ?? false,
            'isDone': data['isDone'] ?? false,
            'exercises': exercises,
          };
        }).toList();
      });
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _programs.length,
        itemBuilder: (context, index) {
          final program = _programs[index];
          return GestureDetector(
            onTap: () {
              _startSession(program);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                color: Colors.white,
              ),
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(16),
              child: ListTile(
                title: Text(program['name'] ?? 'Programme sans nom'),
                trailing: Checkbox(
                  value: program['isDone'] ?? false,
                  onChanged: null, // Rendre le Checkbox non cliquable
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
