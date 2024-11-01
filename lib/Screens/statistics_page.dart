// Importation des packages nécessaires
import 'package:flutter/material.dart'; // Bibliothèque principale de widgets Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec Firestore, la base de données cloud de Firebase
import 'package:syncfusion_flutter_charts/charts.dart'; // Pour créer des graphiques interactifs
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Pour la gestion de l'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour le thème (clair/sombre)

// Définition de la classe StatisticsPage, un ConsumerStatefulWidget pour utiliser Riverpod
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

// État associé à la classe StatisticsPage
class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  // Instances Firebase pour l'authentification et Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Utilisateur actuellement connecté
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables pour stocker les statistiques générales
  int totalSessions = 0; // Nombre total de sessions terminées
  double totalWeight = 0.0; // Poids total soulevé
  Map<String, int> sessionsPerCategory =
      {}; // Nombre de sessions par catégorie (non utilisé dans ce code)
  Map<String, double> weightPerDay = {}; // Poids soulevé par jour de la semaine

  // Variables pour les statistiques hebdomadaires
  int weeklySessions = 0; // Nombre de sessions cette semaine
  double weeklyWeight = 0.0; // Poids soulevé cette semaine
  Duration weeklyTimeSpent =
      const Duration(); // Temps passé en séance cette semaine

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Récupère l'utilisateur actuellement connecté
  }

  // Méthode pour obtenir le nom du jour de la semaine en français
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

  // Méthode pour créer les séries de données pour le graphique
  List<ChartSeries<DayWeight, String>> _createWeightSeries() {
    // Transforme le Map weightPerDay en une liste d'objets DayWeight
    final data = weightPerDay.entries
        .map((entry) => DayWeight(entry.key, entry.value))
        .toList();

    return [
      // Crée une série de colonnes pour le graphique
      ColumnSeries<DayWeight, String>(
        dataSource: data, // Source des données
        xValueMapper: (DayWeight dw, _) =>
            dw.day, // Mappe le nom du jour sur l'axe X
        yValueMapper: (DayWeight dw, _) =>
            dw.weight, // Mappe le poids sur l'axe Y
        color: Colors.blue, // Couleur des barres du graphique
      )
    ];
  }

  // Méthode asynchrone pour mettre à jour les statistiques
  Future<void> _updateStatistics(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (_user == null)
      return; // Si l'utilisateur n'est pas connecté, on quitte la méthode

    // Réinitialise les statistiques
    totalSessions = 0;
    totalWeight = 0.0;
    weeklySessions = 0;
    weeklyWeight = 0.0;
    weeklyTimeSpent = const Duration();
    weightPerDay = {
      'Lundi': 0.0,
      'Mardi': 0.0,
      'Mercredi': 0.0,
      'Jeudi': 0.0,
      'Vendredi': 0.0,
      'Samedi': 0.0,
      'Dimanche': 0.0,
    };

    // Calcule les dates de début et de fin de la semaine en cours
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
    Timestamp endTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 7));

    // Parcourt chaque document (session terminée) du snapshot
    for (var doc in snapshot.docs) {
      totalSessions += 1; // Incrémente le nombre total de sessions

      // Récupère le poids total soulevé pour cette session
      double weight = doc.data()['totalWeight']?.toDouble() ?? 0.0;
      totalWeight += weight; // Ajoute au poids total

      // Récupère la date de la session
      Timestamp sessionDate = doc.data()['date'];
      // Vérifie si la session est dans la semaine en cours
      if (sessionDate.compareTo(startTimestamp) >= 0 &&
          sessionDate.compareTo(endTimestamp) < 0) {
        weeklySessions += 1; // Incrémente le nombre de sessions cette semaine
        weeklyWeight += weight; // Ajoute au poids soulevé cette semaine

        // Récupère la durée de la session et la convertit en Duration
        String duration = doc.data()['duration'] ?? "0:0:0";
        List<String> parts = duration.split(':');
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);

        weeklyTimeSpent += Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds); // Ajoute au temps passé cette semaine

        // Récupère le nom du jour de la semaine en français
        DateTime date = sessionDate.toDate();
        String day = _getFrenchDayName(date.weekday);
        // Ajoute le poids soulevé ce jour-là
        weightPerDay[day] = (weightPerDay[day] ?? 0.0) + weight;
      }
    }

    setState(() {}); // Met à jour l'interface utilisateur
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

    return Stack(
      children: [
        // Fond dégradé
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color.fromRGBO(255, 204, 0, 1.0),
                      Colors.black
                    ] // Couleurs pour le thème sombre
                  : [
                      const Color.fromRGBO(255, 204, 0, 1.0),
                      const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
                    ], // Couleurs pour le thème clair
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors
              .transparent, // Rend le fond du Scaffold transparent pour voir le dégradé
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('users')
                .doc(_user!.uid)
                .collection('completedSessions')
                .snapshots(), // Flux en temps réel des sessions terminées de l'utilisateur
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // En cas d'erreur, affiche un message
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                // Affiche un indicateur de chargement pendant la récupération des données
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                // Si des données sont disponibles, met à jour les statistiques
                _updateStatistics(snapshot.data!);
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  // Permet de faire défiler le contenu si nécessaire
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre des statistiques générales
                      Text(
                        'Statistiques Générales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16), // Espacement
                      // Affiche le nombre total de séances
                      _buildGeneralStatCard(
                        title: 'Nombre total de séances',
                        value: '$totalSessions',
                        icon: Icons.event_note,
                        color: Colors.green,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      // Affiche le poids total soulevé
                      _buildGeneralStatCard(
                        title: 'Poids total soulevé',
                        value: '${totalWeight.toStringAsFixed(1)} kg',
                        icon: Icons.fitness_center,
                        color: Colors.orange,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 32),
                      // Titre des statistiques hebdomadaires
                      Text(
                        'Statistiques de la Semaine',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Affiche le nombre de séances réalisées cette semaine
                      _buildWeeklyStatCard(
                        title: 'Nombre de séances réalisées cette semaine',
                        value: '$weeklySessions',
                        icon: Icons.check_circle,
                        color: Colors.purple,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      // Affiche le poids soulevé cette semaine
                      _buildWeeklyStatCard(
                        title: 'Poids soulevé cette semaine',
                        value: '${weeklyWeight.toStringAsFixed(1)} kg',
                        icon: Icons.fitness_center,
                        color: Colors.orange,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      // Affiche le temps passé en séance cette semaine
                      _buildWeeklyStatCard(
                        title: 'Temps passé en séance cette semaine',
                        value:
                            '${weeklyTimeSpent.inHours}:${weeklyTimeSpent.inMinutes.remainder(60)}:${weeklyTimeSpent.inSeconds.remainder(60)}',
                        icon: Icons.access_time,
                        color: Colors.blue,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      // Affiche le graphique du poids soulevé par jour
                      _buildWeeklyChartCard(isDarkMode),
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

  // Widget pour afficher une carte de statistique générale
  Widget _buildGeneralStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Espacement interne
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black54
            : Colors.white.withOpacity(0.8), // Couleur de fond selon le thème
        borderRadius: BorderRadius.circular(16.0), // Coins arrondis
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isDarkMode ? 0.5 : 0.05), // Ombre portée
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône dans un cercle
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.yellow[700],
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          // Texte du titre et de la valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la statistique
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Valeur de la statistique
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une carte de statistique hebdomadaire (identique à _buildGeneralStatCard)
  Widget _buildWeeklyStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return _buildGeneralStatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      isDarkMode: isDarkMode,
    );
  }

  // Widget pour afficher le graphique du poids soulevé par jour
  Widget _buildWeeklyChartCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Espacement interne
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black54
            : Colors.white.withOpacity(0.8), // Couleur de fond selon le thème
        borderRadius: BorderRadius.circular(16.0), // Coins arrondis
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(isDarkMode ? 0.5 : 0.05), // Ombre portée
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du graphique
          Text(
            'Poids soulevé par jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Affiche le graphique
          SizedBox(
            height: 200, // Hauteur du graphique
            child: SfCartesianChart(
              backgroundColor: isDarkMode
                  ? Colors.black54
                  : Colors.white, // Couleur de fond du graphique
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Couleur des labels de l'axe X
                ),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Couleur des labels de l'axe Y
                ),
              ),
              series: _createWeightSeries(), // Données du graphique
            ),
          ),
        ],
      ),
    );
  }
}

// Classe pour représenter le poids soulevé chaque jour
class DayWeight {
  final String day; // Nom du jour
  final double weight; // Poids soulevé ce jour-là

  DayWeight(this.day, this.weight); // Constructeur
}
