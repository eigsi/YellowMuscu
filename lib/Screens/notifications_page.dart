// notifications_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<Map<String, dynamic>> _notifications = [];

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

    setState(() {
      _notifications = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['notificationId'] = doc.id;
        return data;
      }).toList();
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

    _fetchNotifications();
  }

  void _rejectFriendRequest(String notificationId) async {
    if (_user == null) return;

    // Supprimer la demande d'ami
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();

    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: double.maxFinite,
        child: _notifications.isEmpty
            ? const Text('Aucune nouvelle notification')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  if (notification['type'] == 'friendRequest') {
                    return ListTile(
                      title: Text(
                          'Demande d\'ami de ${notification['fromUserName']}'),
                      subtitle: Text('Souhaitez-vous accepter cette demande ?'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptFriendRequest(
                                notification['fromUserId'],
                                notification['notificationId']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectFriendRequest(
                                notification['notificationId']),
                          ),
                        ],
                      ),
                    );
                  } else if (notification['type'] == 'like') {
                    return ListTile(
                      title: const Text('Nouveau like'),
                      subtitle: Text(
                          'Votre activité a été likée par ${notification['fromUserName']}'),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
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
