import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
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

  int _selectedProfileImageIndex = 0; // Index for selected profile image

  // List of predefined profile image URLs
  final List<String> _profileImages = [
    'https://i.pinimg.com/564x/a4/54/16/a45416714096b6b224e939c2d1e6e842.jpg',
    'https://i.pinimg.com/564x/a0/02/78/a0027883fe995b3bf3b44d71b355f8a8.jpg',
    'https://i.pinimg.com/564x/99/dd/28/99dd28115c9a95b0c09813763a511aca.jpg',
    'https://i.pinimg.com/564x/7a/52/67/7a5267576242661fbe79954bea91946c.jpg',
    'https://i.pinimg.com/736x/02/4a/5b/024a5b0df5d2c2462ff8c73bebb418f3.jpg',
  ];

  void _signUp() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String uid = userCredential.user!.uid;

      // Store user data in Firestore including the selected profile image
      await _firestore.collection('users').doc(uid).set({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email': _emailController.text,
        'weight': _weightController.text,
        'height': _heightController.text,
        'dob': _dobController.text,
        'profile_image': _profileImages[
            _selectedProfileImageIndex], // Selected profile image URL
        'created_at': DateTime.now(),
      });

      Navigator.pushReplacementNamed(context, '/mainPage');
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightController,
                decoration: InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _dobController,
                decoration:
                    InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 20),

              // Section to select a profile picture
              const Text('Select a Profile Picture',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),

              // Make the row of images scrollable horizontally
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
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
