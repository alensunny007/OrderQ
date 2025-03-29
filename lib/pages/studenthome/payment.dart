import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final String userId;
  final double total;
  final List<Map<String, dynamic>> items;

  const PaymentPage({
    super.key,
    required this.userId,
    required this.total,
    required this.items,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isProcessingPayment = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Card(
                    color: Color(0xFF001736),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Items', style: TextStyle(color: Colors.white70)),
                              Text('${widget.items.length}', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: TextStyle(color: Colors.white70)),
                              Text(
                                '₹${widget.total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Color(0xFF53E3C6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Payment Options Header
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Payment Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPaymentOption(
                        'Google Pay',
                        'assets/images/google-pay.png',
                        Icons.account_balance_wallet,
                        () => _launchSpecificUpiApp(
                          context, 
                          'gpay', 
                          widget.total, 
                          widget.userId, 
                          widget.items
                        ),
                      ),
                      _buildPaymentOption(
                        'PhonePe',
                        'assets/images/phonepe.png',
                        Icons.phone_android,
                        () => _launchSpecificUpiApp(
                          context, 
                          'phonepe', 
                          widget.total, 
                          widget.userId, 
                          widget.items
                        ),
                      ),
                      _buildPaymentOption(
                        'Paytm',
                        'assets/images/paytm.png',
                        Icons.payment,
                        () => _launchSpecificUpiApp(
                          context, 
                          'paytm', 
                          widget.total, 
                          widget.userId, 
                          widget.items
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Cancel button
                  Center(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: Text('Cancel Payment'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
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
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Method to launch a specific UPI app directly
  Future<void> _launchSpecificUpiApp(BuildContext context, String appName,
      double amount, String userId, List<Map<String, dynamic>> items) async {
    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Generate a unique transaction reference ID
      String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

      // Create order in Firestore first (pending status)
      await _createPendingOrder(userId, orderId, items, amount);

      // Payment details
      final upiDetails = {
        'upiId': 'athuldevaraj1@oksbi', // Replace with your UPI ID
        'name': 'Food Order',
        'amount': amount.toStringAsFixed(2),
        'transactionRef': orderId,
        'note': 'Payment for food order #$orderId',
      };

      // Attempt to launch the specific UPI app
      bool launched = false;
      
      if (appName == 'gpay') {
        launched = await _launchGooglePay(upiDetails);
      } else if (appName == 'phonepe') {
        launched = await _launchPhonePe(upiDetails);
      } else if (appName == 'paytm') {
        launched = await _launchPaytm(upiDetails);
      }

      if (launched) {
        // Wait a bit for user to complete payment process
        await Future.delayed(Duration(seconds: 2));
        
        if (mounted) {
          setState(() {
            isProcessingPayment = false;
          });
          
          _confirmPaymentStatus(context, orderId, userId);
        }
      } else {
        // App not found - show error
        setState(() {
          isProcessingPayment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected payment app not installed'),
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

  // Launch Google Pay app directly
  Future<bool> _launchGooglePay(Map<String, String> upiDetails) async {
    try {
      // Google Pay specific intent URL
      final intentUrl = Uri.parse(
        'tez://upi/pay?pa=${upiDetails['upiId']}'
        '&pn=${Uri.encodeComponent(upiDetails['name']!)}'
        '&am=${upiDetails['amount']}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(upiDetails['note']!)}'
        '&tr=${upiDetails['transactionRef']}'
      );
      
      return await launchUrl(
        intentUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Google Pay launch error: $e');
      return false;
    }
  }

  // Launch PhonePe app directly
  Future<bool> _launchPhonePe(Map<String, String> upiDetails) async {
    try {
      // PhonePe specific intent URL
      final intentUrl = Uri.parse(
        'phonepe://pay?pa=${upiDetails['upiId']}'
        '&pn=${Uri.encodeComponent(upiDetails['name']!)}'
        '&am=${upiDetails['amount']}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(upiDetails['note']!)}'
        '&tr=${upiDetails['transactionRef']}'
      );
      
      return await launchUrl(
        intentUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('PhonePe launch error: $e');
      return false;
    }
  }

  // Launch Paytm app directly
  Future<bool> _launchPaytm(Map<String, String> upiDetails) async {
    try {
      // Paytm specific intent URL
      final intentUrl = Uri.parse(
        'paytmmp://pay?pa=${upiDetails['upiId']}'
        '&pn=${Uri.encodeComponent(upiDetails['name']!)}'
        '&am=${upiDetails['amount']}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent(upiDetails['note']!)}'
        '&tr=${upiDetails['transactionRef']}'
      );
      
      return await launchUrl(
        intentUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Paytm launch error: $e');
      
      // Try alternate Paytm UPI URL
      try {
        final alternateUrl = Uri.parse(
          'paytm://upi/pay?pa=${upiDetails['upiId']}'
          '&pn=${Uri.encodeComponent(upiDetails['name']!)}'
          '&am=${upiDetails['amount']}'
          '&cu=INR'
          '&tn=${Uri.encodeComponent(upiDetails['note']!)}'
          '&tr=${upiDetails['transactionRef']}'
        );
        
        return await launchUrl(
          alternateUrl,
          mode: LaunchMode.externalApplication,
        );
      } catch (e2) {
        print('Alternate Paytm launch error: $e2');
        return false;
      }
    }
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

  void _confirmPaymentStatus(BuildContext context, String orderId, String userId) {
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
      
      // Navigate back to home or order confirmation page
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Alternatively, navigate to order tracking page:
      // Navigator.pushReplacement(
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