import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Statistiques générales
  int totalSessions = 0;
  double totalWeight = 0.0;
  Map<String, int> sessionsPerCategory = {};
  Map<String, double> weightPerDay = {};

  // Statistiques de la semaine
  int weeklySessions = 0;
  double weeklyWeight = 0.0;
  Duration weeklyTimeSpent = Duration();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
  }

  String _getFrenchDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Unknown';
    }
  }

  List<ChartSeries<DayWeight, String>> _createWeightSeries() {
    final data = weightPerDay.entries
        .map((entry) => DayWeight(entry.key, entry.value))
        .toList();

    return [
      ColumnSeries<DayWeight, String>(
        dataSource: data,
        xValueMapper: (DayWeight dw, _) => dw.day,
        yValueMapper: (DayWeight dw, _) => dw.weight,
        color: Colors.blue,
      )
    ];
  }

  Future<void> _updateStatistics(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (_user == null) return;

    totalSessions = 0;
    totalWeight = 0.0;
    weeklySessions = 0;
    weeklyWeight = 0.0;
    weeklyTimeSpent = Duration();
    weightPerDay = {
      'Lundi': 0.0,
      'Mardi': 0.0,
      'Mercredi': 0.0,
      'Jeudi': 0.0,
      'Vendredi': 0.0,
      'Samedi': 0.0,
      'Dimanche': 0.0,
    };

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
    Timestamp endTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 7));

    for (var doc in snapshot.docs) {
      totalSessions += 1;

      double weight = doc.data()['totalWeight']?.toDouble() ?? 0.0;
      totalWeight += weight;

      Timestamp sessionDate = doc.data()['date'];
      if (sessionDate.compareTo(startTimestamp) >= 0 &&
          sessionDate.compareTo(endTimestamp) < 0) {
        weeklySessions += 1;
        weeklyWeight += weight;

        // Récupération et ajout de la durée de la séance
        String duration = doc.data()['duration'] ?? "0:0:0";
        List<String> parts = duration.split(':');
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);

        weeklyTimeSpent +=
            Duration(hours: hours, minutes: minutes, seconds: seconds);

        DateTime date = sessionDate.toDate();
        String day = _getFrenchDayName(date.weekday);
        weightPerDay[day] = (weightPerDay[day] ?? 0.0) + weight;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromRGBO(255, 204, 0, 1.0),
                const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('users')
                .doc(_user!.uid)
                .collection('completedSessions')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                _updateStatistics(snapshot.data!);
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistiques Générales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGeneralStatCard(
                        title: 'Nombre total de séances',
                        value: '$totalSessions',
                        icon: Icons.event_note,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildGeneralStatCard(
                        title: 'Poids total soulevé',
                        value: '${totalWeight.toStringAsFixed(1)} kg',
                        icon: Icons.fitness_center,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Statistiques de la Semaine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyStatCard(
                        title: 'Nombre de séances réalisées cette semaine',
                        value: '$weeklySessions',
                        icon: Icons.check_circle,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyStatCard(
                        title: 'Poids soulevé cette semaine',
                        value: '${weeklyWeight.toStringAsFixed(1)} kg',
                        icon: Icons.fitness_center,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyStatCard(
                        title: 'Temps passé en séance cette semaine',
                        value:
                            '${weeklyTimeSpent.inHours}:${weeklyTimeSpent.inMinutes.remainder(60)}:${weeklyTimeSpent.inSeconds.remainder(60)}',
                        icon: Icons.access_time,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildWeeklyChartCard(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow[700],
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow[700],
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Poids soulevé par jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: _createWeightSeries(),
            ),
          ),
        ],
      ),
    );
  }
}

class DayWeight {
  final String day;
  final double weight;

  DayWeight(this.day, this.weight);
}
