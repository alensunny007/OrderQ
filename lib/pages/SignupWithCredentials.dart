import 'package:flutter/material.dart';

class SignupWithCredentials extends StatelessWidget {
  const SignupWithCredentials({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up with Credentials'),
        backgroundColor: const Color(0xFF00122D), // Match AppBar theme
      ),
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
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF53E3C6)),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF53E3C6)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF53E3C6)),
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Handle sign-up logic here
                },
                child: const Text('Sign Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53E3C6), // Match button color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 24), // Button padding
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
