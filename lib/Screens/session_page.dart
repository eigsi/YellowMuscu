import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/Session_page/ExerciseSessionPage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellowmuscu/Provider/theme_provider.dart';

class SessionPage extends ConsumerStatefulWidget {
  const SessionPage({super.key});

  @override
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> _programs = [];

  DateTime? sessionStartTime;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchPrograms();
  }

  void _markProgramAsDone(String programId, DateTime sessionEndTime) async {
    if (_user == null) return;

    try {
      DocumentSnapshot programSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(programId)
          .get();

      if (!programSnapshot.exists) {
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
      double totalWeight = 0.0;
      for (var exercise in exercises) {
        double weight = double.tryParse(exercise['weight'].toString()) ?? 0.0;
        int reps = int.tryParse(exercise['reps'].toString()) ?? 0;
        int sets = int.tryParse(exercise['sets'].toString()) ?? 0;

        totalWeight += weight * reps * sets;
      }

      Duration sessionDuration = sessionEndTime.difference(sessionStartTime!);
      String durationFormatted =
          "${sessionDuration.inHours}:${sessionDuration.inMinutes.remainder(60)}:${sessionDuration.inSeconds.remainder(60)}";

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Session terminée! Durée: $durationFormatted, Poids total soulevé: ${totalWeight.toStringAsFixed(2)} kg'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startSession(Map<String, dynamic> program) {
    if (program['exercises'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ce programme ne contient aucun exercice. Allez dans la page programme pour en ajouter !'),
        ),
      );
    } else {
      sessionStartTime = DateTime.now();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseSessionPage(
            program: program,
            userId: _user!.uid,
            onSessionComplete: () {
              DateTime sessionEndTime = DateTime.now();
              _markProgramAsDone(program['id'], sessionEndTime);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color.fromRGBO(255, 204, 0, 1.0), Colors.black]
                : [
                    const Color.fromRGBO(255, 204, 0, 1.0),
                    const Color.fromRGBO(255, 204, 0, 0.3),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
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
                  color: isDarkMode ? Colors.black54 : Colors.white,
                ),
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  title: Text(
                    program['name'] ?? 'Programme sans nom',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  trailing: Checkbox(
                    value: program['isDone'] ?? false,
                    onChanged: null,
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
