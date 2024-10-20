// profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isEditing = false;
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  DateTime? _selectedBirthdate;
  String _selectedProfilePicture = '';
  List<Map<String, dynamic>> _allUsers = [];
  List<dynamic> _friends = [];
  List<dynamic> _sentRequests = [];
  List<String> _receivedRequests = [];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserData();
      _fetchReceivedFriendRequests();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final message = ModalRoute.of(context)?.settings.arguments as String?;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _fetchUserData() async {
    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (userData.exists) {
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      setState(() {
        _lastNameController.text = data['last_name'] ?? '';
        _firstNameController.text = data['first_name'] ?? '';
        _weightController.text = data['weight'] ?? '';
        _heightController.text = data['height'] ?? '';
        _selectedProfilePicture = data['profilePicture'] ?? '';

        if (data['birthdate'] != null &&
            data['birthdate'].toString().isNotEmpty) {
          _selectedBirthdate = DateTime.parse(data['birthdate']);
          _birthdateController.text =
              '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}';
        } else {
          _selectedBirthdate = null;
          _birthdateController.text = '';
        }

        _friends = data['friends'] ?? [];
        _sentRequests = data['sentRequests'] ?? [];
      });
    }
  }

  void _fetchReceivedFriendRequests() async {
    if (_user == null) return;

    QuerySnapshot notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'friendRequest')
        .get();

    List<String> receivedRequests = notificationsSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['fromUserId'] as String;
    }).toList();

    setState(() {
      _receivedRequests = receivedRequests;
    });
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    if (_user == null) {
      return {'last_name': '', 'first_name': '', 'profilePicture': ''};
    }

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      return {'last_name': '', 'first_name': '', 'profilePicture': ''};
    }
  }

  void _sendFriendRequest(String friendId) async {
    if (_user == null) return;

    // Récupérer le nom complet et la photo de profil de l'utilisateur actuel
    Map<String, dynamic> currentUserData = await _getCurrentUserData();
    String fromUserName =
        '${currentUserData['last_name'] ?? ''} ${currentUserData['first_name'] ?? ''}'
            .trim();
    String fromUserProfilePicture = currentUserData['profilePicture'] ?? '';

    // Vérifier si une demande a déjà été envoyée
    if (_sentRequests.contains(friendId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vous avez déjà envoyé une demande d\'ami à cet utilisateur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifier si une demande a été reçue de cet utilisateur
    if (_receivedRequests.contains(friendId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vous avez déjà une demande d\'ami en attente de cet utilisateur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Ajouter la demande à la collection 'notifications' de l'utilisateur cible
    await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .collection('notifications')
        .add({
      'type': 'friendRequest',
      'fromUserId': _user!.uid,
      'fromUserName': fromUserName,
      'fromUserProfilePicture': fromUserProfilePicture,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Mettre à jour la liste des demandes envoyées
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({
      'sentRequests': FieldValue.arrayUnion([friendId]),
    });

    setState(() {
      _sentRequests.add(friendId);
    });

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'ami envoyée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveProfile() async {
    // Validations
    String lastName = _lastNameController.text.trim();
    String firstName = _firstNameController.text.trim();
    int? weight = int.tryParse(_weightController.text.trim());
    int? height = int.tryParse(_heightController.text.trim());

    if (lastName.length > 15) {
      _showError('Le nom ne doit pas dépasser 15 caractères.');
      return;
    }

    if (firstName.length > 15) {
      _showError('Le prénom ne doit pas dépasser 15 caractères.');
      return;
    }

    if (weight == null || weight < 0 || weight > 200) {
      _showError('Le poids doit être un entier entre 0 et 200.');
      return;
    }

    if (height == null || height < 0 || height > 250) {
      _showError('La taille doit être un entier entre 0 et 250.');
      return;
    }

    if (_user != null) {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'last_name': lastName,
        'first_name': firstName,
        'weight': weight.toString(),
        'height': height.toString(),
        'birthdate': _selectedBirthdate?.toIso8601String() ?? '',
        'profilePicture': _selectedProfilePicture,
        'email': _user!.email,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        // Fetch updated data
        _fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/signIn');
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Widget _buildAddFriendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Ajouter des amis',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            List<DocumentSnapshot> usersDocs = snapshot.data!.docs;
            _allUsers = usersDocs
                .map((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  return {
                    'uid': doc.id,
                    'last_name': data['last_name'] ?? '',
                    'first_name': data['first_name'] ?? '',
                    'profilePicture': data['profilePicture'] ?? '',
                  };
                })
                .where((user) => user['uid'] != _user!.uid)
                .toList();

            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  bool isFriend = _friends.contains(user['uid']);
                  bool requestSent = _sentRequests.contains(user['uid']);
                  bool requestReceived =
                      _receivedRequests.contains(user['uid']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['profilePicture']),
                    ),
                    title: Text('${user['last_name']} ${user['first_name']}'),
                    trailing: isFriend
                        ? const Text('Ami')
                        : requestSent
                            ? const Text('Demande envoyée')
                            : requestReceived
                                ? const Text('Demande reçue')
                                : ElevatedButton(
                                    onPressed: () =>
                                        _sendFriendRequest(user['uid']),
                                    child: const Text('Ajouter'),
                                  ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(_selectedProfilePicture.isNotEmpty
              ? _selectedProfilePicture
              : 'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg'),
          radius: 50,
        ),
        const SizedBox(height: 16),
        _isEditing ? _buildEditableFields() : _buildDisplayFields(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _toggleEditing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
              ),
              child: Text(_isEditing ? 'Annuler' : 'Modifier le profil'),
            ),
            _isEditing
                ? ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Enregistrer'),
                  )
                : ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Se déconnecter'),
                  ),
          ],
        ),
        if (!_isEditing) _buildAddFriendsSection(),
      ],
    );
  }

  Widget _buildDisplayFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom : ${_lastNameController.text}',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Prénom : ${_firstNameController.text}',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Poids : ${_weightController.text} kg',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Taille : ${_heightController.text} cm',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Date de naissance : ${_birthdateController.text}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text('Email : ${_user?.email ?? 'Non défini'}',
            style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Nom'),
          maxLength: 15,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'Prénom'),
          maxLength: 15,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: 'Poids (kg)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _heightController,
          decoration: const InputDecoration(labelText: 'Taille (cm)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _birthdateController,
          decoration: const InputDecoration(labelText: 'Date de naissance'),
          readOnly: true,
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            DateTime initialDate =
                DateTime.now().subtract(const Duration(days: 365 * 20));
            if (_selectedBirthdate != null) {
              initialDate = _selectedBirthdate!;
            }
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              _selectedBirthdate = pickedDate;
              _birthdateController.text =
                  '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('Photo de profil :', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildProfilePictureOption(
                      'https://i.pinimg.com/564x/a4/54/16/a45416714096b6b224e939c2d1e6e842.jpg'),
                  _buildProfilePictureOption(
                      'https://i.pinimg.com/564x/a0/02/78/a0027883fe995b3bf3b44d71b355f8a8.jpg'),
                  _buildProfilePictureOption(
                      'https://i.pinimg.com/564x/99/dd/28/99dd28115c9a95b0c09813763a511aca.jpg'),
                  _buildProfilePictureOption(
                      'https://i.pinimg.com/564x/7a/52/67/7a5267576242661fbe79954bea91946c.jpg'),
                  _buildProfilePictureOption(
                      'https://i.pinimg.com/736x/02/4a/5b/024a5b0df5d2c2462ff8c73bebb418f3.jpg'),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 4,
                child: Container(
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfilePictureOption(String imageUrl) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProfilePicture = imageUrl;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedProfilePicture == imageUrl
                ? Colors.green
                : Colors.transparent,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          radius: 30,
        ),
      ),
    );
  }

  Widget _buildSignIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signIn');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
            ),
            child: const Text('Se connecter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signUp');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromRGBO(255, 204, 0, 1.0),
                const Color.fromRGBO(255, 204, 0, 1.0).withOpacity(0.3),
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isEditing
              ? AppBar(
                  title: const Text('Modifier le profil'),
                )
              : null,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _user == null ? _buildSignIn() : _buildProfile(),
            ),
          ),
        ),
      ],
    );
  }
}
