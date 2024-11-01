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

// Classe principale de la page, qui est un ConsumerStatefulWidget pour utiliser Riverpod
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

// État associé à la classe MainPage
class _MainPageState extends ConsumerState<MainPage> {
  int _selectedIndex =
      0; // Index de l'onglet sélectionné dans la barre de navigation
  String? _userId; // Identifiant de l'utilisateur actuel

  List<Map<String, dynamic>> likesData = []; // Liste des données des likes

  // Liste des jours de la semaine en français
  final List<String> _daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // Appel pour récupérer l'utilisateur actuel lors de l'initialisation
  }

  // Méthode pour obtenir l'utilisateur actuel connecté via Firebase Auth
  void _getCurrentUser() {
    User? user =
        FirebaseAuth.instance.currentUser; // Récupère l'utilisateur courant
    if (user != null) {
      setState(() {
        _userId = user.uid; // Stocke l'ID de l'utilisateur
        _fetchFriendsEvents(); // Récupère les événements des amis de l'utilisateur
      });
    }
  }

  // Méthode pour récupérer les événements des amis de l'utilisateur
  void _fetchFriendsEvents() async {
    if (_userId == null)
      return; // Si l'utilisateur n'est pas connecté, ne rien faire

    try {
      // Récupérer le document de l'utilisateur actuel depuis Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      // Vérifier si le document existe
      if (!userDoc.exists) {
        // Afficher un message d'erreur si l'utilisateur n'existe pas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur non trouvé.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Récupérer la liste des amis de l'utilisateur
      List<dynamic> friends = [];
      if (userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('friends') && data['friends'] is List) {
          friends = data['friends']; // Liste des IDs des amis
        }
      }

      print('Nombre d\'amis trouvés: ${friends.length}');

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

        print(
            'Nombre d\'événements pour l\'ami $friendId: ${eventsSnapshot.docs.length}');

        for (var doc in eventsSnapshot.docs) {
          Map<String, dynamic> data = doc.data();

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

      // Trier les événements par date décroissante (plus récents en premier)
      events.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      print('Nombre total d\'événements récupérés: ${events.length}');

      setState(() {
        likesData = events; // Mettre à jour la liste des événements likés
      });
    } catch (e) {
      // Gérer les erreurs en affichant un message à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération des événements: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erreur dans _fetchFriendsEvents: $e');
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
            'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg',
      };
    } else {
      // Si l'utilisateur n'existe pas, retourner des valeurs par défaut
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
    if (_userId == null)
      return; // Si l'utilisateur n'est pas connecté, ne rien faire

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez liké une activité'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Gérer les erreurs en affichant un message à l'utilisateur
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

  // Widget pour afficher le résumé du prochain programme avec compte à rebours
  Widget _buildNextProgramSummary() {
    return _buildProgramSummarySection();
  }

  // Méthode pour construire la section des likes
  Widget _buildLikesSection() {
    final isDarkMode =
        ref.watch(themeProvider); // Vérifie si le thème sombre est activé

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black54
            : Colors.white, // Couleur de fond en fonction du thème
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Text(
            'Activités de vos amis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          // Affichage des activités
          likesData.isEmpty
              ? Text(
                  'Aucune activité récente.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                )
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
    final isDarkMode = ref.watch(themeProvider);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Dégradé de fond qui couvre tout l'écran
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color.fromRGBO(255, 204, 0, 1.0), Colors.black]
                    : [
                        const Color.fromRGBO(255, 204, 0, 1.0),
                        const Color.fromRGBO(255, 204, 0, 0.3),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Contenu défilable au-dessus du dégradé
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildNextProgramSummary(), // Affiche le prochain programme
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
          ? Colors.grey[900]
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
  _NextProgramSummaryState createState() => _NextProgramSummaryState();
}

class _NextProgramSummaryState extends ConsumerState<NextProgramSummary> {
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
    String programDay = widget.program['day'];
    int programWeekday =
        widget.daysOfWeek.indexOf(programDay) + 1; // 1 = Lundi, 7 = Dimanche

    if (programWeekday == 0) {
      // Si le jour n'est pas trouvé, retourner une date lointaine
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // 1 = Lundi, 7 = Dimanche
    int daysUntilNext = programWeekday - currentWeekday;

    if (daysUntilNext < 0 || (daysUntilNext == 0 && now.hour >= 0)) {
      daysUntilNext += 7;
    }

    DateTime nextProgramDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: daysUntilNext));

    // Définir une heure spécifique pour le début du programme (ex: 8h00)
    nextProgramDate = DateTime(
      nextProgramDate.year,
      nextProgramDate.month,
      nextProgramDate.day,
      8,
      0,
      0,
    );

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
            ? Colors.black54 // Couleur de fond en mode sombre
            : Colors.white, // Couleur de fond en mode clair
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1),
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
            'Prochain programme dans : $countdownText',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.red[300] : Colors.red,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Liste des exercices
              Expanded(
                child: exercises.isEmpty
                    ? Text(
                        'Aucun exercice disponible.',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sets: $sets • Reps: $reps • Poids: ${weight}kg • Pause: ${rest}s',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
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
    String days = duration.inDays > 0 ? '${duration.inDays}j ' : '';
    String hours = twoDigits(duration.inHours.remainder(24));
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$days$hours:$minutes:$seconds';
  }
}
