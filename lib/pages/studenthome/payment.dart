import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  late Razorpay _razorpay;
  final uuid = Uuid();
  late String orderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Generate order ID at initialization
    orderId = 'ORD${uuid.v4().replaceAll('-', '').substring(0, 12)}';
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

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
                    color: const Color(0xFF001736),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                              const Text('Items', style: TextStyle(color: Colors.white70)),
                              Text('${widget.items.length}', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(color: Colors.white70)),
                              Text(
                                '₹${widget.total.toStringAsFixed(2)}',
                                style: const TextStyle(
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
                        'Razorpay',
                        'assets/images/razorpay.png',
                        Icons.payment,
                        () => _openRazorpayCheckout(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // UPI App Selection
                  const Text(
                    'Select UPI App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // UPI Apps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPaymentOption(
                        'Google Pay',
                        'assets/images/google-pay.png',
                        Icons.account_balance_wallet,
                        () => _launchUpiPayment(
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
                        () => _launchUpiPayment(
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
                        () => _launchUpiPayment(
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
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text('Cancel Payment'),
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
                  color: const Color(0xFF001736),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    fallbackIcon,
                    size: 40,
                    color: const Color(0xFF001736),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }



// Inside your _openRazorpayCheckout method:

void _openRazorpayCheckout() async {
  setState(() {
    isProcessingPayment = true;
  });

  try {
    // Create a pending order in your database
    await _createPendingOrder(widget.userId, orderId, widget.items, widget.total);

    // Convert amount to paise
    int amountInPaise = (widget.total * 100).toInt();

    // This should be your test/live API key from Razorpay dashboard
    String razorpayKey = dotenv.get('RAZORPAY_KEY_ID');
    if (razorpayKey.isEmpty) {
      throw Exception("Razorpay API key is missing");
    }
    var options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'name': 'Food Order',
      'description': 'Order #$orderId',
      'timeout': 120, 
      'prefill': {
        'contact': '', 
        'email': ''
      },
      'theme': {
        'color': '#00122D'
      }
    };

    _razorpay.open(options);
  } catch (e) {
    setState(() {
      isProcessingPayment = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error initializing payment: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      isProcessingPayment = false;
    });
    
    try {
      // Update order status
      await _updateOrderStatus(widget.userId, orderId, 'confirmed');
      
      // Clear the cart
      await _clearCart(widget.userId);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Order placed.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to home or order confirmation page
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      isProcessingPayment = false;
    });
    
    _updateOrderStatus(widget.userId, orderId, 'failed');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      isProcessingPayment = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment processing through ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // UPI payment launcher (keeping the existing implementation)
  Future<void> _launchUpiPayment(BuildContext context, String appName,
      double amount, String userId, List<Map<String, dynamic>> items) async {
    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Use the existing order ID for consistency
      String txnId = orderId.substring(3); // Remove 'ORD' prefix for transaction ID

      // Create order in Firestore first (pending status)
      await _createPendingOrder(userId, orderId, items, amount);

      // Format amount without trailing zeros if whole number
      final formattedAmount = amount == amount.roundToDouble() 
          ? amount.round().toString() 
          : amount.toStringAsFixed(2);

      // Merchant name - keep it short and simple
      final merchantName = "FoodOrder";
      
      // UPI ID - ensure this is a valid and working UPI ID
      final upiId = "aasifabdullahtk@oksbi";
      
      // Simple description with less characters
      final note = "Food#$txnId";

      // Prepare URL based on app
      Uri upiUrl;
      
      switch(appName) {
        case 'gpay':
          upiUrl = Uri.parse(
            'tez://upi/pay?pa=$upiId&pn=$merchantName&am=$formattedAmount&cu=INR&tn=$note&tr=$txnId'
          );
          break;
        case 'phonepe':
          upiUrl = Uri.parse(
            'phonepe://pay?pa=$upiId&pn=$merchantName&am=$formattedAmount&cu=INR&tn=$note&tr=$txnId'
          );
          break;
        case 'paytm':
          upiUrl = Uri.parse(
            'paytmmp://pay?pa=$upiId&pn=$merchantName&am=$formattedAmount&cu=INR&tn=$note&tr=$txnId'
          );
          break;
        case 'generic':
        default:
          upiUrl = Uri.parse(
            'upi://pay?pa=$upiId&pn=$merchantName&am=$formattedAmount&cu=INR&tn=$note&tr=$txnId'
          );
      }
      
      // Launch the URL
      final launched = await launchUrl(
        upiUrl,
        mode: LaunchMode.externalApplication,
      );

      // Handle result
      if (launched) {
        // Allow some time for payment process
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          setState(() {
            isProcessingPayment = false;
          });
          
          _confirmPaymentStatus(context, orderId, userId);
        }
      } else {
        // Try generic UPI if specific app failed
        if (appName != 'generic') {
          setState(() {
            isProcessingPayment = false;
          });
          
          // Try generic UPI intent instead
          _launchUpiPayment(context, 'generic', amount, userId, items);
          return;
        }
        
        // All attempts failed
        setState(() {
          isProcessingPayment = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to launch payment app. Please ensure you have a UPI app installed.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        await _updateOrderStatus(userId, orderId, 'failed');
      }
    } catch (e) {
      print('UPI launch error: $e');
      
      setState(() {
        isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
        backgroundColor: const Color(0xFF001736),
        title: const Text(
          'Payment Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
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
                const SnackBar(
                  content: Text('Payment cancelled. You can try again later.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
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
            child: const Text(
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
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to home or order confirmation page
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Error finalizing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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