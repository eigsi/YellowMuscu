import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    var snapshot = await _db.collection('users').doc(uid).get();
    return snapshot.data();
  }

  // Save user data to Firestore
  Future<void> saveUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }
}
