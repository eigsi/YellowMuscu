// streaks_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class StreaksWidget extends StatefulWidget {
  final String userId;

  const StreaksWidget({super.key, required this.userId});

  @override
  StreaksWidgetState createState() => StreaksWidgetState();
}

class StreaksWidgetState extends State<StreaksWidget> {
  int _streakCount = 0;
  DateTime _lastStreakDate = DateTime(1970);
  List<DateTime> _completedSessions = [];
  Timer? _timer;
  late StreamSubscription<DocumentSnapshot> _userSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningToUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _userSubscription.cancel();
    super.dispose();
  }

  void _startListeningToUserData() {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        List<dynamic> sessions = data['completedSessions'] ?? [];
        List<DateTime> newCompletedSessions =
            sessions.map((session) => (session as Timestamp).toDate()).toList();

        // Vérifier si une nouvelle séance a été ajoutée
        if (newCompletedSessions.length > _completedSessions.length) {
          // Une nouvelle séance a été complétée
          DateTime lastSessionDate = newCompletedSessions.last;

          // Optionnel : Vérifier si la dernière séance est après la dernière date enregistrée
          if (lastSessionDate.isAfter(_lastStreakDate)) {
            setState(() {
              _streakCount += 1;
              _lastStreakDate = lastSessionDate;
              _completedSessions = newCompletedSessions;
            });

            // Mettre à jour Firestore
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .update({
              'streakCount': _streakCount,
              'lastStreakDate': Timestamp.fromDate(_lastStreakDate),
            });
          }
        } else {
          // Pas de nouvelle séance, mettre à jour les données locales
          setState(() {
            _streakCount = data['streakCount'] ?? 0;
            _lastStreakDate = data['lastStreakDate'] != null
                ? (data['lastStreakDate'] as Timestamp).toDate()
                : DateTime(1970);
            _completedSessions = newCompletedSessions;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Déterminer si le thème actuel est sombre
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: isDarkMode ? Colors.redAccent : Colors.red,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Streaks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                '$_streakCount séances',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Optionnel : Afficher la date de la dernière séance
          Text(
            'Dernière séance: ${DateFormat('dd/MM/yyyy').format(_lastStreakDate)}',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[300] : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
