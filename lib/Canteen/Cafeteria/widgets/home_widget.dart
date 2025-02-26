import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Home', style: TextStyle(color: Colors.white))),
        backgroundColor: const Color(0xFF00122D),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color(0xFF00122D),
                    title: Text('Logout', 
                      style: TextStyle(color: Colors.white)
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70)
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', 
                          style: TextStyle(color: Colors.white70)
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pushReplacementNamed(context, '/loginPage');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error logging out. Please try again.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Text('Logout',
                          style: TextStyle(color: Colors.redAccent)
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            'Home controll page is here',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ),
      ),
    );
  }
}