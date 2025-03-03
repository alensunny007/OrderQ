import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isProcessingPayment = false;

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
      body: Stack(
        children: [
          Container(
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
                  return Center(
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
                  return Center(
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
                              contentPadding: EdgeInsets.all(12),
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
                                style: TextStyle(
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
                                      icon: Icon(Icons.remove, color: Colors.white70),
                                      onPressed: () => _updateQuantity(userId,
                                          item['docId'], item['quantity'] - 1),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          ElevatedButton(
                            onPressed: () => _showPaymentOptions(context, total, userId, items),
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
          if (isProcessingPayment)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Color(0xFF001736),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53E3C6)),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Processing Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );
  }

  Future<void> _updateQuantity(
      String userId, String itemId, int newQuantity) async {
    if (newQuantity < 1) {
      // Remove item if quantity becomes 0
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

  void _showPaymentOptions(BuildContext context, double total, String userId,
      List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF001736),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete Your Order',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Total Amount: ₹${total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Color(0xFF53E3C6)),
            ),
            SizedBox(height: 20),
            Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPaymentOption(
                  'Google Pay',
                  'assets/images/google-pay.png',
                  Icons.account_balance_wallet,
                  () => _initiateUpiPayment(context, 'gpay', total, userId, items),
                ),
                _buildPaymentOption(
                  'PhonePe',
                  'assets/images/phonepe.png',
                  Icons.phone_android,
                  () => _initiateUpiPayment(context, 'phonepe', total, userId, items),
                ),
                _buildPaymentOption(
                  'Paytm',
                  'assets/images/paytm.png',
                  Icons.payment,
                  () => _initiateUpiPayment(context, 'paytm', total, userId, items),
                ),
              ],
            ),
            SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildPaymentOption(
      String name, String imagePath, IconData fallbackIcon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  imagePath,
                  width: 74, // Container width (90) - padding (8*2)
                  height: 74, // Container height (90) - padding (8*2)
                  fit: BoxFit.contain, // This ensures the image fits while maintaining aspect ratio
                  errorBuilder: (context, error, stackTrace) => Icon(
                    fallbackIcon,
                    size: 45,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }
  // Initiate UPI payment with specific app
  Future<void> _initiateUpiPayment(BuildContext context, String app,
      double amount, String userId, List<Map<String, dynamic>> items) async {
    // Close the payment options bottom sheet
    Navigator.pop(context);

    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Generate a unique transaction reference ID
      String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // Create order in Firestore first (pending status)
      await _createPendingOrder(userId, orderId, items, amount);

      // Create the UPI payment URL
      String upiUrl = _generateUpiUrl(
        upiId: 'aasifabdullahtk@oksbi', // Replace with your UPI ID
        name: 'Food Order',
        amount: amount,
        transactionRef: orderId,
        note: 'Payment for food order #$orderId',
        app: app,
      );

      // Check if URI can be launched using the new Uri approach
      final Uri uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Wait a bit for user to complete payment process
        await Future.delayed(Duration(seconds: 2));
        
        if (mounted) {
          setState(() {
            isProcessingPayment = false;
          });
          
          _confirmPaymentStatus(context, orderId, userId, amount);
        }
      } else {
        // No UPI app found
        setState(() {
          isProcessingPayment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No UPI payment app found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Update order status to failed
        await _updateOrderStatus(userId, orderId, 'failed');
      }
    } catch (e) {
      print('UPI launch error: $e');
      
      setState(() {
        isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Generate UPI payment URL with app-specific parameters
  String _generateUpiUrl({
    required String upiId,
    required String name,
    required double amount,
    required String transactionRef,
    required String note,
    String app = '',
    String currency = 'INR',
  }) {
    String baseUrl = 'upi://pay?'
        'pa=$upiId&'
        'pn=${Uri.encodeComponent(name)}&'
        'am=${amount.toStringAsFixed(2)}&'
        'cu=$currency&'
        'tn=${Uri.encodeComponent(note)}&'
        'tr=$transactionRef';

    // Add app-specific package names - ensures opening of specific apps
    if (app == 'gpay') {
      return '$baseUrl&package=com.google.android.apps.nbu.paisa.user';
    } else if (app == 'phonepe') {
      return '$baseUrl&package=com.phonepe.app';
    } else if (app == 'paytm') {
      return '$baseUrl&package=net.one97.paytm';
    }

    return baseUrl;
  }

  Future<void> _createPendingOrder(
      String userId, String orderId, List<Map<String, dynamic>> items, double amount) async {
    try {
      final order = {
        'orderId': orderId,
        'userId': userId,
        'items': items,
        'total': amount,
        'status': 'pending',
        'paymentMethod': 'UPI',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create the order document
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .set(order);

      // Add order reference to user's orders
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .set({'orderId': orderId, 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error creating pending order: $e');
      throw e;
    }
  }

  Future<void> _updateOrderStatus(String userId, String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  void _confirmPaymentStatus(BuildContext context, String orderId, String userId, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF001736),
        title: Text(
          'Payment Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Did you complete the payment successfully?',
          style: TextStyle(color: Colors.white70),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(userId, orderId, 'failed');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment cancelled. You can try again later.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text(
              'No',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _finalizeOrder(context, orderId, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53E3C6),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Yes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeOrder(BuildContext context, String orderId, String userId) async {
    try {
      // Update order status to paid/confirmed
      await _updateOrderStatus(userId, orderId, 'confirmed');
      
      // Clear the cart
      await _clearCart(userId);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate to order tracking or confirmation page (optional)
      // Navigator.pushReplacement(F
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => OrderConfirmationPage(orderId: orderId),
      //   ),
      // );
    } catch (e) {
      print('Error finalizing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearCart(String userId) async {
    try {
      // Get all cart items
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      
      // Delete each item
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in cartSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing cart: $e');
      throw e;
    }
  }
}