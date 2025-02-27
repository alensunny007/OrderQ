import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orderq/Canteen/Cafeteria/caf_home.dart';
import 'package:orderq/Students/stuhome.dart';
import 'package:orderq/superadmin/super_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
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
                    // Add the sign-in attempt
                    await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
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

                    if (context.mounted) {
                      route(context);
                    }
                  } on auth.FirebaseAuthException catch (e) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53E3C6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to the Sign-Up page
                  Navigator.pushReplacementNamed(context, '/signupPage');
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
    auth.User? user = auth.FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        String userRole = documentSnapshot.get('role') as String;

        switch (userRole) {
          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CafHomePage(userId: documentSnapshot.id),
              ),
            );
            break;

          case 'student':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StuHomePage(userId: documentSnapshot.id),
              ),
            );
            break;

          case 'super':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SuperHome(userId: documentSnapshot.id),
              ),
            );
            break;

          default:
            Fluttertoast.showToast(
              msg: "Invalid user role: $userRole",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
            );
        }
      } else {
        Fluttertoast.showToast(
          msg: "User profile not found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        );
      }
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "Error: ${error.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
      );
    });
  }
}