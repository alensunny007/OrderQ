import 'package:flutter/material.dart';
import 'package:gap/gap.dart'; // Ensure this package is added to your pubspec.yaml
import 'package:orderq/Canteen/canSignup.dart';
import 'package:orderq/Students/signupwithcredentials.dart';
import 'package:orderq/pages/signup.dart';


class Signupas extends StatelessWidget {
  const Signupas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.white,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Top Corner Logo
            Positioned(
              top: 45,
              right: 20,
              child: Image.asset(
                'assets/images/logo-orderq.png',
                width: 100, // Adjust size as needed
              ),
            ),

            // Centered Content
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User Button
                    Container(
                      child: Material(
                        elevation: 0, // Remove elevation
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
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
                              backgroundColor: Colors.black, // Set button color to black
                              elevation: 0, // Remove button elevation
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
                      ),
                    ),

                    const Gap(30),

                    // Organization Button
                    Container(
                      child: Material(
                        elevation: 0, // Remove elevation
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
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
                              backgroundColor: Colors.black, // Set button color to black
                              elevation: 0, // Remove button elevation
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
