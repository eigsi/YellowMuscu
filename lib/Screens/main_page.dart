// main_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellowmuscu/Screens/session_page.dart';
import 'package:yellowmuscu/widgets/weekly_chart_widget.dart';
import 'package:yellowmuscu/main_page/streaks_widget.dart';
import 'package:yellowmuscu/screens/profile_page.dart';
import 'package:yellowmuscu/screens/statistics_page.dart';
import 'package:yellowmuscu/screens/exercises_page.dart';
import 'package:yellowmuscu/Screens/app_bar_widget.dart';
import 'package:yellowmuscu/Screens/bottom_nav_bar_widget.dart';
import 'package:yellowmuscu/main_page/like_item_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String? _userId;

  late List<Widget> _widgetOptions;

  List<Map<String, dynamic>> likesData = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _widgetOptions = <Widget>[
      _buildHomePage(),
      const ExercisesPage(),
      const StatisticsPage(),
      const SessionPage(),
      const ProfilePage(),
    ];
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
        _fetchFriendsEvents();
      });
    }
  }

  /// Fonction pour récupérer le nom complet et la photo de profil d'un utilisateur
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return {
        'last_name': data['last_name'] ?? 'Inconnu',
        'first_name': data['first_name'] ?? 'Utilisateur',
        'profilePicture': data['profilePicture'] ??
            'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg',
      };
    } else {
      return {
        'last_name': 'Inconnu',
        'first_name': 'Utilisateur',
        'profilePicture':
            'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg',
      };
    }
  }

  void _fetchFriendsEvents() async {
    if (_userId == null) return;

    try {
      // Récupérer le document utilisateur
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      // Vérifier si le document existe
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non trouvé.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Vérifier si le champ 'friends' existe et est une liste
      List<dynamic> friends = [];
      if (userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('friends') && data['friends'] is List) {
          friends = data['friends'];
        }
      }

      // Récupérer les données de chaque ami
      Map<String, Map<String, dynamic>> friendsData = {};

      for (String friendId in friends) {
        Map<String, dynamic> friendData = await _getUserData(friendId);
        friendsData[friendId] = friendData;
      }

      // Récupérer les événements de chaque ami
      List<Map<String, dynamic>> events = [];

      for (String friendId in friends) {
        QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .collection('events')
            .get();

        for (var doc in eventsSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // S'assurer que les champs nécessaires existent
          String profileImage = friendsData[friendId]?['profilePicture'] ??
              'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg';
          String description =
              data['description']?.toString() ?? 'Description non disponible.';
          Timestamp timestamp =
              data['timestamp'] ?? Timestamp.fromDate(DateTime(1970));

          events.add({
            'eventId': doc.id,
            'friendId': friendId,
            'profileImage': profileImage,
            'description': description,
            'timestamp': timestamp,
          });
        }
      }

      // Trier les événements par date décroissante
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      setState(() {
        likesData = events;
      });
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des événements: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour construire la page d'accueil avec le dégradé
  Widget _buildHomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints
              .maxHeight, // S'assure que le conteneur occupe toute la hauteur
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildChartSection(),
                    const SizedBox(height: 16),
                    if (_userId != null) StreaksWidget(userId: _userId!),
                    const SizedBox(height: 16),
                    _buildLikesSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
            'Activités de vos amis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          likesData.isEmpty
              ? const Text('Aucune activité récente.')
              : Column(
                  children: List.generate(likesData.length, (index) {
                    return LikeItem(
                      profileImage: likesData[index]['profileImage'] as String,
                      description: likesData[index]['description'] as String,
                      onLike: () => _likeEvent(likesData[index]),
                    );
                  }),
                ),
        ],
      ),
    );
  }

  void _likeEvent(Map<String, dynamic> event) async {
    if (_userId == null) return;

    try {
      // Ajouter un like à l'événement
      String friendId = event['friendId'] as String;
      String eventId = event['eventId'] as String;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('events')
          .doc(eventId)
          .update({
        'likes': FieldValue.arrayUnion([_userId])
      });

      // Ajouter une notification à l'ami
      Map<String, dynamic> currentUserData = await _getUserData(_userId!);
      String fromUserName =
          '${currentUserData['last_name']} ${currentUserData['first_name']}'
              .trim();
      String fromUserProfilePicture = currentUserData['profilePicture'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('notifications')
          .add({
        'type': 'like',
        'fromUserId': _userId,
        'fromUserName': fromUserName,
        'fromUserProfilePicture': fromUserProfilePicture,
        'eventId': eventId,
        'timestamp': FieldValue.serverTimestamp(),
        'description': event['description'] ?? 'Aucune description disponible.',
      });

      // Mettre à jour l'interface utilisateur
      _fetchFriendsEvents();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez liké une activité'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Supprimer le dégradé du body ici
      body: _widgetOptions.elementAt(_selectedIndex),
      appBar: const AppBarWidget(),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 0) {
              _fetchFriendsEvents();
            }
          });
        },
      ),
    );
  }
}
