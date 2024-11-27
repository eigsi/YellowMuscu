import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCompletedSessions();
  }

  /// Méthode pour récupérer les données de la sous-collection `completedSessions`
  Future<void> _fetchCompletedSessions() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('completedSessions')
          .orderBy('date', descending: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final sessions = querySnapshot.docs;

        setState(() {
          _streakCount = sessions.length;
          _lastStreakDate = (sessions.first['date'] as Timestamp).toDate();
        });
      } else {
        setState(() {
          _streakCount = 0;
          _lastStreakDate = DateTime(1970);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching streaks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last: ${_lastStreakDate.year > 1970 ? getTimeAgo(_lastStreakDate) : "No sessions yet"}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
