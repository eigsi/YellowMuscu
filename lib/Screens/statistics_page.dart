// lib/statistics_page.dart

import 'package:flutter/cupertino.dart'; // To use Cupertino widgets
import 'package:flutter/material.dart'; // Main Flutter widget library
import 'package:cloud_firestore/cloud_firestore.dart'; // Interact with Firestore
import 'package:syncfusion_flutter_charts/charts.dart'; // Create interactive charts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider for theme (light/dark)
import 'package:yellowmuscu/Provider/statistics_provider.dart'; // Import the new statistics provider
import 'package:reorderables/reorderables.dart'; // For drag and drop functionality

// Définition de la classe StatisticSection
class StatisticSection {
  final String id; // Unique identifier
  final Widget widget; // The widget to display

  StatisticSection({required this.id, required this.widget});
}

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
  int totalSessions = 0; // Nombre total de sessions complétées
  double totalWeight = 0.0; // Poids total soulevé
  Map<String, double> weightPerDay = {}; // Poids soulevé par jour de la semaine

  // Variables pour les statistiques hebdomadaires
  int weeklySessions = 0; // Nombre de sessions cette semaine
  double weeklyWeight = 0.0; // Poids soulevé cette semaine
  Duration weeklyTimeSpent =
      const Duration(); // Temps passé en sessions cette semaine

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Obtenir l'utilisateur actuellement connecté
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aucune action nécessaire ici puisque les sections sont gérées de manière réactive
  }

  // Méthode pour obtenir le nom abrégé du jour de la semaine en anglais
  String _getEnglishDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Unknown';
    }
  }

  // Méthode pour créer les séries de données pour le graphique
  List<ChartSeries<DayWeight, String>> _createWeightSeries() {
    // Transformer la Map weightPerDay en une liste d'objets DayWeight
    final data = weightPerDay.entries
        .map((entry) => DayWeight(entry.key, entry.value))
        .toList();

    return [
      // Créer une série de colonnes pour le graphique
      ColumnSeries<DayWeight, String>(
        dataSource: data, // Source de données
        xValueMapper: (DayWeight dw, _) =>
            dw.day, // Mapper le nom du jour sur l'axe X
        yValueMapper: (DayWeight dw, _) =>
            dw.weight, // Mapper le poids sur l'axe Y
        color: Colors.blue, // Couleur des barres du graphique
      )
    ];
  }

  // Méthode asynchrone pour mettre à jour les statistiques
  Future<void> _updateStatistics(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (_user == null)
      return; // Si l'utilisateur n'est pas connecté, quitter la méthode

    // Réinitialiser les statistiques
    totalSessions = 0;
    totalWeight = 0.0;
    weeklySessions = 0;
    weeklyWeight = 0.0;
    weeklyTimeSpent = const Duration();
    weightPerDay = {
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    // Calculer les dates de début et de fin de la semaine en cours
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
    Timestamp endTimestamp = Timestamp.fromDate(
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day));

    // Itérer sur chaque document (session complétée) dans le snapshot
    for (var doc in snapshot.docs) {
      totalSessions += 1; // Incrémenter le nombre total de sessions

      // Obtenir le poids total soulevé pour cette session
      double weight = doc.data()['totalWeight']?.toDouble() ?? 0.0;
      totalWeight += weight; // Ajouter au poids total

      // Obtenir la date de la session
      Timestamp sessionDate = doc.data()['date'];
      // Vérifier si la session est dans la semaine en cours
      if (sessionDate.compareTo(startTimestamp) >= 0 &&
          sessionDate.compareTo(endTimestamp) < 0) {
        weeklySessions += 1; // Incrémenter le nombre de sessions cette semaine
        weeklyWeight += weight; // Ajouter au poids soulevé cette semaine

        // Obtenir la durée de la session et la convertir en Duration
        String duration = doc.data()['duration'] ?? "0:0:0";
        List<String> parts = duration.split(':');
        if (parts.length == 3) {
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          int seconds = int.parse(parts[2]);

          weeklyTimeSpent += Duration(
              hours: hours,
              minutes: minutes,
              seconds: seconds); // Ajouter au temps passé cette semaine
        }

        // Obtenir le nom anglais abrégé du jour de la semaine
        DateTime date = sessionDate.toDate();
        String day = _getEnglishDayName(date.weekday);
        // Ajouter le poids soulevé ce jour-là
        weightPerDay[day] = (weightPerDay[day] ?? 0.0) + weight;
      }
    }

    // Appeler setState pour reconstruire l'interface utilisateur avec les nouvelles données
    setState(() {});
  }

  // Méthode pour afficher le modal de personnalisation
  void _showCustomizationModal(StatisticsSettings settings) {
    final isDarkMode = ref.watch(themeProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              color: isDarkMode ? Colors.black54 : Colors.white,
              height: MediaQuery.of(context).size.height * 0.5,
              child: SafeArea(
                child: Column(
                  children: [
                    // Titre du modal
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Customize Statistics',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoScrollbar(
                        child: ListView(
                          children: [
                            // Utiliser CupertinoListSection et CupertinoListTile
                            CupertinoListSection.insetGrouped(
                              backgroundColor:
                                  isDarkMode ? Colors.black54 : Colors.white,
                              children: [
                                _buildSwitchListTile(
                                  'Show Total Sessions',
                                  settings.showTotalSessions,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowTotalSessions(value);
                                    setStateModal(
                                        () {}); // Mettre à jour l'état du modal
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Total Weight',
                                  settings.showTotalWeight,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowTotalWeight(value);
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Sessions',
                                  settings.showWeeklySessions,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowWeeklySessions(value);
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Weight',
                                  settings.showWeeklyWeight,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowWeeklyWeight(value);
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Time',
                                  settings.showWeeklyTime,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowWeeklyTime(value);
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weight Chart',
                                  settings.showWeeklyChart,
                                  (value) {
                                    ref
                                        .read(
                                            statisticsSettingsProvider.notifier)
                                        .toggleShowWeeklyChart(value);
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 17,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Méthode auxiliaire pour construire les tiles de switch
  Widget _buildSwitchListTile(
      String title, bool value, ValueChanged<bool> onChanged, bool isDarkMode) {
    return CupertinoListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      ),
      backgroundColor: isDarkMode ? Colors.black54 : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    final settings = ref.watch(statisticsSettingsProvider);

    return CupertinoPageScaffold(
      child: Stack(
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
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('users')
                  .doc(_user!.uid)
                  .collection('completedSessions')
                  .snapshots(), // Flux en temps réel des sessions complétées de l'utilisateur
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // En cas d'erreur, afficher un message
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Afficher un indicateur de chargement pendant la récupération des données
                  return const Center(child: CupertinoActivityIndicator());
                }

                if (snapshot.hasData) {
                  // Si les données sont disponibles, mettre à jour les statistiques
                  _updateStatistics(snapshot.data!);
                }

                // Générer les sections en fonction des réglages
                List<StatisticSection> sections = [];

                if (settings.selectedMenu == StatisticsMenu.general) {
                  // Générer les sections générales en respectant l'ordre
                  for (String sectionId in settings.generalOrder) {
                    switch (sectionId) {
                      case 'general_sessions':
                        if (settings.showTotalSessions) {
                          sections.add(StatisticSection(
                            id: 'general_sessions',
                            widget: _buildDraggableSection(
                              'general_sessions',
                              _buildGeneralStatCard(
                                title: 'Total Sessions',
                                value: '$totalSessions',
                                cupertinoIcon: CupertinoIcons.calendar,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      case 'general_weight':
                        if (settings.showTotalWeight) {
                          sections.add(StatisticSection(
                            id: 'general_weight',
                            widget: _buildDraggableSection(
                              'general_weight',
                              _buildGeneralStatCard(
                                title: 'Total Weight Lifted',
                                value: '${totalWeight.toStringAsFixed(1)} kg',
                                cupertinoIcon: CupertinoIcons.sportscourt,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      default:
                        // Ignorer les identifiants inconnus
                        break;
                    }
                  }
                } else if (settings.selectedMenu == StatisticsMenu.week) {
                  // Générer les sections hebdomadaires en respectant l'ordre
                  for (String sectionId in settings.weekOrder) {
                    switch (sectionId) {
                      case 'weekly_sessions':
                        if (settings.showWeeklySessions) {
                          sections.add(StatisticSection(
                            id: 'weekly_sessions',
                            widget: _buildDraggableSection(
                              'weekly_sessions',
                              _buildWeeklyStatCard(
                                title: 'Sessions this Week',
                                value: '$weeklySessions',
                                cupertinoIcon:
                                    CupertinoIcons.check_mark_circled,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      case 'weekly_weight':
                        if (settings.showWeeklyWeight) {
                          sections.add(StatisticSection(
                            id: 'weekly_weight',
                            widget: _buildDraggableSection(
                              'weekly_weight',
                              _buildWeeklyStatCard(
                                title: 'Weight Lifted this Week',
                                value: '${weeklyWeight.toStringAsFixed(1)} kg',
                                cupertinoIcon: CupertinoIcons.sportscourt,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      case 'weekly_time':
                        if (settings.showWeeklyTime) {
                          sections.add(StatisticSection(
                            id: 'weekly_time',
                            widget: _buildDraggableSection(
                              'weekly_time',
                              _buildWeeklyStatCard(
                                title: 'Time Spent this Week',
                                value:
                                    '${weeklyTimeSpent.inHours}h ${weeklyTimeSpent.inMinutes.remainder(60)}m',
                                cupertinoIcon: CupertinoIcons.time,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      case 'weekly_chart':
                        if (settings.showWeeklyChart) {
                          sections.add(StatisticSection(
                            id: 'weekly_chart',
                            widget: _buildDraggableSection(
                              'weekly_chart',
                              _buildWeeklyChartCard(isDarkMode),
                            ),
                          ));
                        }
                        break;
                      default:
                        // Ignorer les identifiants inconnus
                        break;
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne avec le titre et le bouton de paramètres
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settings.selectedMenu == StatisticsMenu.general
                                ? 'General Statistics'
                                : 'Statistics Week',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCustomizationModal(settings),
                            child: Icon(
                              CupertinoIcons.slider_horizontal_3,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Espacement

                      // Segmented Control pour les menus
                      CupertinoSegmentedControl<StatisticsMenu>(
                        children: const {
                          StatisticsMenu.general: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('  General  '),
                          ),
                          StatisticsMenu.week: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('  Week  '),
                          ),
                        },
                        groupValue: settings.selectedMenu,
                        onValueChanged: (StatisticsMenu value) {
                          ref
                              .read(statisticsSettingsProvider.notifier)
                              .setSelectedMenu(value);
                          // Pas besoin d'appeler _updateSections ici car la build sera réactive
                        },
                      ),
                      const SizedBox(height: 16), // Espacement

                      // Expanded ReorderableColumn pour permettre le drag and drop
                      Expanded(
                        child: ReorderableColumn(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          onReorder: (int oldIndex, int newIndex) {
                            if (settings.selectedMenu ==
                                StatisticsMenu.general) {
                              final updatedOrder =
                                  List<String>.from(settings.generalOrder);
                              final movedItem = updatedOrder.removeAt(oldIndex);
                              updatedOrder.insert(newIndex, movedItem);
                              ref
                                  .read(statisticsSettingsProvider.notifier)
                                  .setGeneralOrder(updatedOrder);
                            } else {
                              final updatedOrder =
                                  List<String>.from(settings.weekOrder);
                              final movedItem = updatedOrder.removeAt(oldIndex);
                              updatedOrder.insert(newIndex, movedItem);
                              ref
                                  .read(statisticsSettingsProvider.notifier)
                                  .setWeekOrder(updatedOrder);
                            }
                            // Pas besoin d'appeler _updateSections ici car la build sera réactive
                          },
                          needsLongPressDraggable:
                              true, // Permettre le drag sur appui long
                          children: sections
                              .map((section) => Padding(
                                    key: ValueKey(
                                        section.id), // Assigner une clé unique
                                    padding:
                                        const EdgeInsets.only(bottom: 16.0),
                                    child: section.widget,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour construire une section réordonnable avec une poignée de drag
  Widget _buildDraggableSection(String id, Widget content) {
    return Row(
      children: [
        Expanded(child: content),
      ],
    );
  }

  // Widget pour afficher une carte de statistique générale
  Widget _buildGeneralStatCard({
    required String title,
    required String value,
    required IconData cupertinoIcon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Padding interne
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]
            : Colors.white, // Couleur de fond selon le thème
        borderRadius: BorderRadius.circular(12.0), // Coins arrondis
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2), // Ombre portée
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône dans un conteneur arrondi
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(cupertinoIcon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          // Texte pour le titre et la valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la statistique
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Valeur de la statistique
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
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

  // Widget pour afficher une carte de statistique hebdomadaire
  Widget _buildWeeklyStatCard({
    required String title,
    required String value,
    required IconData cupertinoIcon,
    required Color color,
    required bool isDarkMode,
  }) {
    return _buildGeneralStatCard(
      title: title,
      value: value,
      cupertinoIcon: cupertinoIcon,
      color: color,
      isDarkMode: isDarkMode,
    );
  }

  // Widget pour afficher le graphique du poids soulevé par jour
  Widget _buildWeeklyChartCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Padding interne
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]
            : Colors.white, // Couleur de fond selon le thème
        borderRadius: BorderRadius.circular(12.0), // Coins arrondis
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2), // Ombre portée
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du graphique
          Text(
            'Weight Lifted per Day',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Afficher le graphique
          SizedBox(
            height: 200, // Hauteur du graphique
            child: SfCartesianChart(
              backgroundColor:
                  Colors.transparent, // Fond transparent pour le graphique
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Couleur des labels de l'axe X
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Couleur des labels de l'axe Y
                ),
                majorGridLines: MajorGridLines(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
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

// Classe personnalisée pour CupertinoListTile (car Flutter ne fournit pas de CupertinoListTile par défaut)
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget trailing;
  final Color backgroundColor;

  const CupertinoListTile({
    Key? key,
    required this.title,
    required this.trailing,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          title,
          trailing,
        ],
      ),
    );
  }
}
