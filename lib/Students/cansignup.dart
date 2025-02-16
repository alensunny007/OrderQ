import 'package:flutter/material.dart';

import 'package:orderq/pages/loginpage.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}

class Cansignup extends StatefulWidget {
  const Cansignup({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _Cansignup createState() => _Cansignup();
}

class _Cansignup extends State<Cansignup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneno = TextEditingController();

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
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // This will stretch children horizontally
              children: [
                const SizedBox(height: 60), // Add top spacing
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
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
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
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
                    fillColor: Colors.white.withAlpha(25),
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
                  controller: _phoneno,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(25),
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
                    final mobileNumber = _phoneno.text.trim();

                    if (email.isEmpty ||
                        password.isEmpty ||
                        name.isEmpty ||
                        mobileNumber.isEmpty) {
                      Fluttertoast.showToast(
                        msg: 'Please fill in all fields.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.black54,
                        textColor: Colors.white,
                        fontSize: 14.0,
                      );
                      return;
                    }

                    try {
                      final navigator = Navigator.of(context);
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
                          'roll': 'Cafe',
                        });
                      }

                      // Navigate to HomePage only if widget is still mounted
                      if (mounted) {
                        navigator.pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Signup failed: $e',
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
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
      ),
    );
  }
}
