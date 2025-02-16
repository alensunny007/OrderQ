import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteItems;

  const FavoritesPage({super.key, required this.favoriteItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF53E3C6),
              Color(0xFF00122D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Favourites",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: favoriteItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(favoriteItems[index]['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      title: Text(favoriteItems[index]['title']),
                      subtitle: Text("₹${favoriteItems[index]['price']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Logic for removing items
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
