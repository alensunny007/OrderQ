import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orderq/services/daily_menu_service.dart';

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DailyMenuService _menuService = DailyMenuService();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;
  Map<String, Set<String>> _availableItems = {'canteen': {}, 'cafeteria': {}};
  bool _isLoadingMenu = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load available items for today's menu
  Future<void> _loadAvailableItems() async {
    setState(() {
      _isLoadingMenu = true;
    });

    try {
      // Get today's date (start of day)
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      print('Loading available items for favorites, date: $today');

      // Query directly from dailMenu collection (note the spelling)
      final canteenIds =
          await _menuService.getDirectAvailableItems('canteen', today);
      final cafeteriaIds =
          await _menuService.getDirectAvailableItems('cafeteria', today);

      print('Available canteen items: $canteenIds');
      print('Available cafeteria items: $cafeteriaIds');

      setState(() {
        _availableItems = {
          'canteen': canteenIds,
          'cafeteria': cafeteriaIds,
        };
        _isLoadingMenu = false;
      });
    } catch (e) {
      print('Error loading available menu items: $e');
      setState(() {
        _isLoadingMenu = false;
      });
    }
  }

  // Update how favorites checks availability
  bool isItemAvailable(String itemId, String source) {
    if (itemId.isEmpty) return false;

    // Extract the actual ID without prefix
    final cleanId = itemId.contains('') ? itemId.split('').last : itemId;

    // Check if this ID is in the available items set
    final result = _availableItems[source]?.contains(cleanId) ?? false;
    print('Checking availability of $cleanId in $source: $result');
    return result;
  }

  // Helper function for string capitalization
  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: const Color(0xFF00122D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add refresh button to reload available items
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableItems,
            tooltip: 'Refresh menu availability',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Canteen'),
            Tab(text: 'Cafeteria'),
          ],
          indicatorColor: const Color(0xFF53E3C6),
          labelColor: const Color(0xFF53E3C6),
          unselectedLabelColor: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00122D), // Dark blue
              Color(0xFF001f47), // Slightly lighter blue
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoadingMenu
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53E3C6)),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildFavoritesList('canteen'),
                  _buildFavoritesList('cafeteria'),
                ],
              ),
      ),
    );
  }

  Widget _buildFavoritesList(String source) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .where('source', isEqualTo: source)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53E3C6)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border,
                    size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Text(
                  'No favorites in ${capitalizeFirstLetter(source)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Filter favorites based on availability
        final allFavorites = snapshot.data!.docs;
        List<QueryDocumentSnapshot> availableFavorites = [];
        List<QueryDocumentSnapshot> unavailableFavorites = [];

        for (var doc in allFavorites) {
          final data = doc.data() as Map<String, dynamic>;
          final itemId = data['itemId'] as String? ?? '';
          final source = data['source'] as String? ?? '';

          // Use the new helper method
          if (isItemAvailable(itemId, source)) {
            availableFavorites.add(doc);
          } else {
            unavailableFavorites.add(doc);
          }
        }

        // Combine lists: available items first, then unavailable
        final allDocs = [...availableFavorites, ...unavailableFavorites];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12, // Match home page
            mainAxisSpacing: 12, // Match home page
            childAspectRatio: 0.7, // Match home page aspect ratio
          ),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            final doc = allDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final itemId = data['itemId'] as String? ?? '';
            final isAvailable = isItemAvailable(itemId, source);

            return _buildFavoriteCard(data, doc.id, isAvailable);
          },
        );
      },
    );
  }

  Widget _buildFavoriteCard(
      Map<String, dynamic> data, String docId, bool isAvailable) {
    // Safely get source and capitalize it
    String sourceText = data['source'] ?? '';
    String displaySource = capitalizeFirstLetter(sourceText);

    // Format price for display
    var priceDisplay = '';
    if (data['price'] != null) {
      priceDisplay = '₹${data['price']}';
    } else {
      priceDisplay = '₹0';
    }

    return Card(
      elevation: 3, // Match home page
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)), // Match home page
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image - match home page style
          Stack(
            children: [
              // Add unavailable overlay if needed
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15)), // Match home page
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.all(8), // Match home page padding
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Image.asset(
                        data['imageUrl'],
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (!isAvailable)
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Unavailable Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeFromFavorites(docId),
                  child: Container(
                    padding: const EdgeInsets.all(6), // Match home page
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(15), // Match home page
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content - match home page style
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // Match home page padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Color(0xFF00122D) : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    displaySource,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          priceDisplay,
                          style: TextStyle(
                            fontSize: 18, // Match home page
                            fontWeight: FontWeight.bold,
                            color:
                                isAvailable ? Color(0xFF900C3F) : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Layout buttons in a row with proper spacing - MATCH HOME PAGE PATTERN
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: isAvailable ? () => _addToCart(data) : null,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(8), // Match home page
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(
                                    15), // Match home page
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: isAvailable
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                                size: 22, // Match home page
                              ),
                            ),
                          ),
                          const SizedBox(width: 8), // Match home page spacing
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: Text(
                                    data['title'] ?? '',
                                    style: TextStyle(
                                      color: isAvailable
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(data['description'] ??
                                          'No description available'),
                                      if (!isAvailable) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.amber.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border:
                                                Border.all(color: Colors.amber),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.amber,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'This item is not available in today\'s menu.',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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
                              padding:
                                  const EdgeInsets.all(8), // Match home page
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(
                                    15), // Match home page
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                                size: 22, // Match home page
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      final String source = item['source'] ?? '';
      final String itemId = item['itemId'] ?? '';

      // Check if item has valid ID
      if (itemId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Invalid item'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // First check if item is available in today's menu
      if (!isItemAvailable(itemId, source)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} is not available in today\'s menu'),
            backgroundColor: Colors.amber.shade700,
          ),
        );
        return;
      }

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        // If item is already in cart, show message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} is already in your cart'),
            backgroundColor: const Color(0xFF00122D),
          ),
        );
      } else {
        // Handle different price formats and ensure it's saved as a double
        dynamic priceValue = item['price'];
        double finalPrice = 0.0;

        if (priceValue is double) {
          finalPrice = priceValue;
        } else if (priceValue is int) {
          finalPrice = priceValue.toDouble();
        } else if (priceValue is String) {
          // Try to parse the string to a double
          finalPrice = double.tryParse(priceValue) ?? 0.0;
        }

        // Add item to cart with proper price value
        await docRef.set({
          'id': itemId,
          'title': item['title'] ?? '',
          'price': finalPrice,
          'imageUrl': item['imageUrl'] ?? '',
          'quantity': 1,
          'source': source,
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} added to cart'),
            backgroundColor: const Color(0xFF53E3C6),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to cart tab in the main navigation
                Navigator.of(context)
                    .pop(); // Close the favorites page if it's a separate page
                // Navigate to cart tab - this approach might need to be adjusted based on your navigation setup
                final pageViewIndex = 2; // Index for cart in bottom navigation
                // You may need to use a global key or state management solution to change the index
                // This is a placeholder that would need to be implemented based on your navigation structure
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error adding to cart'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _removeFromFavorites(String docId) async {
    try {
      // Get the document reference
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(docId);

      // Delete the document
      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: Color(0xFF00122D),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error removing from favorites'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}