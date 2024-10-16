// notifications_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _likes = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      // Écouter les changements en temps réel dans les notifications
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        List<Map<String, dynamic>> friendRequests = [];
        List<Map<String, dynamic>> likes = [];

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['notificationId'] = doc.id;

          if (data['type'] == 'friendRequest') {
            friendRequests.add(data);
          } else if (data['type'] == 'like') {
            likes.add(data);
          }
        }

        setState(() {
          _friendRequests = friendRequests;
          _likes = likes;
        });
      });
    }
  }

  void _acceptFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) return;

    try {
      // Ajouter chacun aux listes d'amis de l'autre
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'friends': FieldValue.arrayUnion([fromUserId]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'friends': FieldValue.arrayUnion([_user!.uid]),
      });

      // Supprimer la demande d'ami de la collection des notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Supprimer la demande des demandes envoyées de l'expéditeur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ami accepté'),
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

  void _rejectFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) return;

    try {
      // Supprimer la demande d'ami de la collection des notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Supprimer la demande des demandes envoyées de l'expéditeur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Afficher un message de refus
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'ami refusée'),
          backgroundColor: Colors.red,
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
    if (_user == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Partie des demandes d'amis
              const Text(
                'Demandes d\'ami',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _friendRequests.isEmpty
                  ? const Text('Aucune demande d\'ami')
                  : Column(
                      children: _friendRequests.map((notification) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
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
                                      'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg'),
                            ),
                            title: Text(
                                'Demande d\'ami de ${notification['fromUserName']}'),
                            subtitle: const Text(
                                'Souhaitez-vous accepter cette demande ?'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  onPressed: () => _acceptFriendRequest(
                                      notification['fromUserId'],
                                      notification['notificationId']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => _rejectFriendRequest(
                                      notification['fromUserId'],
                                      notification['notificationId']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 16),
              // Partie des likes
              const Text(
                'Likes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _likes.isEmpty
                  ? const Text('Aucune notification')
                  : Column(
                      children: _likes.map((notification) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
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
                                      'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg'),
                            ),
                            title: Text(
                                '${notification['fromUserName']} a liké votre exploit'),
                            subtitle: notification['exploitName'] != null &&
                                    notification['exploitName']
                                        .toString()
                                        .isNotEmpty
                                ? Text(
                                    '${notification['fromUserName']} a liké "${notification['exploitName']}"')
                                : Text(
                                    '${notification['fromUserName']} a liké une de vos activités'),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Fermer'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  /// Fonction pour obtenir l'URL de la photo de profil d'un utilisateur.
  /// Si l'utilisateur n'a pas de photo de profil, retourne une image par défaut.
  String _getProfilePicture(String userId) {
    // Cette fonction suppose que vous avez une collection 'users' avec des documents utilisateur
    // contenant un champ 'profilePicture'. Vous pouvez la modifier en fonction de votre structure Firestore.
    // Pour simplifier, nous retournons une URL d'image par défaut ici.
    // Vous devriez implémenter une méthode pour récupérer dynamiquement l'image de profil de l'utilisateur.
    return 'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg';
  }
}
