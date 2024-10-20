// streaks_widget.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  Duration _timeUntilNextStreak = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStreakData();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

    // Vérifier si la dernière vérification de streak était avant la semaine en cours
    if (!_isSameWeek(_lastStreakDate, today)) {
      // Vérifier si l'utilisateur a complété toutes les séances de la semaine précédente
      DateTime lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
      DateTime lastWeekEnd = endOfWeek.subtract(const Duration(days: 7));

      bool allSessionsCompleted =
          _checkAllSessionsCompleted(lastWeekStart, lastWeekEnd);

      if (allSessionsCompleted) {
        // Incrémenter le streak
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
      } else {
        // Réinitialiser le streak
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

      // Réinitialiser les statuts des programmes
      await _resetProgramStatuses();
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

  Future<void> _resetProgramStatuses() async {
    try {
      QuerySnapshot programsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('programs')
          .get();

      for (var doc in programsSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('programs')
            .doc(doc.id)
            .update({'isDone': false});
      }

      // Optionnel : Réinitialiser la liste des sessions complétées
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'completedSessions': []});
    } catch (e) {
      // Gérer les erreurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors de la réinitialisation des programmes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startCountdownTimer() {
    _updateCountdown();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    DateTime now = DateTime.now();
    DateTime nextWeekStart = _startOfWeek(now).add(const Duration(days: 7));
    Duration difference = nextWeekStart.difference(now);

    setState(() {
      _timeUntilNextStreak = difference;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
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
                '$_streakCount semaines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Temps avant la prochaine streak: ${_formatDuration(_timeUntilNextStreak)}',
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
