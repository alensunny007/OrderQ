import 'package:flutter/material.dart';
import 'package:orderq/utils/favour_data.dart'; // Adjust this import path according to your project structure

class FavoritesPage extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteItems;

  // Constructor for passing the favoriteItems list
  FavoritesPage({required this.favoriteItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: const Color(0xFF00122D),
      ),
      body: Container(
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
        child: favoriteItems.isEmpty
            ? const Center(
                child: Text(
                  "No favorites added yet!",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              )
            : ListView.builder(
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  final item = favoriteItems[index];
                  return Card(
                    color: const Color(0xFF12243A),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        item['title'],
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      subtitle: Text(
                        '₹${item['price']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
