// streaks_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:yellowmuscu/Provider/theme_provider.dart';

String getTimeAgo(DateTime lastSessionDate) {
  final now = DateTime.now();
  final difference = now.difference(lastSessionDate);

  if (difference.inDays >= 1) {
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
  } else {
    return 'just now';
  }
}

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
        color: isDarkMode ? darkWidget : lightWidget,
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
                  const Text(
                    'Streaks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                '$_streakCount Sessions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last: ${getTimeAgo(_lastStreakDate)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
