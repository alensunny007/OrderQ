import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersWidget extends StatefulWidget {
  const OrdersWidget({super.key});

  @override
  State createState() => _OrdersWidgetState();
}

class _OrdersWidgetState extends State<OrdersWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  // Selected date for filtering
  DateTime _selectedDate = DateTime.now();
  // Selected month for monthly view
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            'Please login to view orders',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revenue Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        // Refresh the page
                      });
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.black12,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Color(0xFF53E3C6),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Daily Revenue'),
                  Tab(text: 'Monthly Summary'),
                ],
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDailyRevenueTab(),
                  _buildMonthlyRevenueTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRevenueTab() {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Color(0xFF53E3C6),
                            surface: Color(0xFF00122D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                icon: Icon(Icons.calendar_today, size: 16),
                label: Text('Change Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00122D),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Today's Revenue Summary
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('revenue')
              .doc(formattedDate)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading revenue data',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data;
            final double totalRevenue = data?.exists == true
                ? (data!.data() as Map<String, dynamic>)['total']?.toDouble() ??
                    0.0
                : 0.0;

            final List<String> orderIds = data?.exists == true
                ? List<String>.from(
                    (data!.data() as Map<String, dynamic>)['orders'] ?? [])
                : [];

            return Expanded(
              child: Column(
                children: [
                  // Revenue Card
                  Card(
                    margin: EdgeInsets.all(16),
                    color: Color(0xFF001736),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Revenue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(totalRevenue),
                            style: TextStyle(
                              color: Color(0xFF53E3C6),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Orders: ${orderIds.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Orders Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completed Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${orderIds.length} orders',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Orders List
                  Expanded(
                    child: orderIds.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 64, color: Colors.white30),
                                SizedBox(height: 16),
                                Text(
                                  'No orders completed on this day',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: orderIds.length,
                            padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderIds[index])
                                    .get(),
                                builder: (context, orderSnapshot) {
                                  if (!orderSnapshot.hasData) {
                                    return SizedBox(
                                      height: 60,
                                      child: Center(
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.black12,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF53E3C6),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (!orderSnapshot.data!.exists) {
                                    return SizedBox.shrink();
                                  }

                                  final orderData = orderSnapshot.data!.data()
                                      as Map<String, dynamic>;

                                  // Better handling of order amount
                                  double amount = 0.0;
                                  if (orderData.containsKey('totalAmount')) {
                                    amount = (orderData['totalAmount'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                  } else if (orderData.containsKey('items')) {
                                    List<dynamic> items =
                                        orderData['items'] as List<dynamic>;
                                    amount = items.fold(0.0, (sum, item) {
                                      final itemData =
                                          item as Map<String, dynamic>;
                                      final quantity =
                                          itemData['quantity'] as int? ?? 1;
                                      final price = (itemData['price'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                      return sum + (quantity * price);
                                    });
                                  }

                                  // Get user information with fallbacks
                                  String userName = orderData['userName'] ??
                                      orderData['customerName'] ??
                                      'User';
                                  final String userId =
                                      orderData['userId'] ?? '';

                                  // Fetch user info from Firebase if we only have the user ID
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: userId.isNotEmpty
                                        ? FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .get()
                                        : null,
                                    builder: (context, userSnapshot) {
                                      // If we have user data from Firebase, use it
                                      if (userSnapshot.hasData &&
                                          userSnapshot.data != null &&
                                          userSnapshot.data!.exists) {
                                        final userData = userSnapshot.data!
                                            .data() as Map<String, dynamic>;

                                        // Try all possible name fields in the user document
                                        final String? fetchedName =
                                            userData['name'] ??
                                                userData['displayName'] ??
                                                userData['username'] ??
                                                userData['fullName'] ??
                                                userData['user_name'];

                                        if (fetchedName != null &&
                                            fetchedName.isNotEmpty) {
                                          userName = fetchedName;
                                        }
                                      }

                                      // Format timestamp
                                      final Timestamp? timestamp =
                                          orderData['timestamp'] as Timestamp?;
                                      final String timeString =
                                          timestamp != null
                                              ? DateFormat('hh:mm a')
                                                  .format(timestamp.toDate())
                                              : 'N/A';

                                      // Get order ID (shortened for display)
                                      final String orderId = orderIds[index];
                                      final String shortOrderId =
                                          orderId.length > 8
                                              ? "${orderId.substring(0, 8)}..."
                                              : orderId;

                                      // Get customer info - include more details if available
                                      final String customerEmail = userSnapshot
                                                  .hasData &&
                                              userSnapshot.data?.exists == true
                                          ? (userSnapshot.data!.data() as Map<
                                                  String, dynamic>)['email'] ??
                                              ''
                                          : orderData['userEmail'] ?? '';

                                      final String customerPhone = userSnapshot
                                                  .hasData &&
                                              userSnapshot.data?.exists == true
                                          ? (userSnapshot.data!.data() as Map<
                                                  String, dynamic>)['phone'] ??
                                              (userSnapshot.data!.data() as Map<
                                                  String,
                                                  dynamic>)['phoneNumber'] ??
                                              ''
                                          : orderData['userPhone'] ??
                                              orderData['phone'] ??
                                              '';

                                      return Card(
                                        margin: EdgeInsets.only(bottom: 8),
                                        color: Color(0xFF001022),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ExpansionTile(
                                          iconColor: Color(0xFF53E3C6),
                                          collapsedIconColor: Colors.white70,
                                          title: Text(
                                            'Order #$shortOrderId',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(Icons.person,
                                                  size: 12,
                                                  color: Colors.white70),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.access_time,
                                                  size: 12,
                                                  color: Colors.white70),
                                              SizedBox(width: 4),
                                              Text(
                                                timeString,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            currencyFormatter.format(amount),
                                            style: TextStyle(
                                              color: Color(0xFF53E3C6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          children: [
                                            // Order details section
                                            Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Order ID
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.receipt_long,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF53E3C6),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'Order ID: $orderId',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),

                                                  // Customer name with icon (more prominent)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12,
                                                            horizontal: 16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Color(0xFF53E3C6)
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.person,
                                                              size: 18,
                                                              color: Color(
                                                                  0xFF53E3C6),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Customer Information',
                                                              style: TextStyle(
                                                                color: Color(
                                                                    0xFF53E3C6),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text(
                                                          userName,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        if (customerEmail
                                                            .isNotEmpty) ...[
                                                          SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Icon(Icons.email,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white54),
                                                              SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                customerEmail,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (customerPhone
                                                            .isNotEmpty) ...[
                                                          SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Icon(Icons.phone,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white54),
                                                              SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                customerPhone,
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),

                                                  // Show order items if available
                                                  if (orderData.containsKey(
                                                          'items') &&
                                                      (orderData['items']
                                                              as List<dynamic>)
                                                          .isNotEmpty) ...[
                                                    Container(
                                                      padding:
                                                          EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.05),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(0.1),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .restaurant,
                                                                size: 16,
                                                                color: Color(
                                                                    0xFF53E3C6),
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                'Items Ordered',
                                                                style:
                                                                    TextStyle(
                                                                  color: Color(
                                                                      0xFF53E3C6),
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 12),
                                                          // Display items in a more readable format
                                                          ListView.builder(
                                                            shrinkWrap: true,
                                                            physics:
                                                                NeverScrollableScrollPhysics(),
                                                            itemCount: (orderData[
                                                                        'items']
                                                                    as List<
                                                                        dynamic>)
                                                                .length,
                                                            itemBuilder:
                                                                (context,
                                                                    itemIndex) {
                                                              final item = (orderData[
                                                                          'items']
                                                                      as List<
                                                                          dynamic>)[
                                                                  itemIndex];

                                                              // Look for the item name in different possible fields, prioritizing 'title'
                                                              String itemName;

                                                              // Try to get the title first, as it seems this is what your data uses
                                                              if (item.containsKey(
                                                                      'title') &&
                                                                  item['title'] !=
                                                                      null) {
                                                                itemName = item[
                                                                        'title']
                                                                    .toString();
                                                              }
                                                              // Then try name
                                                              else if (item
                                                                      .containsKey(
                                                                          'name') &&
                                                                  item['name'] !=
                                                                      null) {
                                                                itemName = item[
                                                                        'name']
                                                                    .toString();
                                                              }
                                                              // Then try itemName
                                                              else if (item
                                                                      .containsKey(
                                                                          'itemName') &&
                                                                  item['itemName'] !=
                                                                      null) {
                                                                itemName = item[
                                                                        'itemName']
                                                                    .toString();
                                                              }
                                                              // Then try product_name
                                                              else if (item
                                                                      .containsKey(
                                                                          'product_name') &&
                                                                  item['product_name'] !=
                                                                      null) {
                                                                itemName = item[
                                                                        'product_name']
                                                                    .toString();
                                                              }
                                                              // Finally, if all else fails, use productId or 'Unknown Item'
                                                              else if (item
                                                                      .containsKey(
                                                                          'productId') &&
                                                                  item['productId'] !=
                                                                      null) {
                                                                itemName =
                                                                    'Product #${item['productId']}';
                                                              } else {
                                                                itemName =
                                                                    'Unknown Item';
                                                              }

                                                              // For debugging - print the item structure to console
                                                              print(
                                                                  'DEBUG: Item structure for ${itemIndex}: ${item.keys.toList()}');

                                                              final quantity =
                                                                  item['quantity']
                                                                          as int? ??
                                                                      1;
                                                              final price =
                                                                  (item['price']
                                                                              as num?)
                                                                          ?.toDouble() ??
                                                                      0.0;

                                                              return Container(
                                                                margin: EdgeInsets
                                                                    .only(
                                                                        bottom:
                                                                            8),
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              6),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Color(0xFF53E3C6)
                                                                            .withOpacity(0.2),
                                                                        borderRadius:
                                                                            BorderRadius.circular(6),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        quantity
                                                                            .toString(),
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Color(0xFF53E3C6),
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            12),
                                                                    Expanded(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            itemName,
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w600,
                                                                              fontSize: 15,
                                                                            ),
                                                                          ),
                                                                          if (item.containsKey('description') &&
                                                                              item['description'] != null &&
                                                                              item['description'].toString().isNotEmpty) ...[
                                                                            SizedBox(height: 4),
                                                                            Text(
                                                                              item['description'].toString(),
                                                                              style: TextStyle(
                                                                                color: Colors.white70,
                                                                                fontSize: 12,
                                                                              ),
                                                                              maxLines: 2,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      currencyFormatter.format(
                                                                          price *
                                                                              quantity),
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        fontSize:
                                                                            15,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                          Divider(
                                                              color: Colors
                                                                  .white24,
                                                              height: 24),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Text(
                                                                'Subtotal:',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                currencyFormatter
                                                                    .format(
                                                                        amount),
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(height: 16),
                                                  ],

                                                  // Total amount
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12,
                                                            horizontal: 16),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFF53E3C6)
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Total Amount',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          currencyFormatter
                                                              .format(amount),
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFF53E3C6),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonthlyRevenueTab() {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Color(0xFF53E3C6),
                            surface: Color(0xFF00122D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedMonth = DateTime(picked.year, picked.month, 1);
                    });
                  }
                },
                icon: Icon(Icons.calendar_today, size: 16),
                label: Text('Change Month'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00122D),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Revenue for the month
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('revenue')
              .where('date',
                  isGreaterThanOrEqualTo:
                      DateFormat('yyyy-MM-dd').format(startOfMonth))
              .where('date',
                  isLessThanOrEqualTo:
                      DateFormat('yyyy-MM-dd').format(endOfMonth))
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading monthly data: ${snapshot.error}',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // Calculate total monthly revenue
            double totalMonthlyRevenue = 0;
            int totalOrders = 0;

            // Map to store daily revenue for chart data
            Map<String, double> dailyRevenue = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final double revenue = (data['total'] as num?)?.toDouble() ?? 0.0;
              totalMonthlyRevenue += revenue;

              final List<String> orders =
                  List<String>.from(data['orders'] ?? []);
              totalOrders += orders.length;

              final String date = data['date'] as String;
              dailyRevenue[date] = revenue;
            }

            return Expanded(
              child: Column(
                children: [
                  // Monthly Revenue Card
                  Card(
                    margin: EdgeInsets.all(16),
                    color: Color(0xFF001736),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Revenue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(totalMonthlyRevenue),
                            style: TextStyle(
                              color: Color(0xFF53E3C6),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Orders: $totalOrders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Days: ${docs.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Daily breakdown title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Breakdown',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${docs.length} days',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daily breakdown list
                  Expanded(
                    child: docs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart,
                                    size: 64, color: Colors.white30),
                                SizedBox(height: 16),
                                Text(
                                  'No revenue data for this month',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: docs.length,
                            padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final date = data['date'] as String;
                              final double revenue =
                                  (data['total'] as num?)?.toDouble() ?? 0.0;
                              final List<String> orders =
                                  List<String>.from(data['orders'] ?? []);

                              // Format the date for display
                              final DateTime dateObj =
                                  DateFormat('yyyy-MM-dd').parse(date);
                              final String displayDate =
                                  DateFormat('MMM dd (EEEE)').format(dateObj);

                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                color: Color(0xFF001022),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    // Navigate to daily view for this date
                                    setState(() {
                                      _selectedDate = dateObj;
                                      _tabController
                                          .animateTo(0); // Switch to daily view
                                    });
                                  },
                                  title: Text(
                                    displayDate,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${orders.length} orders',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    currencyFormatter.format(revenue),
                                    style: TextStyle(
                                      color: Color(0xFF53E3C6),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
