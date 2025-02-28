import 'package:flutter/material.dart';
import 'package:orderq/pages/studenthome/cart.dart';
import 'package:orderq/pages/studenthome/contact_us.dart';
import 'package:orderq/pages/studenthome/favourites.dart';
import 'package:orderq/pages/profile.dart';
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
  List<bool> _isInCart = [];  // Initialize as empty list
  final Map<String, bool> _favoriteStates = {};
  final DailyMenuService _menuService = DailyMenuService();
  List<Map<String, dynamic>> availableItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  StreamSubscription<QuerySnapshot>? _cartSubscription;
  final Map<String, List<bool>> _cartStates = {
    'canteen': [],
    'cafeteria': [],
  };
  
  // Add variables for user data
  String name = "User"; // Default value
  bool _isLoadingUserData = false; // Start with false to prevent initial loading

  @override
  void initState() {
    super.initState();
    // Set loading to true right before fetching
    setState(() {
      _isLoadingUserData = true;
    });
    _loadUserData(); // Add this method call to fetch user data
    _loadDailyMenu();
    _setupFavoritesListener();
    _setupCartListener();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _cartSubscription?.cancel();
    super.dispose();
  }
  
  // Method to load user data from Firestore
  Future<void> _loadUserData() async {
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 3), () {
      if (_isLoadingUserData) {
        setState(() {
          _isLoadingUserData = false;
          // If loading takes too long, use the default name
        });
      }
    });
    
    try {
      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        // Extract name from the document data
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        
        if (userData != null && userData.containsKey('name')) {
          setState(() {
            name = userData['name'];
            _isLoadingUserData = false;
          });
        } else {
          setState(() {
            _isLoadingUserData = false;
            // Keep default name if 'name' field doesn't exist
          });
        }
      } else {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadDailyMenu() async {
    try {
      final menuItems = await _menuService.getDailyMenuItems(
          selectedOption.toLowerCase(), DateTime.now());

      setState(() {
        availableItems = menuItems;
        // Update _isInCart length to match availableItems
        _isInCart = List.generate(availableItems.length, (_) => false);
      });
    } catch (e) {
      print('Error loading daily menu: $e');
      setState(() {
        availableItems = [];
        _isInCart = []; // Clear the list when there are no items
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

  void _setupCartListener() {
    _cartSubscription = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        // Make sure _cartStates lists match the current availableItems length
        _cartStates['canteen'] = List.generate(availableItems.length, (_) => false);
        _cartStates['cafeteria'] = List.generate(availableItems.length, (_) => false);

        // Update cart states based on Firestore data
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final itemId = data['id'] as String;
          final itemSource = data['source'] as String;

          final index = availableItems.indexWhere((item) {
            String currentItemId = '${itemSource}_${item['id']}';
            return currentItemId == itemId;
          });

          if (index != -1 && index < availableItems.length) {
            // Add bounds checking to prevent out of range errors
            if (_cartStates.containsKey(itemSource) && 
                _cartStates[itemSource] != null && 
                index < _cartStates[itemSource]!.length) {
              _cartStates[itemSource]![index] = true;
            }
          }
        }

        // Update the current view's cart state with bounds checking
        String source = selectedOption.toLowerCase();
        if (_cartStates.containsKey(source) && _cartStates[source] != null) {
          // Only update if lengths match to prevent range errors
          if (_cartStates[source]!.length == availableItems.length) {
            _isInCart = List.from(_cartStates[source]!);
          } else {
            // Recreate _isInCart with the correct length
            _isInCart = List.generate(availableItems.length, (_) => false);
            
            // Copy values where possible
            int minLength = _isInCart.length < _cartStates[source]!.length 
                ? _isInCart.length 
                : _cartStates[source]!.length;
                
            for (int i = 0; i < minLength; i++) {
              _isInCart[i] = _cartStates[source]![i];
            }
          }
        } else {
          _isInCart = List.generate(availableItems.length, (_) => false);
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
    // Check bounds before proceeding
    if (index >= availableItems.length || index >= _isInCart.length) {
      print('Error: Index out of bounds in toggleCart');
      return;
    }
    
    try {
      final String userId = widget.userId;
      final String source = selectedOption.toLowerCase();
      final String itemId = '${source}_${item['id']}';

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        setState(() {
          // Safely update the cart states with bounds checking
          if (_cartStates.containsKey(source) && 
              _cartStates[source] != null && 
              index < _cartStates[source]!.length) {
            _cartStates[source]![index] = false;
          }
          
          if (index < _isInCart.length) {
            _isInCart[index] = false;
          }
        });
      } else {
        await docRef.set({
          'id': itemId,
          'title': item['title'],
          'price': double.parse(item['price'].toString()),
          'imageUrl': item['imageUrl'],
          'quantity': 1,
          'source': source,
        });
        setState(() {
          // Safely update the cart states with bounds checking
          if (_cartStates.containsKey(source) && 
              _cartStates[source] != null && 
              index < _cartStates[source]!.length) {
            _cartStates[source]![index] = true;
          }
          
          if (index < _isInCart.length) {
            _isInCart[index] = true;
          }
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} added to cart'),
            backgroundColor: Color(0xFF53E3C6),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                _onItemTapped(2); // Navigate to cart page
              },
            ),
          ),
        );
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

  void _updateSelectedOption(String option) {
    setState(() {
      selectedOption = option;
    });
    _loadDailyMenu(); // This will update availableItems and _isInCart
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          const CartPage(),
          const Favourites(),
          const ContactUsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D), // Restored original dark blue background
        selectedItemColor: const Color(0xFF53E3C6), // Teal for selected items
        unselectedItemColor: Colors.white, // White for unselected items
        type: BottomNavigationBarType.fixed, // Required for more than 3 items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'MyCart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favourites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.contact_mail), label: 'Contact'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color(0xFF00122D),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to profile section when avatar is clicked
                                _onItemTapped(1); // Index 1 is for Profile page
                              },
                              child: Icon(Icons.person, color: Color(0xFF00122D)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dynamic greeting with loading indicator
                              _isLoadingUserData
                                ? SizedBox(
                                    height: 22,
                                    width: 120,
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.white30,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                    ),
                                  )
                                : Text(
                                    "Hello, $name",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
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
                        icon: const Icon(
                          Icons.logout, // Changed from notifications_outlined to logout
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Logout', // Updated tooltip
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food Categories header removed as requested
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Adding spacing to push buttons further right
                        SizedBox(width: 40),
                        _buildCategoryChip("Canteen", selectedOption == "Canteen"),
                        SizedBox(width: 100), // Increased spacing to push Cafeteria more to the right
                        _buildCategoryChip("Cafeteria", selectedOption == "Cafeteria"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Popular Food Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Popular Foods",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Changed to white for visibility on dark background
                        ),
                      ),
                      // "See All" text removed as requested
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFoodGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == "Canteen" || label == "Cafeteria") {
          _updateSelectedOption(label);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF53E3C6) : Colors.white, // Changed to teal when selected
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Color(0xFF53E3C6) : Colors.grey.shade300,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(
                color: Color(0xFF53E3C6).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              )]
            : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
   return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 30),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Reduced vertical padding
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(50),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, color: Colors.grey, size: 20), // Slightly smaller icon
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              isDense: true, // Makes the TextField more compact
              contentPadding: EdgeInsets.zero, // Removes internal padding
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildFoodGrid() {
    return availableItems.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 64, color: Colors.white70), // Changed to white for visibility
                const SizedBox(height: 16),
                Text(
                  'No items available in ${selectedOption} today',
                  style: const TextStyle(
                    color: Colors.white70, // Changed to white for visibility
                    fontSize: 16,
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
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: availableItems.length,
            itemBuilder: (context, index) {
              final item = availableItems[index];
              return _buildFoodCard(item, index);
            },
          );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, int index) {
    bool isInCart = index < _isInCart.length ? _isInCart[index] : false;
    
    final String itemId =
        '${selectedOption.toLowerCase()}_${item['id'] ?? DateTime.now().toString()}';
    bool isFavorite = _favoriteStates[itemId] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  child: Image.asset(
                    item['imageUrl'],
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => toggleFavorite(item, index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00122D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  selectedOption,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF900C3F),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => toggleCart(item, index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isInCart ? Color(0xFF53E3C6) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                          color: isInCart ? Colors.white : Colors.grey.shade700,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Added spacing
                    // Added info/description button
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(item['title']),
                            content: Text(item['description'] ?? 'No description available'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
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