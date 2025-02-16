import 'package:flutter/material.dart';
import 'package:orderq/Students/cansignup.dart';

import 'package:orderq/pages/loginpage.dart';
 // Import the AuthService
import 'package:fluttertoast/fluttertoast.dart'; // Import the HomePage
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class SignupWithCredentials extends StatefulWidget {
  const SignupWithCredentials({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignupWithCredentialsState createState() => _SignupWithCredentialsState();
}

class _SignupWithCredentialsState extends State<SignupWithCredentials> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _Phoneno = TextEditingController();

  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00122D), // Dark blue
              Color(0xFF53E3C6), // Teal
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.name,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _universityIdController,
                decoration: InputDecoration(
                  labelText: 'University ID',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _Phoneno,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim();
                  final name = _fullNameController.text.trim();
                  final mobileNumber = _Phoneno.text.trim();
                  final universityId = _universityIdController.text.trim();

                  // Validate all fields
                  if (email.isEmpty ||
                      password.isEmpty ||
                      name.isEmpty ||
                      mobileNumber.isEmpty ||
                      universityId.isEmpty) {
                    Fluttertoast.showToast(
                      msg: 'Please fill in all fields.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                    return;
                  }

                  // Validate password length
                  if (password.length < 6) {
                    Fluttertoast.showToast(
                      msg: 'Password must be at least 6 characters long.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  try {
                    await _authService.signup(
                      email: email,
                      password: password,
                      context: context,
                    );

                    // If signup is successful, add user details to Firestore
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'name': name,
                        'email': email,
                        'mobileNumber': mobileNumber,
                        'universityId': universityId,
                        'role': 'student', // Changed from 'roll' to 'role'
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // Show success message
                      Fluttertoast.showToast(
                        msg: 'Signup successful!',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );

                      // Navigate to LoginPage
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                    }
                  } catch (e) {
                    Fluttertoast.showToast(
                      msg: 'Signup failed: ${e.toString()}',
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53E3C6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
