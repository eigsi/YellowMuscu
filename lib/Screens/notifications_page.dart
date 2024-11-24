// notifications_page.dart

// Importation des packages nécessaires pour Flutter et Firebase
import 'package:flutter/material.dart'; // Bibliothèque de widgets matériels de Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase

// Définition de la classe NotificationsPage qui est un StatefulWidget
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

// État associé à la classe NotificationsPage
class _NotificationsPageState extends State<NotificationsPage> {
  // Instance de FirebaseAuth pour gérer l'authentification
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable pour stocker l'utilisateur actuellement connecté
  List<Map<String, dynamic>> _friendRequests = []; // Liste des demandes d'amis
  List<Map<String, dynamic>> _likes = []; // Liste des likes reçus

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Récupère l'utilisateur actuellement connecté
    if (_user != null) {
      // Si l'utilisateur est connecté, on écoute les changements en temps réel dans les notifications
      FirebaseFirestore.instance
          .collection('users') // Accès à la collection 'users' dans Firestore
          .doc(_user!.uid) // Accès au document de l'utilisateur actuel
          .collection(
              'notifications') // Accès à la sous-collection 'notifications'
          .orderBy('timestamp',
              descending: true) // Trie les notifications par date décroissante
          .snapshots() // Obtient un flux en temps réel des données
          .listen((snapshot) {
        // Écoute les changements dans les notifications
        List<Map<String, dynamic>> friendRequests =
            []; // Liste temporaire pour les demandes d'amis
        List<Map<String, dynamic>> likes =
            []; // Liste temporaire pour les likes

        // Parcourt chaque document de notification
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data =
              doc.data(); // Récupère les données du document
          data['notificationId'] =
              doc.id; // Ajoute l'ID du document aux données

          // Trie les notifications en fonction de leur type
          if (data['type'] == 'friendRequest') {
            friendRequests.add(data); // Ajoute à la liste des demandes d'amis
          } else if (data['type'] == 'like') {
            likes.add(data); // Ajoute à la liste des likes
          }
        }

        // Met à jour l'état avec les nouvelles listes de notifications
        setState(() {
          _friendRequests = friendRequests;
          _likes = likes;
        });
      });
    }
  }

  // Méthode pour accepter une demande d'ami
  void _acceptFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) {
      return; // Si aucun utilisateur n'est connecté, on quitte la méthode
    }

    try {
      // Ajouter l'ID de l'ami à la liste des amis de l'utilisateur actuel
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'friends': FieldValue.arrayUnion([fromUserId]),
      });

      // Ajouter l'ID de l'utilisateur actuel à la liste des amis de l'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'friends': FieldValue.arrayUnion([_user!.uid]),
      });

      // Supprimer la notification de demande d'ami de la collection des notifications de l'utilisateur actuel
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Supprimer la demande des demandes envoyées de l'expéditeur (ami)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Afficher un message de succès à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour rejeter une demande d'ami
  void _rejectFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) {
      return; // Si aucun utilisateur n'est connecté, on quitte la méthode
    }

    try {
      // Supprimer la notification de demande d'ami de la collection des notifications de l'utilisateur actuel
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Supprimer la demande des demandes envoyées de l'expéditeur (ami)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Afficher un message de refus à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request refused'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // Si aucun utilisateur n'est connecté, afficher un message
      return const Center(child: Text('User offline'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'), // Titre de la page
      ),
      body: ListView(
        children: [
          // Section des demandes d'amis
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Friend Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Si la liste des demandes d'amis est vide, afficher un message
          _friendRequests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No friend requests'),
                )
              : ListView.builder(
                  shrinkWrap:
                      true, // Pour que la liste prenne seulement l'espace nécessaire
                  physics:
                      const NeverScrollableScrollPhysics(), // Empêche le défilement indépendant
                  itemCount:
                      _friendRequests.length, // Nombre d'éléments dans la liste
                  itemBuilder: (context, index) {
                    // Construit chaque élément de la liste
                    Map<String, dynamic> notification = _friendRequests[index];
                    return Dismissible(
                      key: Key(notification[
                          'notificationId']), // Clé unique pour chaque élément
                      direction: DismissDirection
                          .endToStart, // Direction du glissement pour supprimer
                      onDismissed: (direction) {
                        setState(() {
                          _friendRequests.removeAt(
                              index); // Supprime l'élément de la liste locale
                        });
                        // Supprimer la notification de Firestore
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('notifications')
                            .doc(notification['notificationId'])
                            .delete();
                      },
                      background: Container(
                        color: Colors.red, // Couleur de fond lors du glissement
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white), // Icône de suppression
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16), // Marges autour de la carte
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: notification[
                                            'fromUserProfilePicture'] !=
                                        null &&
                                    notification['fromUserProfilePicture']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(
                                    notification['fromUserProfilePicture'])
                                : const NetworkImage(
                                    'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg'),
                          ), // Affiche la photo de profil de l'expéditeur
                          title: Text(
                              'Demande d\'ami de ${notification['fromUserName']}'), // Titre de la notification
                          subtitle: const Text(
                              'Souhaitez-vous accepter cette demande ?'), // Sous-titre ou message supplémentaire
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // Taille minimale pour le contenu
                            children: [
                              // Bouton pour accepter la demande d'ami
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptFriendRequest(
                                    notification['fromUserId'],
                                    notification['notificationId']),
                              ),
                              // Bouton pour rejeter la demande d'ami
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _rejectFriendRequest(
                                    notification['fromUserId'],
                                    notification['notificationId']),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          // Section des likes
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Likes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Si la liste des likes est vide, afficher un message
          _likes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No like'),
                )
              : ListView.builder(
                  shrinkWrap:
                      true, // Pour que la liste prenne seulement l'espace nécessaire
                  physics:
                      const NeverScrollableScrollPhysics(), // Empêche le défilement indépendant
                  itemCount: _likes.length, // Nombre d'éléments dans la liste
                  itemBuilder: (context, index) {
                    // Construit chaque élément de la liste
                    Map<String, dynamic> notification = _likes[index];
                    return Dismissible(
                      key: Key(notification[
                          'notificationId']), // Clé unique pour chaque élément
                      direction: DismissDirection
                          .endToStart, // Direction du glissement pour supprimer
                      onDismissed: (direction) {
                        setState(() {
                          _likes.removeAt(
                              index); // Supprime l'élément de la liste locale
                        });
                        // Supprimer la notification de Firestore
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('notifications')
                            .doc(notification['notificationId'])
                            .delete();
                      },
                      background: Container(
                        color: Colors.red, // Couleur de fond lors du glissement
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white), // Icône de suppression
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16), // Marges autour de la carte
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: notification[
                                            'fromUserProfilePicture'] !=
                                        null &&
                                    notification['fromUserProfilePicture']
                                        .toString()
                                        .isNotEmpty
                                ? NetworkImage(
                                    notification['fromUserProfilePicture'])
                                : const NetworkImage(
                                    'https://i.pinimg.com/736x/65/25/a0/6525a08f1df98a2e3a545fe2ace4be47.jpg'),
                          ), // Affiche la photo de profil de l'utilisateur qui a liké
                          title: Text(
                              '${notification['fromUserName']} a liké votre exploit'), // Titre de la notification
                          subtitle: notification['exploitName'] != null &&
                                  notification['exploitName']
                                      .toString()
                                      .isNotEmpty
                              ? Text(
                                  '${notification['fromUserName']} a liké "${notification['exploitName']}"')
                              : Text(
                                  '${notification['fromUserName']} a liké une de vos activités'), // Message supplémentaire
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
