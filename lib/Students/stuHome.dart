import 'package:flutter/material.dart';
import 'package:orderq/pages/studenthome/cart.dart';
import 'package:orderq/pages/studenthome/contact_us.dart';
import 'package:orderq/pages/studenthome/favourites.dart';
import 'package:orderq/pages/profile.dart';
import 'package:orderq/utils/food_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/daily_menu_service.dart';

class StuHomePage extends StatefulWidget {
  final dynamic userId;

  const StuHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<StuHomePage> createState() => _StuHomePageState();
}

class _StuHomePageState extends State<StuHomePage> {
  int _selectedIndex = 0;
  String selectedOption = 'Canteen';
  final PageController _pageController = PageController();
  final List<bool> _isInCart = List.generate(foodItems.length, (_) => false);
  final Map<String, bool> _favoriteStates = {};
  final DailyMenuService _menuService = DailyMenuService();
  List<Map<String, dynamic>> availableItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;

  @override
  void initState() {
    super.initState();
    _loadDailyMenu();
    _setupFavoritesListener();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDailyMenu() async {
    try {
      final menuItems = await _menuService.getDailyMenuItems(
          selectedOption.toLowerCase(), DateTime.now());

      setState(() {
        availableItems = menuItems;
      });
    } catch (e) {
      print('Error loading daily menu: $e');
      setState(() {
        availableItems = [];
      });
    }
  }

  void _setupFavoritesListener() {
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _favoriteStates.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _favoriteStates[data['itemId']] = true;
        }
      });
    });
  }

  Future<void> toggleFavorite(Map<String, dynamic> item, int index) async {
    try {
      final String userId = widget.userId;
      final String itemId =
          '${selectedOption.toLowerCase()}_${item['id'] ?? DateTime.now().toString()}';

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'title': item['title'],
          'price': item['price'],
          'imageUrl': item['imageUrl'],
          'description': item['description'],
          'dateAdded': DateTime.now(),
          'itemId': itemId,
          'source': selectedOption.toLowerCase(),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorites')),
      );
    }
  }

  Future<void> toggleCart(Map<String, dynamic> item, int index) async {
    try {
      final String userId = widget.userId;
      final String itemId = '${selectedOption.toLowerCase()}_${item['id']}';

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        setState(() => _isInCart[index] = false);
      } else {
        await docRef.set({
          'id': itemId,
          'title': item['title'],
          'price':
              double.parse(item['price'].toString()), // Ensure price is double
          'imageUrl': item['imageUrl'],
          'quantity': 1,
          'source': selectedOption.toLowerCase(),
        });
        setState(() => _isInCart[index] = true);
      }
    } catch (e) {
      print('Error toggling cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating cart')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00122D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Show confirmation dialog
              bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ) ??
                  false;

              if (confirm) {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Navigate to login page and remove all previous routes
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/loginPage', (route) => false);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error logging out. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomePage(),
          const ProfilePage(),
          CartPage(),
          Favourites(),
          const ContactUsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D),
        selectedItemColor: const Color(0xFF53E3C6),
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'MyCart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favourites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.contact_mail), label: 'Contact Us'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Hello, User",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton("Canteen"),
                  _buildOptionButton("Cafeteria"),
                ],
              ),
            ),
            _buildFoodGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = selectedOption == option;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedOption = option;
        });
        _loadDailyMenu(); // Reload menu when option changes
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.amber : Colors.white,
        foregroundColor: isSelected ? Colors.black : Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(option),
    );
  }

  Widget _buildFoodGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: availableItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu,
                      size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'No items available in ${selectedOption} today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final item = availableItems[index];
                return _buildFoodCard(item, index);
              },
            ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, int index) {
    final String itemId =
        '${selectedOption.toLowerCase()}_${item['id'] ?? DateTime.now().toString()}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      shadowColor: Colors.black45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  item['imageUrl'],
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              if (item['dateAdded'] != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Today's Special",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Title and Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${item['price']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Icons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Favorite and Cart icons
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _favoriteStates[itemId] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _favoriteStates[itemId] == true
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => toggleFavorite(item, index),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isInCart[index]
                                ? Icons.shopping_cart
                                : Icons.add_shopping_cart,
                            color: _isInCart[index] ? Colors.teal : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => toggleCart(item, index),
                        ),
                      ],
                    ),
                    // Info button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(item['title']),
                            content: Text(item['description'] ??
                                'No description available'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
