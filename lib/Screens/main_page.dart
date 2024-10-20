// main_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellowmuscu/Screens/session_page.dart';
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

  /// Méthode pour récupérer le premier programme de l'utilisateur
  Future<Map<String, dynamic>?> _getFirstProgram() async {
    if (_userId == null) return null;
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } catch (e) {
      print('Erreur lors de la récupération du programme: $e');
      return null;
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

          String friendName =
              '${friendsData[friendId]?['first_name'] ?? ''} ${friendsData[friendId]?['last_name'] ?? ''}'
                  .trim();

          events.add({
            'eventId': doc.id,
            'friendId': friendId,
            'friendName': friendName,
            'profileImage': profileImage,
            'description': description,
            'timestamp': timestamp,
            'likes': data['likes'] ?? [],
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

  // Méthode pour liker un événement
  void _likeEvent(Map<String, dynamic> event) async {
    if (_userId == null) return;

    try {
      // Récupérer les informations nécessaires de l'événement
      String friendId = event['friendId'] as String;
      String eventId = event['eventId'] as String;

      // Vérifier si l'utilisateur a déjà liké l'événement
      List<dynamic> currentLikes = event['likes'] as List<dynamic>? ?? [];
      if (currentLikes.contains(_userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez déjà liké cet événement.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Ajouter un like à l'événement dans Firestore
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

      String activityType = event['description'] ?? 'activité';

      String notificationDescription =
          '$fromUserName a liké votre activité: $activityType';

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
        'description': notificationDescription,
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

  // Méthode pour construire la section de résumé du programme
  Widget _buildProgramSummarySection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getFirstProgram(),
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Text('Aucun programme disponible.');
        }

        var programData = snapshot.data!;

        // Récupérer les informations du programme
        String iconPath = programData['icon'] ??
            'lib/data/icon_images/chest_part.png'; // Chemin par défaut
        String programName = programData['name'] ?? 'Nom du Programme';
        List<dynamic> exercises = programData['exercises'] ?? [];

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section de gauche : Image de la catégorie et nom du programme
              Column(
                children: [
                  Image.asset(
                    iconPath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 80);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    programName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Section de droite : Liste des exercices
              Expanded(
                child: exercises.isEmpty
                    ? const Text('Aucun exercice disponible.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          var exercise = exercises[index];
                          String exerciseName = exercise['name'] ?? 'Exercice';
                          int sets = exercise['sets'] ?? 0;
                          int reps = exercise['reps'] ?? 0;
                          double weight = (exercise['weight'] ?? 0).toDouble();
                          int rest = exercise['restBetweenExercises'] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exerciseName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sets: $sets • Reps: $reps • Poids: ${weight}kg • Pause: ${rest}s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
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
      },
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
              : SizedBox(
                  height: 300, // Hauteur pour rendre la liste scrollable
                  child: ListView.builder(
                    itemCount: likesData.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> event = likesData[index];
                      bool isLiked = (event['likes'] as List<dynamic>?)
                              ?.contains(_userId) ??
                          false;
                      String activityType = event['description'];
                      String formattedDescription =
                          '${event['friendName']} a publié : $activityType';

                      return Dismissible(
                        key: Key(event['eventId']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          setState(() {
                            likesData.removeAt(index);
                          });
                          // Optionnel : Supprimer de Firestore si nécessaire
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: LikeItem(
                          profileImage: event['profileImage'] as String,
                          description: formattedDescription,
                          onLike: () => _likeEvent(event),
                          isLiked: isLiked,
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  // Méthode pour construire la page d'accueil avec le dégradé
  Widget _buildHomePage() {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Dégradé de fond qui couvre tout l'écran
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  //Colors.transparent,
                  //Colors.transparent
                  const Color.fromRGBO(255, 204, 0, 1.0),
                  const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
                ],
              ),
            ),
          ),
          // Contenu défilable au-dessus du dégradé
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildProgramSummarySection(),
                  const SizedBox(height: 16),
                  if (_userId != null) StreaksWidget(userId: _userId!),
                  const SizedBox(height: 16),
                  _buildLikesSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Assure que le Scaffold ne cache pas le dégradé
      body: _widgetOptions[_selectedIndex],
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
