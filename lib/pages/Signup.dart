import 'package:flutter/material.dart';
import 'SignupWithCredentials.dart'; // Import the new page

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF00122D), // Match theme
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00122D),
              Color(0xFF53E3C6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to OrderQ!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupWithCredentials(),
                    ),
                  );
                },
                child: const Text('Sign Up'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF00122D), backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
