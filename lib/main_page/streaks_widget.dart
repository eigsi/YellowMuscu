// streaks_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StreaksWidget extends StatefulWidget {
  final String userId;

  const StreaksWidget({super.key, required this.userId});

  @override
  _StreaksWidgetState createState() => _StreaksWidgetState();
}

class _StreaksWidgetState extends State<StreaksWidget> {
  int _streakCount = 0;
  DateTime _lastStreakDate = DateTime(1970);
  List<DateTime> _completedSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchStreakData();
  }

  void _fetchStreakData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        _streakCount = data['streakCount'] ?? 0;
        _lastStreakDate = data['lastStreakDate'] != null
            ? (data['lastStreakDate'] as Timestamp).toDate()
            : DateTime(1970);

        // Récupérer les sessions complétées
        List<dynamic> sessions = data['completedSessions'] ?? [];
        _completedSessions =
            sessions.map((session) => (session as Timestamp).toDate()).toList();
      });

      _updateStreak();
    }
  }

  void _updateStreak() async {
    DateTime today = DateTime.now();
    DateTime startOfWeek = _startOfWeek(today);
    DateTime endOfWeek = _endOfWeek(today);

    // Vérifier si l'utilisateur a complété toutes les séances de la semaine
    bool allSessionsCompleted =
        _checkAllSessionsCompleted(startOfWeek, endOfWeek);

    if (allSessionsCompleted) {
      // Vérifier si le streak doit être incrémenté
      if (!_isSameWeek(_lastStreakDate, today)) {
        setState(() {
          _streakCount += 1;
          _lastStreakDate = today;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'streakCount': _streakCount,
          'lastStreakDate': Timestamp.fromDate(today),
        });
      }
    } else {
      // Réinitialiser le streak si une séance est manquée
      if (_streakCount > 0) {
        setState(() {
          _streakCount = 0;
          _lastStreakDate = today;
        });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({
          'streakCount': _streakCount,
          'lastStreakDate': Timestamp.fromDate(today),
        });
      }
    }
  }

  bool _checkAllSessionsCompleted(DateTime startOfWeek, DateTime endOfWeek) {
    // Supposons que chaque semaine, l'utilisateur doit avoir 7 séances (une par jour)
    // Ajustez cette logique en fonction de votre application

    // Créer une liste de dates pour la semaine
    List<DateTime> weekDates = [];
    DateTime current = startOfWeek;
    while (current.isBefore(endOfWeek) || current.isAtSameMomentAs(endOfWeek)) {
      weekDates.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Vérifier que chaque jour a une séance complétée
    for (DateTime date in weekDates) {
      bool completed = _completedSessions.any((sessionDate) =>
          sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day);
      if (!completed) {
        return false;
      }
    }

    return true;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1 = _weekNumber(date1);
    final week2 = _weekNumber(date2);
    final year1 = date1.year;
    final year2 = date2.year;
    return week1 == week2 && year1 == year2;
  }

  int _weekNumber(DateTime date) {
    return int.parse(DateFormat('w').format(date));
  }

  DateTime _startOfWeek(DateTime date) {
    // Semaine commence le lundi
    int subtractDays = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: subtractDays));
  }

  DateTime _endOfWeek(DateTime date) {
    // Semaine se termine le dimanche
    int addDays = DateTime.sunday - date.weekday;
    return DateTime(date.year, date.month, date.day)
        .add(Duration(days: addDays));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.red,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
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
            '$_streakCount jours',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
