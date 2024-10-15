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
      _fetchNotifications();
    }
  }

  void _fetchNotifications() async {
    if (_user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

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
  }

  void _acceptFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) return;

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

    // Supprimer la demande d'ami
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

    // Afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ami accepté'),
        backgroundColor: Colors.green,
      ),
    );

    _fetchNotifications();
  }

  void _rejectFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) return;

    // Supprimer la demande d'ami
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

    // Afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'ami refusée'),
        backgroundColor: Colors.red,
      ),
    );

    _fetchNotifications();
  }

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    String lastName = data['last_name'] ?? '';
    String firstName = data['first_name'] ?? '';
    return '$lastName $firstName';
  }

  @override
  Widget build(BuildContext context) {
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
                        return FutureBuilder<String>(
                          future: _getUserName(notification['fromUserId']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            String friendName = snapshot.data!;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text(friendName),
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
                          },
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
                        return FutureBuilder<String>(
                          future: _getUserName(notification['fromUserId']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            String friendName = snapshot.data!;
                            String description =
                                notification['description'] ?? 'votre exploit';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text('$friendName a liké $description'),
                              ),
                            );
                          },
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
}
