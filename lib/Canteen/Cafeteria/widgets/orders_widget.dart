import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
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
        child: const Center(
          child: Text(
            'Please login to view your orders',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'My Orders',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.white70),
                          SizedBox(height: 16),
                          Text(
                            'You have no orders yet',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: orders.length,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final orderData = orders[index].data() as Map<String, dynamic>;
                      final orderId = orderData['orderId'] as String;
                      final timestamp = orderData['createdAt'] as Timestamp?;
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .get(),
                        builder: (context, orderSnapshot) {
                          final orderStatus = orderSnapshot.hasData
                              ? ((orderSnapshot.data!.data() as Map<String, dynamic>?) != null ? (orderSnapshot.data!.data() as Map<String, dynamic>)['status'] ?? 'unknown' : 'unknown')
                              : 'loading';
                          
                          final orderAmount = orderSnapshot.hasData
                              ? ((orderSnapshot.data!.data() as Map<String, dynamic>?)?['total'] ?? 0.0)
                              : 0.0;
                          
                          final String formattedDate = timestamp != null
                              ? DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp.toDate())
                              : 'Processing';

                          Color statusColor;
                          IconData statusIcon;
                          
                          switch (orderStatus) {
                            case 'confirmed':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'pending':
                              statusColor = Colors.orange;
                              statusIcon = Icons.hourglass_top;
                              break;
                            case 'failed':
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusIcon = Icons.help_outline;
                          }

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Color(0xFF001736),
                            child: InkWell(
                              onTap: () => _showOrderDetails(context, orderId),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #${orderId.substring(orderId.length - 8)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            orderStatus.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: statusColor,
                                          avatar: Icon(
                                            statusIcon,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    if (orderSnapshot.connectionState == ConnectionState.waiting)
                                      Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53E3C6)),
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total: ₹${orderAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Color(0xFF53E3C6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white54,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, String orderId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF53E3C6)),
        ),
      ),
    );

    try {
      // Fetch full order details
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      // Close loading dialog
      Navigator.of(context).pop();

      if (!orderDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order details not found')),
        );
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
      final total = orderData['total'] as double? ?? 0.0;
      final status = orderData['status'] as String? ?? 'unknown';
      final paymentMethod = orderData['paymentMethod'] as String? ?? 'Unknown';
      final createdAt = orderData['createdAt'] as Timestamp?;
      final formattedDate = createdAt != null
          ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())
          : 'Processing';

      // Show order details modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Color(0xFF001736),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle for dragging
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(3)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'confirmed'
                            ? Colors.green
                            : status == 'pending'
                                ? Colors.orange
                                : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = item['title'] as String? ?? 'Unknown Item';
                    final quantity = item['quantity'] as int? ?? 1;
                    final price = item['price'] as double? ?? 0.0;
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: TextStyle(color: Color(0xFF53E3C6)),
                      ),
                      trailing: Text(
                        'x$quantity',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
              Divider(color: Colors.white10),
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          paymentMethod,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Color(0xFF53E3C6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    if (status == 'confirmed')
                      ElevatedButton.icon(
                        onPressed: () {
                          // Implement reorder functionality if needed
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.replay),
                        label: Text('Reorder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF53E3C6),
                          foregroundColor: Colors.black,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading order details')),
      );
      print('Error loading order details: $e');
    }
  }
}