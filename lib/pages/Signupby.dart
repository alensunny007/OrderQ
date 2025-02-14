import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:orderq/Canteen/canSignup.dart';
import 'package:orderq/Students/signupwithcredentials.dart';

class Signupas extends StatelessWidget {
  const Signupas({super.key});

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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    Image.asset(
                      'assets/images/logo-orderq.png',
                      width: 180,
                      height: 180,
                    ),

                    const SizedBox(height: 80),

                    // Common button style
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        minWidth: 300,
                      ),
                      height: 65,
                      child: ElevatedButton(
                        onPressed: () => _navigateToNextScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53E3C6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Student',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Gap(30),

                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: 300,
                        minWidth: 300,
                      ),
                      height: 65,
                      child: ElevatedButton(
                        onPressed: () => _navigateToNextScreen2(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53E3C6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Canteen/Cafeteria',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => SignupWithCredentials()));
  }

  void _navigateToNextScreen2(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Cansignup()));
  }
}
