// ignore: file_names
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:fluttertoast/fluttertoast.dart'; // For displaying toast messages
import 'package:orderq/Canteen/Cafeteria/cafHome.dart';
import 'package:orderq/Students/stuHome.dart';
import 'package:orderq/pages/Signupby.dart';
import 'HomePage.dart'; // Import the HomePage for successful login navigation
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key});


  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

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
                controller: emailController,
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
                controller: passwordController,
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final String email = emailController.text.trim();
                  final String password = passwordController.text.trim();

                  if (email.isEmpty || password.isEmpty) {
                    Fluttertoast.showToast(
                      msg: "Please fill in all fields",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                    return;
                  }

                  try {
                    // Attempt to sign in
                    UserCredential userCredential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    // If successful, navigate to HomePage
                    Fluttertoast.showToast(
                      msg: "Login successful!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );

                    route(context); // Call the route method after successful login

                  } on FirebaseAuthException catch (e) {
                    String errorMessage;
                    switch (e.code) {
                      case 'user-not-found':
                        errorMessage =
                            'No user found with this email. Please register first.';
                        break;
                      case 'wrong-password':
                        errorMessage = 'Incorrect password. Please try again.';
                        break;
                      default:
                        errorMessage = 'An error occurred. Please try again.';
                    }

                    // Display error message
                    Fluttertoast.showToast(
                      msg: errorMessage,
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    );
                  }
                },
                child: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53E3C6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to the Sign-Up page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Signupas(),
                    ),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void route(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        if (documentSnapshot.get('roll') == 'cafe') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin not approved yet, Please contact the admin'),
            ),
          );
        } else if (documentSnapshot.get('roll') == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StuHomePage(userId: documentSnapshot.id)),
            );
          
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CafHomePage(userId: documentSnapshot.id),
            ),
          );
        }
      } else {
        print('Document does not exist on the database');
      }
    });
  }
}