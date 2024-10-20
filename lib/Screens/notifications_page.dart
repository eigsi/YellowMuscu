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
          Map<String, dynamic> data = doc.data();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          // Partie des demandes d'amis
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Demandes d\'ami',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _friendRequests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Aucune demande d\'ami'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _friendRequests.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> notification = _friendRequests[index];
                    return Dismissible(
                      key: Key(notification['notificationId']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          _friendRequests.removeAt(index);
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
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
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
          // Partie des likes
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Likes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _likes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Aucune notification'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> notification = _likes[index];
                    return Dismissible(
                      key: Key(notification['notificationId']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        setState(() {
                          _likes.removeAt(index);
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
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
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
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
