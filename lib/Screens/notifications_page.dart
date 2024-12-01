// notifications_page.dart

// Import necessary packages for Flutter and Firebase
import 'package:flutter/material.dart'; // Flutter material widgets library
import 'package:cloud_firestore/cloud_firestore.dart'; // For interacting with Firestore database
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase authentication

// Define the NotificationsPage class, which is a StatefulWidget
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

// State associated with the NotificationsPage class
class NotificationsPageState extends State<NotificationsPage> {
  // Instance of FirebaseAuth to manage authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable to store the currently logged-in user
  List<Map<String, dynamic>> _friendRequests = []; // List of friend requests
  List<Map<String, dynamic>> _likes = []; // List of received likes

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Get the currently logged-in user
    if (_user != null) {
      // If the user is logged in, listen to real-time changes in notifications
      FirebaseFirestore.instance
          .collection('users') // Access the 'users' collection in Firestore
          .doc(_user!.uid) // Access the current user's document
          .collection(
              'notifications') // Access the 'notifications' subcollection
          .orderBy('timestamp',
              descending: true) // Order notifications by descending date
          .snapshots() // Get a real-time stream of data
          .listen((snapshot) {
        // Listen to changes in notifications
        List<Map<String, dynamic>> friendRequests =
            []; // Temporary list for friend requests
        List<Map<String, dynamic>> likes = []; // Temporary list for likes

        // Iterate over each notification document
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data =
              doc.data(); // Get the data from the document
          data['notificationId'] = doc.id; // Add the document ID to the data

          // Sort notifications based on their type
          if (data['type'] == 'friendRequest') {
            friendRequests.add(data); // Add to the list of friend requests
          } else if (data['type'] == 'like') {
            likes.add(data); // Add to the list of likes
          }
        }

        // Update the state with the new notification lists
        setState(() {
          _friendRequests = friendRequests;
          _likes = likes;
        });
      });
    }
  }

  // Method to accept a friend request
  void _acceptFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) {
      return; // If no user is logged in, exit the method
    }

    try {
      // Add the friend's ID to the current user's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'friends': FieldValue.arrayUnion([fromUserId]),
      });

      // Add the current user's ID to the friend's friends list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'friends': FieldValue.arrayUnion([_user!.uid]),
      });

      // Delete the friend request notification from the current user's notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Remove the request from the sender's sentRequests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // In case of an error, display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting friend request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to reject a friend request
  void _rejectFriendRequest(String fromUserId, String notificationId) async {
    if (_user == null) {
      return; // If no user is logged in, exit the method
    }

    try {
      // Delete the friend request notification from the current user's notifications
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Remove the request from the sender's sentRequests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId)
          .update({
        'sentRequests': FieldValue.arrayRemove([_user!.uid]),
      });

      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request declined'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // In case of an error, display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining friend request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // If no user is logged in, display a message
      return const Center(child: Text('User offline'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'), // Page title
      ),
      body: ListView(
        children: [
          // Friend Requests section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Friend Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // If the list of friend requests is empty, display a message
          _friendRequests.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No friend requests'),
                )
              : ListView.builder(
                  shrinkWrap: true, // Only take up necessary space
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable independent scrolling
                  itemCount:
                      _friendRequests.length, // Number of items in the list
                  itemBuilder: (context, index) {
                    // Build each item in the list
                    Map<String, dynamic> notification = _friendRequests[index];
                    return Dismissible(
                      key: Key(notification[
                          'notificationId']), // Unique key for each item
                      direction: DismissDirection
                          .endToStart, // Swipe to delete direction
                      onDismissed: (direction) {
                        setState(() {
                          _friendRequests.removeAt(
                              index); // Remove the item from the local list
                        });
                        // Delete the notification from Firestore
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('notifications')
                            .doc(notification['notificationId'])
                            .delete();
                      },
                      background: Container(
                        color: Colors.red, // Background color when swiping
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white), // Delete icon
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Card margins
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
                          ), // Display the sender's profile picture
                          title: Text(
                              'Friend request from ${notification['fromUserName']}'), // Notification title
                          subtitle: const Text(
                              'Do you want to accept this request?'), // Additional message
                          trailing: Row(
                            mainAxisSize: MainAxisSize
                                .min, // Minimize size to fit content
                            children: [
                              // Button to accept the friend request
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptFriendRequest(
                                    notification['fromUserId'],
                                    notification['notificationId']),
                              ),
                              // Button to reject the friend request
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
          // Likes section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Likes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // If the list of likes is empty, display a message
          _likes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('No likes'),
                )
              : ListView.builder(
                  shrinkWrap: true, // Only take up necessary space
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable independent scrolling
                  itemCount: _likes.length, // Number of items in the list
                  itemBuilder: (context, index) {
                    // Build each item in the list
                    Map<String, dynamic> notification = _likes[index];
                    return Dismissible(
                      key: Key(notification[
                          'notificationId']), // Unique key for each item
                      direction: DismissDirection
                          .endToStart, // Swipe to delete direction
                      onDismissed: (direction) {
                        setState(() {
                          _likes.removeAt(
                              index); // Remove the item from the local list
                        });
                        // Delete the notification from Firestore
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('notifications')
                            .doc(notification['notificationId'])
                            .delete();
                      },
                      background: Container(
                        color: Colors.red, // Background color when swiping
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white), // Delete icon
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Card margins
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
                          ), // Display the user's profile picture who liked
                          title: Text(
                              '${notification['fromUserName']} liked your activity'), // Notification title
                          subtitle: notification['description'] != null &&
                                  notification['description']
                                      .toString()
                                      .isNotEmpty
                              ? Text(notification['description'])
                              : Text(
                                  '${notification['fromUserName']} liked one of your activities'), // Additional message
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
