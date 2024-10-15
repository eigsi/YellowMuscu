// SessionPage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellowmuscu/Session_page/ExerciseSessionPage.dart'; // Assurez-vous que le chemin est correct

class SessionPage extends StatefulWidget {
  const SessionPage({Key? key}) : super(key: key);

  @override
  _SessionPageState createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  void _toggleIsDone(int index, bool? value) async {
    if (_user != null) {
      final program = _programs[index];
      program['isDone'] = value ?? false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('programs')
          .doc(program['id'])
          .update({'isDone': program['isDone']});

      setState(() {
        _programs[index] = program;
      });
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
              setState(() {});
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(255, 204, 0, 1.0),
              const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _user == null
            ? Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signIn');
                  },
                  child: const Text('Se connecter'),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user!.uid)
                    .collection('programs')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  _programs = snapshot.data!.docs.map((doc) {
                    Map<String, dynamic>? data =
                        doc.data() as Map<String, dynamic>?;

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

                  return ListView.builder(
                    itemCount: _programs.length,
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return GestureDetector(
                        onTap: () {
                          _startSession(program);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: ListTile(
                            title:
                                Text(program['name'] ?? 'Programme sans nom'),
                            trailing: Checkbox(
                              value: program['isDone'] ?? false,
                              onChanged: (value) {
                                _toggleIsDone(index, value);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}