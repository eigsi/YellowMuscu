import 'package:flutter/material.dart';
import 'package:yellowmuscu/Screens/seance_page.dart';
import 'package:yellowmuscu/widgets/weekly_chart_widget.dart';
import 'package:yellowmuscu/main_page/streaks_widget.dart';
import 'package:yellowmuscu/screens/profile_page.dart';
import 'package:yellowmuscu/screens/statistics_page.dart';
import 'package:yellowmuscu/screens/exercises_page.dart';
import 'package:yellowmuscu/Screens/app_bar_widget.dart'; // Import your new AppBarWidget
import 'package:yellowmuscu/Screens/bottom_nav_bar_widget.dart'; // Import your new BottomNavBarWidget
import 'package:yellowmuscu/main_page/like_item_widget.dart'; // Import LikeItem widget

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final int _streakCount = 19;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildChartSection(),
            const SizedBox(height: 16),
            StreaksWidget(streakCount: _streakCount),
            const SizedBox(height: 16),
            _buildLikesSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ExercisesPage(),
      StatisticsPage(),
      SeancePage(), // Add the SeancePage here
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Méthode pour construire la section des graphiques
  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
      child: WeeklyChartWidget(
        data: [
          ActivityData('Lun', 3),
          ActivityData('Mar', 5),
          ActivityData('Mer', 2),
          ActivityData('Jeu', 6),
          ActivityData('Ven', 4),
          ActivityData('Sam', 7),
          ActivityData('Dim', 1),
        ],
      ),
    );
  }

  // Méthode pour construire la section des likes
  Widget _buildLikesSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Likes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(likesData.length, (index) {
              return LikeItem(
                profileImage: likesData[index]['profileImage'],
                description: likesData[index]['description'],
              );
            }),
          ),
        ],
      ),
    );
  }

  // Exemple de données pour les likes
  List<Map<String, dynamic>> likesData = [
    {
      'profileImage':
          'https://cdn.pixabay.com/photo/2018/03/31/19/29/schnitzel-3279045_1280.jpg',
      'description': '35kg at Squat!',
    },
    {
      'profileImage':
          'https://cdn.pixabay.com/photo/2018/03/31/19/29/schnitzel-3279045_1280.jpg',
      'description': 'New best train!',
    },
    {
      'profileImage':
          'https://cdn.pixabay.com/photo/2018/03/31/19/29/schnitzel-3279045_1280.jpg',
      'description': 'First session ever!',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilisation d'un dégradé pour le fond du Scaffold
      body: Container(
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
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      appBar: AppBarWidget(), // Use the new AppBarWidget here

      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
