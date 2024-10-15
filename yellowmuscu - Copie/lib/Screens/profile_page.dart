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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  String _selectedProfilePicture = '';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserData();
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
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _surnameController.text = userData['surname'] ?? '';
        _weightController.text = userData['weight'] ?? '';
        _heightController.text = userData['height'] ?? '';
        _birthdateController.text = userData['birthdate'] ?? '';
        _selectedProfilePicture = userData['profilePicture'] ?? '';
      });
    }
  }

  void _saveProfile() async {
    // Validations
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    int? weight = int.tryParse(_weightController.text.trim());
    int? height = int.tryParse(_heightController.text.trim());

    if (name.length > 15) {
      _showError('Le nom ne doit pas dépasser 15 caractères.');
      return;
    }

    if (surname.length > 15) {
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
        'name': name,
        'surname': surname,
        'weight': weight.toString(),
        'height': height.toString(),
        'birthdate': _birthdateController.text,
        'profilePicture': _selectedProfilePicture,
        'email': _user!.email,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    DateTime date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
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

  Widget _buildProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(_selectedProfilePicture.isNotEmpty
              ? _selectedProfilePicture
              : 'https://example.com/default_profile_picture.png'),
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
      ],
    );
  }

  Widget _buildDisplayFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nom : ${_nameController.text}',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Prénom : ${_surnameController.text}',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Poids : ${_weightController.text} kg',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('Taille : ${_heightController.text} cm',
            style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Date de naissance : ${_formatDate(_birthdateController.text)}',
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
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom'),
          maxLength: 15,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _surnameController,
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
            DateTime initialDate = DateTime.now();
            if (_birthdateController.text.isNotEmpty) {
              initialDate = DateTime.parse(_birthdateController.text);
            }
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              _birthdateController.text = pickedDate.toIso8601String();
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
}
