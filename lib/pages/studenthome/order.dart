import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; 

class Order {
  final String id;
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> items;
  final Timestamp timestamp;
  final String status;
  final double totalAmount;
  final String paymentStatus; // Add this field

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.timestamp,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus, // Add this parameter
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Get items with better field detection
    List<Map<String, dynamic>> items = [];
    if (data['items'] != null) {
      items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    }

    // Calculate total amount if it's zero or missing
    double totalAmount = (data['totalAmount'] ?? 0).toDouble();
    if (totalAmount == 0 && items.isNotEmpty) {
      // Calculate from items if total is not available
      totalAmount = items.fold(0, (sum, item) {
        final quantity = item['quantity'] as int? ?? 1;
        final price = (item['price'] as num? ?? 0).toDouble();
        return sum + (quantity * price);
      });
    }

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      items: items,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      totalAmount: totalAmount,
      paymentStatus: data['paymentStatus'] ??
          'pending', // Get payment status from Firebase
    );
  }

  Map<String, dynamic> toQrData() {
    return {
      'id': id,
      'userName': userName,
      'items': items
          .map((item) => {
                'name': item['name'],
                'quantity': item['quantity'],
                'price': item['price'],
              })
          .toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus, // Include payment status in QR data
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  late Stream<QuerySnapshot> _ordersStream;
  bool _isLoading = true;
  String? _error;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Filter orders by the current user's ID
    _setupOrdersStream();
  }

  void _setupOrdersStream() {
    try {
      if (currentUser == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // First try to get orders without ordering to avoid index issues
      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: currentUser!.uid)
          .snapshots();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error setting up orders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00122D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF00122D),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF53E3C6),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _setupOrdersStream();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53E3C6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF53E3C6),
            ),
          );
        }

        if (snapshot.hasError) {
          String errorMessage = 'An error occurred while loading orders';

          // Check if it's an index error
          if (snapshot.error.toString().contains('failed-precondition') &&
              snapshot.error.toString().contains('requires an index')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.build, size: 60, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    'Setting up your order history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'We\'re preparing your orders page. This might take a few minutes. Please check back later.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53E3C6),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53E3C6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade500),
                const SizedBox(height: 24),
                const Text(
                  'No orders found',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your order history will appear here',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }

        // Convert the documents to Order objects
        final orders =
            snapshot.data!.docs.map((doc) => Order.fromFirestore(doc)).toList();

        // Sort manually since we removed the orderBy from the query
        orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.grey.shade900.withOpacity(0.4),
      elevation: 4,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getStatusColor(order.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getStatusIcon(order.status),
            color: getStatusColor(order.status),
            size: 24,
          ),
        ),
        title: Text(
          'Order #${order.id}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis, // Keep this to handle very long IDs
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y • h:mm a').format(order.timestamp.toDate()),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: getStatusColor(order.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        iconColor: const Color(0xFF53E3C6),
        collapsedIconColor: Colors.white,
        childrenPadding: const EdgeInsets.all(16.0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.grey),
          Text(
            'Items:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF53E3C6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Item',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Price',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(color: Colors.grey.shade700, height: 1),
                const SizedBox(height: 8),
                // Items
                ...order.items.map((item) {
                  final quantity = item['quantity'] as int? ?? 1;
                  final price = (item['price'] as num? ?? 0).toDouble();
                  final itemTotal = price * quantity;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        // Item name
                        Expanded(
                          flex: 5,
                          child: Text(
                            // Check multiple possible field names for item title
                            item['name'] ??
                                item['title'] ??
                                item['itemName'] ??
                                item['product_name'] ??
                                'Unknown Item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Quantity
                        Expanded(
                          flex: 2,
                          child: Text(
                            '$quantity',
                            style: TextStyle(
                              color: Colors.grey.shade300,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Price per item
                        Expanded(
                          flex: 3,
                          child: Text(
                            '₹${itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade700, height: 1),
                const SizedBox(height: 8),

                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                // Total amount with more emphasis
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF53E3C6),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text(
                  'QR Code for Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan to view order details',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: QrImageView(
                    // Use JSON encoded data instead of just the ID
                    data: jsonEncode(order.toQrData()),
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_top;
      case 'preparing':
        return Icons.restaurant;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'preparing':
        return 'Preparing';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Your order has been served. Enjoy!';
      case 'processing':
        return 'Your order is being processed. It will be ready soon.';
      case 'preparing':
        return 'Your food is being prepared in the kitchen.';
      case 'cancelled':
        return 'This order has been cancelled.';
      default:
        return 'Your order is waiting to be processed.';
    }
  }

  IconData _getPaymentIcon(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Icons.payments_outlined;
      case 'processing':
        return Icons.payment;
      case 'failed':
        return Icons.money_off;
      case 'refunded':
        return Icons.keyboard_return;
      case 'cod':
        return Icons.money;
      default:
        return Icons.pending_actions;
    }
  }

  String _formatPaymentStatus(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'cod':
        return 'Cash On Delivery';
      default:
        return paymentStatus.isEmpty ? 'Pending' : paymentStatus;
    }
  }

  String _getPaymentDescription(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Your payment has been processed successfully.';
      case 'processing':
        return 'Your payment is being processed.';
      case 'failed':
        return 'There was an issue with your payment.';
      case 'refunded':
        return 'Your payment has been refunded.';
      case 'cod':
        return 'Pay cash when you receive your order.';
      default:
        return 'Your payment is pending confirmation.';
    }
  }

  Color getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return const Color(0xFF53E3C6); // Teal to match app's theme
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.amber;
      case 'cod':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF53E3C6); // Teal to match app's theme
      case 'processing':
        return Colors.orange;
      case 'preparing':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}