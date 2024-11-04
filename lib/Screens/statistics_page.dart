// Import necessary packages
import 'package:flutter/cupertino.dart'; // To use Cupertino widgets
import 'package:flutter/material.dart'; // Main Flutter widget library
import 'package:cloud_firestore/cloud_firestore.dart'; // Interact with Firestore
import 'package:syncfusion_flutter_charts/charts.dart'; // Create interactive charts
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management with Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider for theme (light/dark)

// Definition of the StatisticsPage class, a ConsumerStatefulWidget to use Riverpod
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

// State associated with the StatisticsPage class
class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  // Firebase instances for authentication and Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Currently logged-in user
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variables to store general statistics
  int totalSessions = 0; // Total number of completed sessions
  double totalWeight = 0.0; // Total weight lifted
  Map<String, int> sessionsPerCategory =
      {}; // Number of sessions per category (not used in this code)
  Map<String, double> weightPerDay = {}; // Weight lifted per day of the week

  // Variables for weekly statistics
  int weeklySessions = 0; // Number of sessions this week
  double weeklyWeight = 0.0; // Weight lifted this week
  Duration weeklyTimeSpent =
      const Duration(); // Time spent in sessions this week

  // Variables to control the visibility of statistics
  bool showTotalSessions = true;
  bool showTotalWeight = true;
  bool showWeeklySessions = true;
  bool showWeeklyWeight = true;
  bool showWeeklyTime = true;
  bool showWeeklyChart = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Get the currently logged-in user
  }

  // Method to get the abbreviated English name of the weekday
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

  // Method to create data series for the chart
  List<ChartSeries<DayWeight, String>> _createWeightSeries() {
    // Transform the weightPerDay Map into a list of DayWeight objects
    final data = weightPerDay.entries
        .map((entry) => DayWeight(entry.key, entry.value))
        .toList();

    return [
      // Create a column series for the chart
      ColumnSeries<DayWeight, String>(
        dataSource: data, // Data source
        xValueMapper: (DayWeight dw, _) => dw.day, // Map day name on X-axis
        yValueMapper: (DayWeight dw, _) => dw.weight, // Map weight on Y-axis
        color: Colors.blue, // Color of the chart bars
      )
    ];
  }

  // Asynchronous method to update statistics
  Future<void> _updateStatistics(
      QuerySnapshot<Map<String, dynamic>> snapshot) async {
    if (_user == null) return; // If the user is not logged in, exit the method

    // Reset statistics
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

    // Calculate the start and end dates of the current week
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    Timestamp startTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
    Timestamp endTimestamp = Timestamp.fromDate(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 7));

    // Iterate over each document (completed session) in the snapshot
    for (var doc in snapshot.docs) {
      totalSessions += 1; // Increment total sessions

      // Get the total weight lifted for this session
      double weight = doc.data()['totalWeight']?.toDouble() ?? 0.0;
      totalWeight += weight; // Add to total weight

      // Get the session date
      Timestamp sessionDate = doc.data()['date'];
      // Check if the session is in the current week
      if (sessionDate.compareTo(startTimestamp) >= 0 &&
          sessionDate.compareTo(endTimestamp) < 0) {
        weeklySessions += 1; // Increment sessions this week
        weeklyWeight += weight; // Add to weight lifted this week

        // Get the duration of the session and convert to Duration
        String duration = doc.data()['duration'] ?? "0:0:0";
        List<String> parts = duration.split(':');
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);

        weeklyTimeSpent += Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds); // Add to time spent this week

        // Get the English name of the weekday
        DateTime date = sessionDate.toDate();
        String day = _getEnglishDayName(date.weekday);
        // Add the weight lifted on that day
        weightPerDay[day] = (weightPerDay[day] ?? 0.0) + weight;
      }
    }

    setState(() {}); // Update the user interface
  }

  // Method to show the customization modal
  void _showCustomizationModal() {
    final isDarkMode = ref.watch(themeProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              color: isDarkMode ? Colors.black : Colors.white,
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
                                  isDarkMode ? Colors.black : Colors.white,
                              children: [
                                _buildSwitchListTile(
                                  'Show Total Sessions',
                                  showTotalSessions,
                                  (value) {
                                    setState(() {
                                      showTotalSessions = value;
                                    });
                                    setStateModal(() {}); // Update modal state
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Total Weight',
                                  showTotalWeight,
                                  (value) {
                                    setState(() {
                                      showTotalWeight = value;
                                    });
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Sessions',
                                  showWeeklySessions,
                                  (value) {
                                    setState(() {
                                      showWeeklySessions = value;
                                    });
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Weight',
                                  showWeeklyWeight,
                                  (value) {
                                    setState(() {
                                      showWeeklyWeight = value;
                                    });
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weekly Time',
                                  showWeeklyTime,
                                  (value) {
                                    setState(() {
                                      showWeeklyTime = value;
                                    });
                                    setStateModal(() {});
                                  },
                                  isDarkMode,
                                ),
                                _buildSwitchListTile(
                                  'Show Weight Chart',
                                  showWeeklyChart,
                                  (value) {
                                    setState(() {
                                      showWeeklyChart = value;
                                    });
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
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: isDarkMode ? Colors.blue : Colors.blue,
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
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        ref.watch(themeProvider); // Check if dark theme is enabled

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        const Color.fromRGBO(255, 204, 0, 1.0),
                        Colors.black
                      ] // Colors for dark theme
                    : [
                        const Color.fromRGBO(255, 204, 0, 1.0),
                        const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
                      ], // Colors for light theme
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
                  .snapshots(), // Real-time stream of the user's completed sessions
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // In case of error, display a message
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Display a loading indicator while fetching data
                  return const Center(child: CupertinoActivityIndicator());
                }

                if (snapshot.hasData) {
                  // If data is available, update the statistics
                  _updateStatistics(snapshot.data!);
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    // Allow content to scroll if necessary
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row with title and settings button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'General Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showCustomizationModal,
                              child: Icon(
                                CupertinoIcons.slider_horizontal_3,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Spacing
                        // Conditionally display total number of sessions
                        if (showTotalSessions)
                          _buildGeneralStatCard(
                            title: 'Total Sessions',
                            value: '$totalSessions',
                            cupertinoIcon: CupertinoIcons.calendar,
                            color: Colors.black,
                            isDarkMode: isDarkMode,
                          ),
                        if (showTotalSessions) const SizedBox(height: 16),
                        // Conditionally display total weight lifted
                        if (showTotalWeight)
                          _buildGeneralStatCard(
                            title: 'Total Weight Lifted',
                            value: '${totalWeight.toStringAsFixed(1)} kg',
                            cupertinoIcon: CupertinoIcons.sportscourt,
                            color: Colors.black,
                            isDarkMode: isDarkMode,
                          ),
                        if (showTotalWeight) const SizedBox(height: 32),
                        // Weekly Statistics Title
                        Text(
                          'Weekly Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Conditionally display number of sessions this week
                        if (showWeeklySessions)
                          _buildWeeklyStatCard(
                            title: 'Sessions this Week',
                            value: '$weeklySessions',
                            cupertinoIcon: CupertinoIcons.check_mark_circled,
                            color: Colors.black,
                            isDarkMode: isDarkMode,
                          ),
                        if (showWeeklySessions) const SizedBox(height: 16),
                        // Conditionally display weight lifted this week
                        if (showWeeklyWeight)
                          _buildWeeklyStatCard(
                            title: 'Weight Lifted this Week',
                            value: '${weeklyWeight.toStringAsFixed(1)} kg',
                            cupertinoIcon: CupertinoIcons.sportscourt,
                            color: Colors.black,
                            isDarkMode: isDarkMode,
                          ),
                        if (showWeeklyWeight) const SizedBox(height: 16),
                        // Conditionally display time spent in sessions this week
                        if (showWeeklyTime)
                          _buildWeeklyStatCard(
                            title: 'Time Spent this Week',
                            value:
                                '${weeklyTimeSpent.inHours}h ${weeklyTimeSpent.inMinutes.remainder(60)}m',
                            cupertinoIcon: CupertinoIcons.time,
                            color: Colors.black,
                            isDarkMode: isDarkMode,
                          ),
                        if (showWeeklyTime) const SizedBox(height: 16),
                        // Conditionally display chart of weight lifted per day
                        if (showWeeklyChart) _buildWeeklyChartCard(isDarkMode),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16.0), // Inner padding
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
      child: Row(
        children: [
          // Icon in a rounded container
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
          // Text for title and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistic title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                // Statistic value
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

  // Widget to display the chart of weight lifted per day
  Widget _buildWeeklyChartCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Inner padding
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
            height: 200, // Height of the chart
            child: SfCartesianChart(
              backgroundColor:
                  Colors.transparent, // Transparent background for the chart
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // X-axis label color
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black, // Y-axis label color
                ),
                majorGridLines: MajorGridLines(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              series: _createWeightSeries(), // Chart data
            ),
          ),
        ],
      ),
    );
  }
}

// Class to represent the weight lifted each day
class DayWeight {
  final String day; // Name of the day
  final double weight; // Weight lifted on that day

  DayWeight(this.day, this.weight); // Constructor
}
