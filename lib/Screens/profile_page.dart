// profile_page.dart

// Importation des packages nécessaires pour Flutter et Firebase
import 'package:flutter/material.dart'; // Bibliothèque de widgets matériels de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'authentification Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour interagir avec la base de données Firestore

// Définition de la classe ProfilePage, un StatefulWidget pour afficher et modifier le profil utilisateur
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // Création de l'état associé à la classe ProfilePage
  _ProfilePageState createState() => _ProfilePageState();
}

// État associé à la classe ProfilePage
class _ProfilePageState extends State<ProfilePage> {
  // Instance de FirebaseAuth pour gérer l'authentification
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user; // Variable pour stocker l'utilisateur actuellement connecté
  bool _isEditing = false; // Indique si le mode édition est activé

  // Contrôleurs pour gérer les entrées de texte dans les TextFields
  final TextEditingController _lastNameController =
      TextEditingController(); // Contrôleur pour le nom de famille
  final TextEditingController _firstNameController =
      TextEditingController(); // Contrôleur pour le prénom
  final TextEditingController _weightController =
      TextEditingController(); // Contrôleur pour le poids
  final TextEditingController _heightController =
      TextEditingController(); // Contrôleur pour la taille
  final TextEditingController _birthdateController =
      TextEditingController(); // Contrôleur pour la date de naissance

  DateTime?
      _selectedBirthdate; // Variable pour stocker la date de naissance sélectionnée
  String _selectedProfilePicture = ''; // URL de la photo de profil sélectionnée

  // Listes pour stocker les données des utilisateurs, amis, et demandes d'amis
  List<Map<String, dynamic>> _allUsers = []; // Liste de tous les utilisateurs
  List<dynamic> _friends = []; // Liste des amis de l'utilisateur
  List<dynamic> _sentRequests = []; // Liste des demandes d'amis envoyées
  List<String> _receivedRequests = []; // Liste des demandes d'amis reçues

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser; // Récupère l'utilisateur actuellement connecté
    if (_user != null) {
      _fetchUserData(); // Récupère les données de l'utilisateur depuis Firestore
      _fetchReceivedFriendRequests(); // Récupère les demandes d'amis reçues
    }

    // Affiche un message si passé en paramètre lors de la navigation vers cette page
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

  // Méthode pour récupérer les données de l'utilisateur depuis Firestore
  void _fetchUserData() async {
    DocumentSnapshot userData = await FirebaseFirestore.instance
        .collection('users') // Accède à la collection 'users' dans Firestore
        .doc(_user!.uid) // Récupère le document de l'utilisateur actuel
        .get(); // Obtient les données du document

    if (userData.exists) {
      Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
      setState(() {
        // Met à jour les contrôleurs avec les données récupérées
        _lastNameController.text = data['last_name'] ?? '';
        _firstNameController.text = data['first_name'] ?? '';
        _weightController.text = data['weight'] ?? '';
        _heightController.text = data['height'] ?? '';
        _selectedProfilePicture = data['profilePicture'] ?? '';

        // Gère la date de naissance
        if (data['birthdate'] != null &&
            data['birthdate'].toString().isNotEmpty) {
          _selectedBirthdate = DateTime.parse(data['birthdate']);
          _birthdateController.text =
              '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}';
        } else {
          _selectedBirthdate = null;
          _birthdateController.text = '';
        }

        // Récupère la liste des amis et des demandes envoyées
        _friends = data['friends'] ?? [];
        _sentRequests = data['sentRequests'] ?? [];
      });
    }
  }

  // Méthode pour récupérer les demandes d'amis reçues
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

  // Méthode pour obtenir les données de l'utilisateur actuel
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

  // Méthode pour envoyer une demande d'ami
  void _sendFriendRequest(String friendId) async {
    if (_user == null) return;

    // Récupère les données de l'utilisateur actuel
    Map<String, dynamic> currentUserData = await _getCurrentUserData();
    String fromUserName =
        '${currentUserData['last_name'] ?? ''} ${currentUserData['first_name'] ?? ''}'
            .trim();
    String fromUserProfilePicture = currentUserData['profilePicture'] ?? '';

    // Vérifie si une demande a déjà été envoyée
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

    // Vérifie si une demande a été reçue de cet utilisateur
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

    // Ajoute la demande à la collection 'notifications' de l'utilisateur cible
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

    // Met à jour la liste des demandes envoyées de l'utilisateur actuel
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({
      'sentRequests': FieldValue.arrayUnion([friendId]),
    });

    setState(() {
      _sentRequests.add(friendId);
    });

    // Affiche un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'ami envoyée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Méthode pour enregistrer les modifications du profil
  void _saveProfile() async {
    // Récupère et valide les valeurs des champs
    String lastName = _lastNameController.text.trim();
    String firstName = _firstNameController.text.trim();
    int? weight = int.tryParse(_weightController.text.trim());
    int? height = int.tryParse(_heightController.text.trim());

    // Validations des champs
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
      // Met à jour les données de l'utilisateur dans Firestore
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
          _isEditing = false; // Désactive le mode édition
        });
        // Rafraîchit les données de l'utilisateur
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

  // Méthode pour afficher un message d'erreur
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Méthode pour déconnecter l'utilisateur
  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/signIn');
    }
  }

  // Méthode pour basculer le mode édition
  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Méthode pour supprimer le compte utilisateur
  void _deleteAccount() async {
    // Affiche une boîte de dialogue de confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le compte'),
          content: const Text(
              'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // L'utilisateur a annulé la suppression
    }

    // Optionnel : Demander à l'utilisateur de se ré-authentifier
    // Cela est recommandé pour des raisons de sécurité, surtout si l'authentification est ancienne
    // Vous pouvez implémenter une ré-authentification ici si nécessaire

    try {
      // Supprimer les données Firestore de l'utilisateur
      await _deleteUserData();

      // Supprimer l'utilisateur de Firebase Auth
      await _user!.delete();

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Après la suppression, afficher une boîte de dialogue pour choisir entre se connecter ou créer un compte
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Empêche la fermeture en tapant en dehors
          builder: (context) {
            return AlertDialog(
              title: const Text('Compte supprimé'),
              content: const Text(
                  'Votre compte a été supprimé. Que souhaitez-vous faire maintenant ?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue
                    Navigator.of(context).pushReplacementNamed(
                        '/signIn'); // Navigue vers la page de connexion
                  },
                  child: const Text('Se connecter'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme la boîte de dialogue
                    Navigator.of(context).pushReplacementNamed(
                        '/signUp'); // Navigue vers la page d'inscription
                  },
                  child: const Text('Créer un compte'),
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showError(
            'La suppression du compte a échoué. Veuillez vous reconnecter et réessayer.');
        // Optionnel : Naviguer vers la page de connexion pour ré-authentifier
        Navigator.of(context).pushReplacementNamed('/signIn');
      } else {
        _showError('La suppression du compte a échoué : ${e.message}');
      }
    } catch (e) {
      _showError('Une erreur est survenue : $e');
    }
  }

  // Méthode pour supprimer les données utilisateur de Firestore
  Future<void> _deleteUserData() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    // Supprimer les notifications de l'utilisateur
    QuerySnapshot notificationsSnapshot =
        await userRef.collection('notifications').get();

    for (var doc in notificationsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer le document utilisateur
    batch.delete(userRef);

    // Supprimer l'utilisateur de la liste des amis de tous les autres utilisateurs
    QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('friends', arrayContains: _user!.uid)
        .get();

    for (var doc in friendsSnapshot.docs) {
      DocumentReference docRef = doc.reference;
      batch.update(docRef, {
        'friends': FieldValue.arrayRemove([_user!.uid])
      });
    }

    // Supprimer l'utilisateur des demandes envoyées de tous les autres utilisateurs
    QuerySnapshot sentRequestsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('sentRequests', arrayContains: _user!.uid)
        .get();

    for (var doc in sentRequestsSnapshot.docs) {
      DocumentReference docRef = doc.reference;
      batch.update(docRef, {
        'sentRequests': FieldValue.arrayRemove([_user!.uid])
      });
    }

    // Supprimer les demandes reçues (notifications) de tous les autres utilisateurs
    // Si les demandes reçues sont stockées dans une sous-collection 'notifications', il faudrait les supprimer individuellement.
    // Cependant, cela peut être complexe et dépend de la structure exacte de vos notifications.

    // Note : Nous supprimons ici les références dans les 'friends' et 'sentRequests'.
    // Pour les notifications reçues, cela devrait être géré via Cloud Functions ou une autre logique appropriée.

    // Exécute le batch
    await batch.commit();
  }

  // Widget pour afficher la section "Ajouter des amis"
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

  // Widget pour construire l'affichage du profil
  Widget _buildProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Affichage de la photo de profil
        CircleAvatar(
          backgroundImage: NetworkImage(_selectedProfilePicture.isNotEmpty
              ? _selectedProfilePicture
              : 'https://i.pinimg.com/564x/17/da/45/17da453e3d8aa5e13bbb12c3b5bb7211.jpg'),
          radius: 50,
        ),
        const SizedBox(height: 16),
        // Affichage des champs du profil ou des champs éditables selon le mode
        _isEditing ? _buildEditableFields() : _buildDisplayFields(),
        const SizedBox(height: 16),
        // Boutons pour modifier le profil, enregistrer, se déconnecter et supprimer le compte
        Column(
          children: [
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
            const SizedBox(height: 16),
            // Bouton pour supprimer le compte (visible uniquement en mode affichage)
            if (!_isEditing)
              ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Supprimer le compte'),
              ),
          ],
        ),
        // Affiche la section "Ajouter des amis" si le mode édition est désactivé
        if (!_isEditing) _buildAddFriendsSection(),
      ],
    );
  }

  // Widget pour afficher les champs du profil en mode affichage
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

  // Widget pour afficher les champs du profil en mode édition
  Widget _buildEditableFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ pour le nom
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Nom'),
          maxLength: 15,
        ),
        const SizedBox(height: 8),
        // Champ pour le prénom
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'Prénom'),
          maxLength: 15,
        ),
        const SizedBox(height: 8),
        // Champ pour le poids
        TextField(
          controller: _weightController,
          decoration: const InputDecoration(labelText: 'Poids (kg)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        // Champ pour la taille
        TextField(
          controller: _heightController,
          decoration: const InputDecoration(labelText: 'Taille (cm)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        // Champ pour la date de naissance avec un sélecteur de date
        TextField(
          controller: _birthdateController,
          decoration: const InputDecoration(labelText: 'Date de naissance'),
          readOnly: true, // Rend le champ non modifiable manuellement
          onTap: () async {
            // Ouvre un sélecteur de date lorsque le champ est tapé
            FocusScope.of(context).requestFocus(FocusNode());
            DateTime initialDate = DateTime.now()
                .subtract(const Duration(days: 365 * 20)); // Date par défaut
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
        // Options pour sélectionner une photo de profil
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

  // Widget pour afficher une option de photo de profil
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

  // Widget pour afficher l'écran de connexion si l'utilisateur n'est pas connecté
  Widget _buildSignIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton pour se connecter
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/signIn');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[700],
            ),
            child: const Text('Se connecter'),
          ),
          // Bouton pour créer un compte
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
        // Dégradé de fond
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
