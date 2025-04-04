import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orderq/pages/studenthome/payment.dart';
import 'package:orderq/services/daily_menu_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DailyMenuService _menuService = DailyMenuService();
  bool _checkingAvailability = false;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text('Please login'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: const Color(0xFF00122D),
        foregroundColor: Colors.white,
        elevation: 0,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(color: Colors.white),
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 64, color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            double total = 0;
            final items = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final price = double.parse(data['price'].toString());
              final quantity = data['quantity'] as int;
              total += price * quantity;
              return {
                ...data,
                'docId': doc.id,
                'price': price,
              };
            }).toList();

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    padding: EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Color(0xFF001736),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item['imageUrl'],
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '₹${item['price']}',
                            style: TextStyle(color: Color(0xFF53E3C6)),
                          ),
                          trailing: Container(
                            width: 120,
                            child: Row(
                              children: [
                                IconButton(
                                  icon:
                                      Icon(Icons.remove, color: Colors.white70),
                                  onPressed: () => _updateQuantity(userId,
                                      item['docId'], item['quantity'] - 1),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.white70),
                                  onPressed: () => _updateQuantity(userId,
                                      item['docId'], item['quantity'] + 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00122D),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _checkingAvailability
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF53E3C6)),
                              strokeWidth: 3,
                            )
                          : ElevatedButton(
                              onPressed: () => _checkAvailabilityAndProceed(
                                  context, total, userId, items),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF53E3C6),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkAvailabilityAndProceed(BuildContext context, double total,
      String userId, List<Map<String, dynamic>> items) async {
    setState(() {
      _checkingAvailability = true;
    });

    try {
      // Group items by source
      Map<String, List<String>> itemsBySource = {};

      for (var item in items) {
        final source = item['source'] as String? ?? 'canteen';
        String id = item['id'] as String? ?? '';

        if (id.isNotEmpty) {
          if (!itemsBySource.containsKey(source)) {
            itemsBySource[source] = [];
          }

          // Extract the actual item ID (after the source prefix)
          if (id.contains('_')) {
            id = id.split('_').last;
          }

          itemsBySource[source]!.add(id);
        }
      }

      List<String> unavailableItems = [];
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);

      // Debug information
      print('Checking availability for items: $itemsBySource');

      // Check availability directly against the dailMenu collection
      for (var source in itemsBySource.keys) {
        final availableIds =
            await _menuService.getDirectAvailableItems(source, today);
        print('Available $source items: $availableIds');

        for (var itemId in itemsBySource[source]!) {
          print('Checking item: $itemId in $source');

          if (!availableIds.contains(itemId)) {
            // Find the original item with full data
            final originalItemId = '${source}_$itemId';
            final itemInfo = items.firstWhere(
                (item) => item['id'] == originalItemId,
                orElse: () => {'title': 'Unknown item ($itemId)'});

            unavailableItems
                .add(itemInfo['title'] as String? ?? 'Unknown item');
            print('Item $itemId (${itemInfo['title']}) is unavailable');
          }
        }
      }

      setState(() {
        _checkingAvailability = false;
      });

      if (unavailableItems.isEmpty) {
        print('All items available, proceeding to payment');
        _navigateToPaymentPage(context, total, userId, items);
      } else {
        print('Some items unavailable: $unavailableItems');
        _showUnavailableItemsDialog(context, unavailableItems);
      }
    } catch (e) {
      print('Error in availability check: ${e.toString()}');
      setState(() {
        _checkingAvailability = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking menu availability: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUnavailableItemsDialog(
      BuildContext context, List<String> unavailableItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF001736),
        title: const Text(
          'Unavailable Items',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following items are not available in today\'s menu:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ...unavailableItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'Please remove these items from your cart to proceed.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF53E3C6)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPaymentPage(BuildContext context, double total, String userId,
      List<Map<String, dynamic>> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          userId: userId,
          total: total,
          items: items,
        ),
      ),
    );
  }

  Future<void> _updateQuantity(
      String userId, String itemId, int newQuantity) async {
    if (newQuantity < 1) {
      await _removeFromCart(userId, itemId);
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .update({'quantity': newQuantity});
    }
  }

  Future<void> _removeFromCart(String userId, String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing item from cart: $e');
    }
  }
}