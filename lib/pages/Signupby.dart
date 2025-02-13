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
        child: Stack(
          children: [
            // Top Corner Logo
            Positioned(
              top: 45,
              right: 20,
              child: Image.asset(
                'assets/images/logo-orderq.png',
                width: 100,
              ),
            ),

            // Centered Content
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Student Button
                    Container(
                      width: 300,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToNextScreen(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: const Color(0xFF53E3C6), // Using theme teal color
                          elevation: 0,
                        ),
                        child: Row(
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

                    // Canteen/Cafeteria Button
                    Container(
                      width: 300,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToNextScreen2(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.2), // Semi-transparent white
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups,
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
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupWithCredentials()));
  }

  void _navigateToNextScreen2(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Cansignup()));
  }
}