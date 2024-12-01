// lib/statistics_page.dart
//full english

import 'package:flutter/cupertino.dart'; // To use Cupertino widgets
import 'package:flutter/material.dart'; // Main Flutter widget library
import 'package:cloud_firestore/cloud_firestore.dart'; // Interaction with Firestore
import 'package:syncfusion_flutter_charts/charts.dart'; // Creating interactive charts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider for theme (light/dark)
import 'package:yellowmuscu/Provider/statistics_provider.dart'; // Import the new statistics provider

// Class to represent the weight lifted each day
class DayWeight {
  final String day; // Day name
  final double weight; // Weight lifted on that day

  DayWeight(this.day, this.weight); // Constructor
}

// Function to get the abbreviated English day name
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

// Definition of the StatisticSection class
class StatisticSection {
  final String id; // Unique identifier
  final Widget widget; // The widget to display

  StatisticSection({required this.id, required this.widget});
}

// Class to store statistical data
class StatisticsData {
  final int totalSessions;
  final double totalWeight;
  final int weeklySessions;
  final double weeklyWeight;
  final Duration weeklyTimeSpent;
  final Map<String, double> weightPerDay;

  StatisticsData({
    required this.totalSessions,
    required this.totalWeight,
    required this.weeklySessions,
    required this.weeklyWeight,
    required this.weeklyTimeSpent,
    required this.weightPerDay,
  });

  factory StatisticsData.empty() {
    return StatisticsData(
      totalSessions: 0,
      totalWeight: 0.0,
      weeklySessions: 0,
      weeklyWeight: 0.0,
      weeklyTimeSpent: Duration.zero,
      weightPerDay: {
        'Mon': 0.0,
        'Tue': 0.0,
        'Wed': 0.0,
        'Thu': 0.0,
        'Fri': 0.0,
        'Sat': 0.0,
        'Sun': 0.0,
      },
    );
  }
}

// Provider for statistical data
final statisticsDataProvider = StreamProvider<StatisticsData>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  if (user == null) {
    return Stream.value(StatisticsData.empty());
  }

  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('completedSessions')
      .snapshots()
      .asyncMap((snapshot) async {
    int totalSessions = 0;
    double totalWeight = 0.0;
    int weeklySessions = 0;
    double weeklyWeight = 0.0;
    Duration weeklyTimeSpent = Duration.zero;
    Map<String, double> weightPerDay = {
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
    Timestamp endTimestamp = Timestamp.fromDate(
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day));

    for (var doc in snapshot.docs) {
      totalSessions += 1;
      double weight = doc.data()['totalWeight']?.toDouble() ?? 0.0;
      totalWeight += weight;

      Timestamp sessionDate = doc.data()['date'];
      if (sessionDate.compareTo(startTimestamp) >= 0 &&
          sessionDate.compareTo(endTimestamp) < 0) {
        weeklySessions += 1;
        weeklyWeight += weight;

        String duration = doc.data()['duration'] ?? "0:0:0";
        List<String> parts = duration.split(':');
        if (parts.length == 3) {
          int hours = int.parse(parts[0]);
          int minutes = int.parse(parts[1]);
          int seconds = int.parse(parts[2]);
          weeklyTimeSpent +=
              Duration(hours: hours, minutes: minutes, seconds: seconds);
        }

        DateTime date = sessionDate.toDate();
        String day = _getEnglishDayName(date.weekday);
        weightPerDay[day] = (weightPerDay[day] ?? 0.0) + weight;
      }
    }

    return StatisticsData(
      totalSessions: totalSessions,
      totalWeight: totalWeight,
      weeklySessions: weeklySessions,
      weeklyWeight: weeklyWeight,
      weeklyTimeSpent: weeklyTimeSpent,
      weightPerDay: weightPerDay,
    );
  });
});

// Definition of the StatisticsPage class, a ConsumerStatefulWidget to use Riverpod
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

// State associated with the StatisticsPage class
class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    // Retrieve the currently logged-in user
  }

  // Method to display the customization modal
  void _showCustomizationModal() {
    final isDarkMode = ref.watch(themeModeProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(statisticsSettingsProvider);

            return Container(
              color: isDarkMode ? Colors.black54 : Colors.white,
              height: MediaQuery.of(context).size.height * 0.5,
              child: SafeArea(
                child: Column(
                  children: [
                    // Modal title
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
                            // Use CupertinoListSection and CupertinoListTile
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

  // Helper method to build switch tiles
  Widget _buildSwitchListTile(
      String title, bool value, ValueChanged<bool> onChanged, bool isDarkMode) {
    return CupertinoListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
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
    final isDarkMode = ref.watch(themeModeProvider);
    final settings = ref.watch(statisticsSettingsProvider);
    final statisticsDataAsyncValue = ref.watch(statisticsDataProvider);

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [darkTop, darkBottom]
                    : [
                        lightTop,
                        lightBottom,
                      ], // Colors for light theme
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: statisticsDataAsyncValue.when(
              data: (statisticsData) {
                // Generate sections based on settings
                List<StatisticSection> sections = [];

                if (settings.selectedMenu == StatisticsMenu.general) {
                  // Generate general sections respecting the order
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
                                value: '${statisticsData.totalSessions}',
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
                                value:
                                    '${statisticsData.totalWeight.toStringAsFixed(1)} kg',
                                cupertinoIcon: CupertinoIcons.sportscourt,
                                color: Colors.black,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ));
                        }
                        break;
                      default:
                        // Ignore unknown identifiers
                        break;
                    }
                  }
                } else if (settings.selectedMenu == StatisticsMenu.week) {
                  // Generate weekly sections respecting the order
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
                                value: '${statisticsData.weeklySessions}',
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
                                value:
                                    '${statisticsData.weeklyWeight.toStringAsFixed(1)} kg',
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
                                    '${statisticsData.weeklyTimeSpent.inHours}h ${statisticsData.weeklyTimeSpent.inMinutes.remainder(60)}m',
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
                              _buildWeeklyChartCard(
                                  isDarkMode, statisticsData.weightPerDay),
                            ),
                          ));
                        }
                        break;
                      default:
                        // Ignore unknown identifiers
                        break;
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with title and settings button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            settings.selectedMenu == StatisticsMenu.general
                                ? 'General Statistics'
                                : 'Weekly Statistics',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCustomizationModal(),
                            child: Icon(
                              CupertinoIcons.slider_horizontal_3,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Spacing

                      // Segmented Control for menus
                      CupertinoSegmentedControl<StatisticsMenu>(
                        children: {
                          StatisticsMenu.general: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            child: Text(
                              'General',
                              style: TextStyle(
                                color: settings.selectedMenu ==
                                        StatisticsMenu.general
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14,
                                fontWeight: settings.selectedMenu ==
                                        StatisticsMenu.general
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          StatisticsMenu.week: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            child: Text(
                              ' Week',
                              style: TextStyle(
                                color: settings.selectedMenu ==
                                        StatisticsMenu.general
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: settings.selectedMenu ==
                                        StatisticsMenu.general
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        },
                        groupValue: settings.selectedMenu,
                        onValueChanged: (StatisticsMenu value) {
                          ref
                              .read(statisticsSettingsProvider.notifier)
                              .setSelectedMenu(value);
                        },
                        selectedColor: isDarkMode ? lightTop : darkTop,
                        unselectedColor: Colors.white,
                        borderColor: isDarkMode ? lightTop : darkBottom,
                      ),
                      const SizedBox(height: 16), // Spacing

                      // Expanded ReorderableListView to allow drag and drop
                      Expanded(
                        child: PrimaryScrollController(
                          controller: ScrollController(),
                          child: ReorderableListView(
                            onReorder: (int oldIndex, int newIndex) {
                              if (newIndex > oldIndex) {
                                newIndex -= 1;
                              }
                              if (settings.selectedMenu ==
                                  StatisticsMenu.general) {
                                final updatedOrder =
                                    List<String>.from(settings.generalOrder);
                                final movedItem =
                                    updatedOrder.removeAt(oldIndex);
                                updatedOrder.insert(newIndex, movedItem);
                                ref
                                    .read(statisticsSettingsProvider.notifier)
                                    .setGeneralOrder(updatedOrder);
                              } else {
                                final updatedOrder =
                                    List<String>.from(settings.weekOrder);
                                final movedItem =
                                    updatedOrder.removeAt(oldIndex);
                                updatedOrder.insert(newIndex, movedItem);
                                ref
                                    .read(statisticsSettingsProvider.notifier)
                                    .setWeekOrder(updatedOrder);
                              }
                            },
                            children: sections
                                .map((section) => Padding(
                                      key: ValueKey(
                                          section.id), // Assign a unique key
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: section.widget,
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a draggable section with a drag handle
  Widget _buildDraggableSection(String id, Widget content) {
    return Row(
      children: [
        Expanded(child: content),
      ],
    );
  }

  // Widget to display a general statistic card
  Widget _buildGeneralStatCard({
    required String title,
    required String value,
    required IconData cupertinoIcon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Internal padding
      decoration: BoxDecoration(
        color: isDarkMode ? darkWidget : lightWidget,
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2), // Drop shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon inside a rounded container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? lightTop : Colors.grey[200],
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(cupertinoIcon, size: 30, color: color),
          ),
          const SizedBox(width: 16),
          // Text for title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistic title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Statistic value
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display a weekly statistic card
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

  // Widget to display the weight lifted per day chart
  Widget _buildWeeklyChartCard(
      bool isDarkMode, Map<String, double> weightPerDay) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Internal padding
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]
            : Colors.white, // Background color based on theme
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2), // Drop shadow
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Text(
            'Weight Lifted per Day',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Display the chart
          SizedBox(
            height: 200, // Chart height
            child: SfCartesianChart(
              backgroundColor:
                  Colors.transparent, // Transparent background for the chart
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Color of X-axis labels
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Color of Y-axis labels
                ),
                majorGridLines: MajorGridLines(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              series: _createWeightSeries(weightPerDay), // Chart data
            ),
          ),
        ],
      ),
    );
  }

  // Method to create data series for the chart
  List<ChartSeries<DayWeight, String>> _createWeightSeries(
      Map<String, double> weightPerDay) {
    // Transform the weightPerDay Map into a list of DayWeight objects
    final data = weightPerDay.entries
        .map((entry) => DayWeight(entry.key, entry.value))
        .toList();

    return [
      // Create a column series for the chart
      ColumnSeries<DayWeight, String>(
        dataSource: data, // Data source
        xValueMapper: (DayWeight dw, _) => dw.day, // Map day name to X-axis
        yValueMapper: (DayWeight dw, _) => dw.weight, // Map weight to Y-axis
        color: Colors.blue, // Color of the chart bars
      )
    ];
  }
}

// Custom class for CupertinoListTile (since Flutter does not provide a default CupertinoListTile)
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget trailing;
  final Color backgroundColor;

  const CupertinoListTile({
    super.key,
    required this.title,
    required this.trailing,
    required this.backgroundColor,
  });

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
