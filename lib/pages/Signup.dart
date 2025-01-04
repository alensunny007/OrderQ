import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF00122D), // Dark blue to match the gradient theme
      ),
      body: Container(
        width: double.infinity, // Ensure the background covers the entire screen
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00122D), // Dark blue from the gradient
              Color(0xFF53E3C6), // Teal from the gradient
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
                  color: Colors.white, // Ensure the text is visible on the gradient
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add functionality for the sign-up process
                },
                child: const Text('Sign Up'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF00122D), backgroundColor: Colors.white, // Button text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
