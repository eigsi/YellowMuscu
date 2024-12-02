// lib/authentication/sign_up_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellowmuscu/tutorial/tutorial_page.dart'; // Import the TutorialPage

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  int _selectedProfileImageIndex = 0; // Index of the selected profile image

  // List of predefined profile image URLs
  final List<String> _profileImages = [
    'https://i.pinimg.com/564x/a4/54/16/a45416714096b6b224e939c2d1e6e842.jpg',
    'https://i.pinimg.com/564x/a0/02/78/a0027883fe995b3bf3b44d71b355f8a8.jpg',
    'https://i.pinimg.com/564x/99/dd/28/99dd28115c9a95b0c09813763a511aca.jpg',
    'https://i.pinimg.com/564x/7a/52/67/7a5267576242661fbe79954bea91946c.jpg',
    'https://i.pinimg.com/736x/02/4a/5b/024a5b0df5d2c2462ff8c73bebb418f3.jpg',
  ];

  DateTime? _selectedBirthdate;

  void _signUp() async {
    // Validate all fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _dobController.text.isEmpty) {
      _showError('Please fill in all the fields.');
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Store user data in Firestore
      await _firestore.collection('users').doc(uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'weight': double.parse(_weightController.text.trim()),
        'height': double.parse(_heightController.text.trim()),
        'birthdate': _selectedBirthdate?.toIso8601String() ?? '',
        'profilePicture': _profileImages[
            _selectedProfileImageIndex], // URL of the selected profile picture
        'created_at': Timestamp.now(),
        'friends': [], // Initialize friends list
        'sentRequests': [], // Initialize sent requests list
        'streakCount': 0, // Initialize streak count
        'lastStreakDate':
            Timestamp.fromDate(DateTime(1970)), // Initialize last streak date
        'completedSessions': [], // Initialize completed sessions list
      });

      // Redirect to the TutorialPage
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => const TutorialPage(),
        ),
      );
    } catch (e) {
      _showError('Error while creating the account. Please try again.');
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

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 20));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthdate = pickedDate;
        _dobController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers when no longer needed
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // First Name Field
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              // Last Name Field
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              // Weight Field
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              // Height Field
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
              ),
              // Birthdate Field with Calendar
              GestureDetector(
                onTap: () => _selectBirthdate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Birthdate',
                      hintText: 'DD/MM/YYYY',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Picture Selection Section
              const Text('Select a Profile Picture',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),

              // Horizontally scrollable profile images
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_profileImages.length, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProfileImageIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedProfileImageIndex == index
                                ? Colors.yellow
                                : Colors.transparent,
                            width: 3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(_profileImages[index]),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
