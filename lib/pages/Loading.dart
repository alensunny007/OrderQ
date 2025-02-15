import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to the SignUpPage after a delay
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
        context,
        '/loginPage',
      );
    });
  }

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Image.asset(
                'assets/images/logo-orderq.png', // Replace with your actual logo path
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20), // Spacing below the logo
              const Text(
                'OrderQ', // App title
                style: TextStyle(
                  fontSize: 36, // Large font size
                  fontWeight: FontWeight.bold, // Bold text
                  color: Colors.white, // White color for contrast
                  letterSpacing: 2.0, // Optional spacing for elegance
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
