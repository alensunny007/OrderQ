import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Total number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OrderQ'),
          backgroundColor: const Color(0xFF00122D), // Match AppBar theme
          bottom: const TabBar(
            indicatorColor: Color(0xFF53E3C6), // Highlight the selected tab
            labelColor: Color(0xFF53E3C6), // Color for the active tab
            unselectedLabelColor: Colors.white, // Color for inactive tabs
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'), // Current tab
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.shopping_cart), text: 'MyCart'),
              Tab(icon: Icon(Icons.favorite), text: 'Favourites'),
              Tab(icon: Icon(Icons.contact_mail), text: 'Contact Us'),
            ],
          ),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Explore The Possibilities of Varieties of Dishes',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
