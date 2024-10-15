import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StreaksWidget extends StatefulWidget {
  final String userId;

  const StreaksWidget({Key? key, required this.userId}) : super(key: key);

  @override
  _StreaksWidgetState createState() => _StreaksWidgetState();
}

class _StreaksWidgetState extends State<StreaksWidget> {
  int _streakCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStreakCount();
  }

  void _fetchStreakCount() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (snapshot.exists) {
      setState(() {
        _streakCount = snapshot['streakCount'] ?? 0;
      });
    }
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
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.red,
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
