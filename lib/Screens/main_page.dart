// main_page.dart

// Importation des packages nécessaires pour Flutter et Firebase
import 'package:flutter/material.dart'; // Bibliothèque de widgets matériels de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore
import 'package:yellowmuscu/Screens/session_page.dart'; // Page de session de l'application YellowMuscu
import 'package:yellowmuscu/main_page/streaks_widget.dart'; // Widget personnalisé pour afficher les séries (streaks)
import 'package:yellowmuscu/screens/profile_page.dart'; // Page de profil utilisateur
import 'package:yellowmuscu/screens/statistics_page.dart'; // Page de statistiques utilisateur
import 'package:yellowmuscu/screens/exercises_page.dart'; // Page des exercices
import 'package:yellowmuscu/Screens/app_bar_widget.dart'; // Widget personnalisé pour la barre d'application
import 'package:yellowmuscu/Screens/bottom_nav_bar_widget.dart'; // Widget personnalisé pour la barre de navigation inférieure
import 'package:yellowmuscu/main_page/like_item_widget.dart'; // Widget personnalisé pour afficher les éléments likés
import 'dart:async'; // Pour utiliser les objets Timer et gérer l'asynchronisme
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Pour la gestion de l'état avec Riverpod
import 'package:yellowmuscu/Provider/theme_provider.dart'; // Provider pour gérer le thème (clair/sombre)
import 'package:flutter/cupertino.dart'; // Pour utiliser CupertinoSegmentedControl

/// Énumération pour le menu des statistiques
enum StatisticsMenu { amis, personnel }

/// Classe principale de la page, qui est un ConsumerStatefulWidget pour utiliser Riverpod
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

/// État associé à la classe MainPage
class MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex =
      0; // Index de l'onglet sélectionné dans la barre de navigation
  String? _userId; // Identifiant de l'utilisateur actuel

  List<Map<String, dynamic>> likesData = []; // Liste des données des likes
  List<Map<String, dynamic>> personalActivities =
      []; // Liste des activités personnelles
  List<String> hiddenEvents = []; // Liste des eventId des événements supprimés

  // Liste des jours de la semaine en français
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  StatisticsMenu _selectedMenu = StatisticsMenu.amis; // Menu sélectionné

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // Appel pour récupérer l'utilisateur actuel lors de l'initialisation
  }

  /// Méthode pour obtenir l'utilisateur actuel connecté via Firebase Auth
  void _getCurrentUser() {
    User? user =
        FirebaseAuth.instance.currentUser; // Récupère l'utilisateur courant
    if (user != null) {
      setState(() {
        _userId = user.uid; // Stocke l'ID de l'utilisateur
        _fetchFriendsEvents(); // Récupère les événements des amis de l'utilisateur
        _fetchPersonalActivities(); // Récupère les activités personnelles
      });
    }
  }

  /// Méthode pour récupérer les événements des amis de l'utilisateur
  void _fetchFriendsEvents() async {
    if (_userId == null) {
      return; // Si l'utilisateur n'est pas connecté, ne rien faire
    }

    try {
      // Récupérer le document de l'utilisateur actuel depuis Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (!mounted) return;

      // Vérifier si le document existe
      if (!userDoc.exists) {
        // Afficher un message d'erreur si l'utilisateur n'existe pas
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisateur non trouvé.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Récupérer la liste des amis de l'utilisateur et les événements cachés
      List<dynamic> friends = [];
      if (userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('friends') && data['friends'] is List) {
          friends = data['friends']; // Liste des IDs des amis
        }
        if (data.containsKey('hiddenEvents') && data['hiddenEvents'] is List) {
          hiddenEvents = List<String>.from(
              data['hiddenEvents']); // Liste des eventId cachés
        }
      }

      // Récupérer les données de chaque ami
      Map<String, Map<String, dynamic>> friendsData = {};

      for (String friendId in friends) {
        // Pour chaque ami, récupérer ses données
        Map<String, dynamic> friendData = await _getUserData(friendId);
        friendsData[friendId] = friendData;
      }

      // Récupérer les événements de chaque ami
      List<Map<String, dynamic>> events = [];

      for (String friendId in friends) {
        // Récupérer les événements de l'ami depuis sa collection 'events' dans Firestore
        QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(friendId)
                .collection('events')
                .get();

        for (var doc in eventsSnapshot.docs) {
          Map<String, dynamic> data = doc.data();
          String eventId = doc.id;

          // Filtrer les événements cachés
          if (hiddenEvents.contains(eventId)) {
            continue; // Ignorer cet événement
          }

          // S'assurer que les champs nécessaires existent
          String profileImage = friendsData[friendId]?['profilePicture'] ??
              'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg';
          String description =
              data['description']?.toString() ?? 'Description non disponible.';
          Timestamp timestamp =
              data['timestamp'] ?? Timestamp.fromDate(DateTime(1970));

          String friendName =
              '${friendsData[friendId]?['first_name'] ?? ''} ${friendsData[friendId]?['last_name'] ?? ''}'
                  .trim();

          events.add({
            'eventId': eventId,
            'friendId': friendId,
            'friendName': friendName,
            'profileImage': profileImage,
            'description': description,
            'timestamp': timestamp,
            'likes': data['likes'] ?? [],
          });
        }
      }

      // Trier les événements par date décroissante (plus récents en premier)
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (!mounted) return;

      setState(() {
        likesData = events; // Mettre à jour la liste des événements likés
      });
    } catch (e) {
      // Gérer les erreurs en affichant un message à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la récupération des événements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Méthode pour récupérer les activités personnelles de l'utilisateur
  void _fetchPersonalActivities() async {
    if (_userId == null) {
      return;
    }

    try {
      QuerySnapshot<Map<String, dynamic>> eventsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('events')
              .get();

      List<Map<String, dynamic>> events = [];

      for (var doc in eventsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        String eventId = doc.id;

        String profileImage =
            'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg'; // Image par défaut
        String description =
            data['description']?.toString() ?? 'Description non disponible.';
        Timestamp timestamp =
            data['timestamp'] ?? Timestamp.fromDate(DateTime(1970));

        // Récupérer les likes
        List<dynamic> likes = data['likes'] ?? [];

        events.add({
          'eventId': eventId,
          'profileImage': profileImage,
          'description': description,
          'timestamp': timestamp,
          'likes': likes,
        });
      }

      // Trier les événements par date décroissante
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      if (!mounted) return;

      setState(() {
        personalActivities = events;
      });
    } catch (e) {
      // Gérer les erreurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur lors de la récupération de vos activités: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Fonction pour récupérer les données d'un utilisateur (nom complet et photo de profil)
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      return {
        'last_name': data['last_name'] ?? 'Inconnu',
        'first_name': data['first_name'] ?? 'Utilisateur',
        'profilePicture': data['profilePicture'] ??
            'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg',
      };
    } else {
      // Si l'utilisateur n'existe pas, retourner des valeurs par défaut
      return {
        'last_name': 'Inconnu',
        'first_name': 'Utilisateur',
        'profilePicture':
            'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg',
      };
    }
  }

  /// Méthode pour liker un événement
  void _likeEvent(Map<String, dynamic> event) async {
    if (_userId == null) {
      return; // Si l'utilisateur n'est pas connecté, ne rien faire
    }

    try {
      // Récupérer les informations nécessaires de l'événement
      String friendId = event['friendId'] as String;
      String eventId = event['eventId'] as String;

      // Vérifier si l'utilisateur a déjà liké l'événement
      List<dynamic> currentLikes = event['likes'] as List<dynamic>? ?? [];
      if (currentLikes.contains(_userId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà liké cet événement.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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

      // Ajouter une notification à l'ami pour l'informer du like
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

      // Mettre à jour l'interface utilisateur en rafraîchissant les événements
      _fetchFriendsEvents();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez liké une activité'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Gérer les erreurs en affichant un message à l'utilisateur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Méthode pour construire la section de résumé du programme
  Widget _buildProgramSummarySection() {
    if (_userId == null) {
      // Si l'utilisateur n'est pas connecté, afficher un message
      return const Text('Veuillez vous connecter pour voir vos programmes.');
    }

    // Utilise un StreamBuilder pour écouter les changements dans la collection 'programs' de l'utilisateur
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('programs')
          .snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affiche un indicateur de progression pendant le chargement
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Affiche un message en cas d'erreur
          return const Text('Erreur de chargement des programmes.');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Si aucun programme n'est disponible
          return const Text('Aucun programme disponible.');
        }

        // Convertir les documents en une liste de maps
        List<Map<String, dynamic>> programs = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data();

          return {
            'id': doc.id,
            'name': data['name'] ?? 'Programme sans nom',
            'icon': data['icon'] ?? 'lib/data/icon_images/chest_part.png',
            'iconName': data['iconName'] ?? 'Chest part',
            'day': data['day'] ?? '',
            'isFavorite': data['isFavorite'] ?? false,
            'exercises': data['exercises'] ?? [],
          };
        }).toList();

        // Déterminer le prochain programme à venir
        Map<String, dynamic>? nextProgram = _getNextProgram(programs);

        if (nextProgram == null) {
          return const Text('Aucun programme programmé pour le moment.');
        }

        // Retourne le widget affichant le résumé du prochain programme
        return NextProgramSummary(
          program: nextProgram,
          daysOfWeek: _daysOfWeek,
        );
      },
    );
  }

  /// Méthode pour trouver le prochain programme basé sur le jour actuel
  Map<String, dynamic>? _getNextProgram(List<Map<String, dynamic>> programs) {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Lundi, 7 = Dimanche

    // Filtrer les programmes dont le jour est après le jour actuel
    List<Map<String, dynamic>> futurePrograms = programs.where((program) {
      int programDayIndex = _daysOfWeek.indexOf(program['day']) + 1; // 1-7
      return programDayIndex >= currentWeekday;
    }).toList();

    if (futurePrograms.isNotEmpty) {
      // Trouver le programme avec le jour le plus proche après le jour actuel
      futurePrograms.sort((a, b) {
        int dayA = _daysOfWeek.indexOf(a['day']) + 1;
        int dayB = _daysOfWeek.indexOf(b['day']) + 1;
        return dayA.compareTo(dayB);
      });
      return futurePrograms.first;
    } else if (programs.isNotEmpty) {
      // Si aucun programme n'est après aujourd'hui, retourner le premier programme de la semaine suivante
      return programs.first;
    } else {
      return null; // Aucun programme disponible
    }
  }

  /// Méthode pour construire la section des likes avec suppression permanente
  Widget _buildLikesSection() {
    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? darkWidget : lightWidget,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.7),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment
            .stretch, // Assure que les enfants occupent toute la largeur
        children: [
          // Titre de la section
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          // Container avec borderRadius pour le CupertinoSegmentedControl
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0), // Rayon de la bordure
            ),
            child: CupertinoSegmentedControl<StatisticsMenu>(
              padding:
                  EdgeInsets.zero, // Supprime le padding interne par défaut
              groupValue: _selectedMenu,
              children: {
                StatisticsMenu.amis: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Friends activity',
                    style: TextStyle(
                      color: _selectedMenu == StatisticsMenu.amis
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: _selectedMenu == StatisticsMenu.amis
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                StatisticsMenu.personnel: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Your Activity',
                    style: TextStyle(
                      color: _selectedMenu == StatisticsMenu.amis
                          ? Colors.black
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: _selectedMenu == StatisticsMenu.amis
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
              },
              onValueChanged: (StatisticsMenu value) {
                setState(() {
                  _selectedMenu = value;
                });
              },
              selectedColor: darkBottom,
              unselectedColor: Colors.white,
              borderColor: darkBottom,
            ),
          ),
          const SizedBox(height: 16),
          // Affichage des activités en fonction du menu sélectionné
          _selectedMenu == StatisticsMenu.amis
              ? _buildFriendsActivities(isDarkMode)
              : _buildPersonalActivities(isDarkMode),
        ],
      ),
    );
  }

  /// Méthode pour construire la liste des activités des amis
  Widget _buildFriendsActivities(bool isDarkMode) {
    return likesData.isEmpty
        ? const Center(
            child: Text(
              'No recent activity',
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16.0), // Ajouter du padding interne
            width: double.infinity, // Utiliser toute la largeur disponible
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: likesData.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = likesData[index];
                  bool isLiked =
                      (event['likes'] as List<dynamic>?)?.contains(_userId) ??
                          false;
                  String activityType = event['description'];
                  String formattedDescription = activityType;

                  return Dismissible(
                    key: Key(event['eventId']),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      String dismissedEventId = event['eventId'];

                      setState(() {
                        likesData.removeAt(index);
                      });

                      // Ajouter l'eventId à hiddenEvents dans Firestore
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_userId)
                            .update({
                          'hiddenEvents':
                              FieldValue.arrayUnion([dismissedEventId])
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Erreur lors de la suppression: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      // Afficher un message de confirmation
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Événement supprimé définitivement.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
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
          );
  }

  /// Méthode pour construire la liste des activités personnelles
  Widget _buildPersonalActivities(bool isDarkMode) {
    return personalActivities.isEmpty
        ? Container(
            width: double.infinity, // Assure une largeur constante
            child: const Center(
              child: Text(
                'No recent activity',
                style: TextStyle(
                  color: Colors.black87,
                ),
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16.0), // Ajouter du padding interne
            width: double.infinity, // Utiliser toute la largeur disponible
            child: SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: personalActivities.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = personalActivities[index];
                  List<dynamic> likes = event['likes'] ?? [];
                  int likesCount = likes.length;
                  bool isLiked = likes.contains(_userId);
                  String description = event['description'];

                  return PersonalActivityItem(
                    profileImage: event['profileImage'] as String,
                    description: description,
                    likesCount: likesCount,
                    isLiked: isLiked,
                    onLike: () => _likePersonalEvent(event),
                  );
                },
              ),
            ),
          );
  }

  /// Méthode pour liker une activité personnelle
  void _likePersonalEvent(Map<String, dynamic> event) async {
    if (_userId == null) return;

    try {
      String eventId = event['eventId'] as String;

      List<dynamic> currentLikes = event['likes'] as List<dynamic>? ?? [];
      if (currentLikes.contains(_userId)) {
        // Si déjà liké, retirer le like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('events')
            .doc(eventId)
            .update({
          'likes': FieldValue.arrayRemove([_userId])
        });
      } else {
        // Ajouter un like
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('events')
            .doc(eventId)
            .update({
          'likes': FieldValue.arrayUnion([_userId])
        });
      }

      // Rafraîchir les activités personnelles
      _fetchPersonalActivities();
    } catch (e) {
      // Gérer les erreurs
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Méthode pour construire la page d'accueil avec le dégradé
  Widget _buildHomePage() {
    final isDarkMode = ref.watch(themeProvider);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Dégradé de fond qui couvre tout l'écran
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [darkTop, darkBottom]
                    : [
                        lightTop,
                        lightBottom,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Contenu défilable au-dessus du dégradé
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildProgramSummarySection(), // Affiche le prochain programme
                  const SizedBox(height: 16),
                  if (_userId != null)
                    StreaksWidget(
                        userId:
                            _userId!), // Affiche le widget des séries si l'utilisateur est connecté
                  const SizedBox(height: 16),
                  _buildLikesSection(), // Affiche la section des likes
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
    Widget currentPage;

    // Détermine quelle page afficher en fonction de l'index sélectionné
    switch (_selectedIndex) {
      case 0:
        currentPage = _buildHomePage();
        break;
      case 1:
        currentPage = const ExercisesPage();
        break;
      case 2:
        currentPage = const StatisticsPage();
        break;
      case 3:
        currentPage = const SessionPage();
        break;
      case 4:
        currentPage = const ProfilePage();
        break;
      default:
        currentPage = _buildHomePage();
    }

    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDarkMode
          ? lightTop
          : Colors.white, // Couleur de fond en fonction du thème
      body: currentPage, // Affiche la page actuelle
      appBar: const AppBarWidget(), // Barre d'application personnalisée
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: (int index) {
          setState(() {
            _selectedIndex = index;
            if (_selectedIndex == 0) {
              _fetchFriendsEvents(); // Rafraîchit les événements si l'onglet Accueil est sélectionné
              _fetchPersonalActivities(); // Rafraîchit les activités personnelles
            }
          });
        },
      ),
    );
  }
}

/// Widget pour afficher le résumé du prochain programme avec compte à rebours
class NextProgramSummary extends ConsumerStatefulWidget {
  final Map<String, dynamic> program; // Le programme à afficher
  final List<String> daysOfWeek; // Liste des jours de la semaine

  const NextProgramSummary({
    super.key,
    required this.program,
    required this.daysOfWeek,
  });

  @override
  NextProgramSummaryState createState() => NextProgramSummaryState();
}

class NextProgramSummaryState extends ConsumerState<NextProgramSummary> {
  late DateTime _nextProgramDateTime; // Date et heure du prochain programme
  late Duration _timeRemaining; // Temps restant avant le programme
  Timer? _timer; // Timer pour le compte à rebours

  @override
  void initState() {
    super.initState();
    _nextProgramDateTime =
        _calculateNextProgramDateTime(); // Calcule la date du prochain programme
    _timeRemaining = _nextProgramDateTime
        .difference(DateTime.now()); // Calcule le temps restant
    _startCountdown(); // Démarre le compte à rebours
  }

  @override
  void didUpdateWidget(covariant NextProgramSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.program['day'] != widget.program['day']) {
      // Si le jour du programme a changé, recalculer les dates
      _nextProgramDateTime = _calculateNextProgramDateTime();
      _timeRemaining = _nextProgramDateTime.difference(DateTime.now());
      _timer?.cancel();
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annule le timer lors de la destruction du widget
    super.dispose();
  }

  /// Méthode pour calculer la prochaine DateTime du programme basé sur le jour
  DateTime _calculateNextProgramDateTime() {
    String programDay =
        widget.program['day']; // Exemple: 'Mercredi' ou 'Wednesday'

    // Carte pour mapper les noms des jours en anglais et en français aux numéros de jour
    final Map<String, int> dayNameToWeekday = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
      'Lundi': 1,
      'Mardi': 2,
      'Mercredi': 3,
      'Jeudi': 4,
      'Vendredi': 5,
      'Samedi': 6,
      'Dimanche': 7,
    };

    int programWeekday = dayNameToWeekday[programDay] ?? 0;

    if (programWeekday == 0) {
      // Si le jour n'est pas trouvé, retourner une date lointaine
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Lundi, 7 = Dimanche

    // Calculer le nombre de jours jusqu'au prochain jour du programme
    int daysUntilNext = (programWeekday - currentWeekday + 7) % 7 + 1;

    // Calculer la date du prochain programme
    DateTime nextProgramDate = DateTime(
      now.year,
      now.month,
      now.day,
      8, // Heure spécifique pour le début du programme (8h00)
      0,
      0,
    ).add(Duration(days: daysUntilNext));

    // Si la date du prochain programme est déjà passée aujourd'hui, la planifier pour la semaine suivante
    if (nextProgramDate.isBefore(now)) {
      nextProgramDate = nextProgramDate.add(const Duration(days: 7));
    }

    return nextProgramDate;
  }

  /// Méthode pour démarrer le compte à rebours
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _timeRemaining = _nextProgramDateTime.difference(now);
        if (_timeRemaining.isNegative) {
          _timeRemaining = Duration.zero;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);
    String iconPath = widget.program['icon'] ??
        'lib/data/icon_images/chest_part.png'; // Chemin par défaut
    String programName = widget.program['name'] ?? 'Nom du Programme';
    List<dynamic> exercises = widget.program['exercises'] ?? [];

    // Format du compte à rebours
    String countdownText = _formatDuration(_timeRemaining);

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? darkWidget
            : lightWidget, // Couleur de fond en fonction du thème
        borderRadius: BorderRadius.circular(16.0), // Bordures arrondies
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
          // Compte à rebours en haut
          Text(
            'Next session in $countdownText',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Image et informations du programme
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de la catégorie
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
                      color: Colors.black, // Couleur dynamique
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Liste des exercices
              Expanded(
                child: exercises.isEmpty
                    ? const Text(
                        'No exercice available',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      )
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
                                    color: Colors.black, // Couleur dynamique
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sets: $sets • Reps: $reps • Poids: ${weight}kg • Pause: ${rest}s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
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
        ],
      ),
    );
  }

  /// Méthode pour formater la durée en jours, heures, minutes, secondes
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inDays > 1) {
      return '${duration.inDays} days';
    } else {
      int hours = duration.inHours.remainder(24);
      int minutes = duration.inMinutes.remainder(60);
      return '${twoDigits(hours)} hours ${twoDigits(minutes)} minutes';
    }
  }
}

/// Widget pour les activités personnelles avec le nombre de likes
class PersonalActivityItem extends StatefulWidget {
  final String profileImage;
  final String description;
  final int likesCount;
  final VoidCallback onLike;
  final bool isLiked;

  const PersonalActivityItem({
    super.key,
    required this.profileImage,
    required this.description,
    required this.likesCount,
    required this.onLike,
    required this.isLiked,
  });

  @override
  PersonalActivityItemState createState() => PersonalActivityItemState();
}

class PersonalActivityItemState extends State<PersonalActivityItem>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (_isLiked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PersonalActivityItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      setState(() {
        _isLiked = widget.isLiked;
        if (_isLiked) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLike() {
    widget.onLike();
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Brightness.dark; // Assure que le texte s'adapte au thème

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.profileImage),
      ),
      title: Text(
        widget.description,
        style: const TextStyle(
          color: Colors.black, // Couleur dynamique
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _handleLike,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.likesCount}',
            style: const TextStyle(
              color: Colors.black87, // Couleur dynamique
            ),
          ),
        ],
      ),
    );
  }
}
