import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  bool _isScanning = false;
  final MobileScannerController _scannerController = MobileScannerController();
  Map<String, dynamic>? _transactionData;
  bool _isVerifying = false;
  bool _verificationSuccess = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _verifyTransaction(String transactionData) async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // Parse the QR data to get transaction details
      Map<String, dynamic> parsedData = jsonDecode(transactionData);

      // Debug the parsed data
      print("Parsed QR data: $parsedData");

      // Get the transaction ID or order ID from the QR data
      String? transactionId = parsedData['id']?.toString() ??
          parsedData['transactionId']?.toString() ??
          parsedData['orderId']?.toString();

      if (transactionId == null) {
        throw Exception('No transaction ID found in QR code');
      }

      // Check if it's an order QR code
      bool isOrderQR = parsedData.containsKey('items');

      if (isOrderQR) {
        // This is an order QR, check the order in Firestore
        DocumentSnapshot orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(transactionId)
            .get();

        if (orderDoc.exists) {
          Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;

          // Create a clean data object with only necessary fields
          final cleanData = {
            'orderId': transactionId,
            'items': parsedData['items'],
            'totalAmount': parsedData['totalAmount'],
            'userName': parsedData['userName'],
            'timestamp': parsedData['timestamp'],
            'status': data['status'] ?? 'pending',
            'paymentStatus': data['paymentStatus'] ?? 'pending',
          };

          setState(() {
            _transactionData = cleanData;
            _verificationSuccess = data['status'] == 'completed';
          });
        } else {
          setState(() {
            _transactionData = {
              'error': 'Order not found',
              'scannedData': parsedData,
            };
            _verificationSuccess = false;
          });
        }
      } else {
        // Legacy transaction QR handling
        DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(transactionId)
            .get();

        if (transactionDoc.exists) {
          Map<String, dynamic> data =
              transactionDoc.data() as Map<String, dynamic>;

          setState(() {
            _transactionData = {
              'transactionId': transactionId,
              'amount': data['amount'],
              'timestamp': data['timestamp'],
              'customerName': data['name'],
              'status': data['status'],
              'verified': data['verified'] ?? false,
            };
            _verificationSuccess = data['verified'] == true;
          });
        } else {
          setState(() {
            _transactionData = {
              'error': 'Transaction not found',
              'scannedData': parsedData,
            };
            _verificationSuccess = false;
          });
        }
      }
    } catch (e) {
      print("Error in transaction verification: $e");
      setState(() {
        _transactionData = {
          'error': 'Error verifying transaction: $e',
          'rawData': transactionData,
        };
        _verificationSuccess = false;
      });
    }

    setState(() {
      _isVerifying = false;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text('Home', style: TextStyle(color: Colors.white))),
        backgroundColor: const Color(0xFF00122D),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF00122D),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('Are you sure you want to logout?',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.pushReplacementNamed(
                                  context, '/loginPage');
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Error logging out. Please try again.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isScanning
            ? _buildQRScanner()
            : _transactionData != null
                ? _buildTransactionResult()
                : _buildHomeContent(),
      ),
      floatingActionButton: _isScanning
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00122D),
              onPressed: () {
                setState(() {
                  _isScanning = false;
                });
              },
              child: const Icon(Icons.close, color: Colors.white),
            )
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFF00122D),
              onPressed: () {
                setState(() {
                  _isScanning = true;
                  _transactionData = null;
                  _verificationSuccess = false;
                });
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label:
                  const Text('Scan QR', style: TextStyle(color: Colors.teal)),
            ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_scanner,
          size: 80,
          color: Colors.white,
        ),
        const SizedBox(height: 20),
        const Text(
          'Transaction Verification',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Scan QR codes to verify customer transactions for canteen and cafeteria payments',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isScanning = true;
              _transactionData = null;
              _verificationSuccess = false;
            });
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF00122D),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                  _verifyTransaction(barcodes[0].rawValue!);
                }
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Position the QR code within the scanner frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionResult() {
    final bool hasError = _transactionData!.containsKey('error');

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _verificationSuccess ? Icons.check_circle : Icons.error,
              size: 72,
              color: _verificationSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _verificationSuccess
                  ? 'Transaction Verified'
                  : 'Verification Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _verificationSuccess ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (hasError) ...[
              Text(
                _transactionData!['error'],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ] else ...[
              _buildTransactionDetails(),
            ],
            const SizedBox(height: 20),

            // Only show the approve button if verification is not yet successful
            if (!_verificationSuccess && !hasError) ...[
              ElevatedButton(
                onPressed: () async {
                  // Mark the transaction as approved
                  await _approveTransaction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53E3C6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Approve Transaction'),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _transactionData = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00122D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveTransaction() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final bool isOrder = _transactionData!.containsKey('orderId');
      final String idField = isOrder ? 'orderId' : 'transactionId';
      final String documentId = _transactionData![idField]?.toString() ?? '';

      if (documentId.isEmpty) {
        throw Exception('No valid ID found for approval');
      }

      // Get current user for auditing
      final currentUser = FirebaseAuth.instance.currentUser;
      final verifiedBy = currentUser?.uid ?? 'unknown_admin';
      final verifiedAt = DateTime.now();

      // Get amount for revenue tracking
      final dynamic rawAmount =
          _transactionData!['amount'] ?? _transactionData!['totalAmount'];
      final double amount = rawAmount is double
          ? rawAmount
          : rawAmount is int
              ? rawAmount.toDouble()
              : rawAmount is String
                  ? double.tryParse(rawAmount) ?? 0.0
                  : 0.0;

      final String orderDate = DateFormat('yyyy-MM-dd').format(verifiedAt);

      if (isOrder) {
        // This is an order - update the order document
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(documentId)
            .update({
          'status': 'completed',
          'paymentStatus': 'paid',
          'verifiedAt': verifiedAt,
          'verifiedBy': verifiedBy,
          'updatedAt': verifiedAt,
        });

        // Add the order to daily revenue collection
        await _updateRevenue(orderDate, amount, documentId);

        // Update the local data too
        setState(() {
          _transactionData!['status'] = 'completed';
          _transactionData!['paymentStatus'] = 'paid';
          _verificationSuccess = true;
        });
      } else {
        // This is a transaction - update transaction document
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(documentId)
            .update({
          'verified': true,
          'verifiedAt': verifiedAt,
          'verifiedBy': verifiedBy,
        });

        // Add the transaction to daily revenue collection
        await _updateRevenue(orderDate, amount, documentId);

        setState(() {
          _transactionData!['verified'] = true;
          _verificationSuccess = true;
        });
      }

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order approved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error approving transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  // Helper method to update revenue collection
  Future<void> _updateRevenue(
      String date, double amount, String orderId) async {
    final revenueRef =
        FirebaseFirestore.instance.collection('revenue').doc(date);

    // Use a transaction to safely update the revenue total
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot revenueDoc = await transaction.get(revenueRef);

      if (revenueDoc.exists) {
        // Update existing revenue document
        Map<String, dynamic> data = revenueDoc.data() as Map<String, dynamic>;
        double currentTotal = (data['total'] as num?)?.toDouble() ?? 0.0;
        List<String> orders = List<String>.from(data['orders'] ?? []);

        // Only add the revenue if this order isn't already counted
        if (!orders.contains(orderId)) {
          transaction.update(revenueRef, {
            'total': currentTotal + amount,
            'orders': FieldValue.arrayUnion([orderId]),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create a new revenue document for this date
        transaction.set(revenueRef, {
          'date': date,
          'total': amount,
          'orders': [orderId],
          'created': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Widget _buildTransactionDetails() {
    final bool isOrder = _transactionData!.containsKey('orderId');
    final String idKey = isOrder ? 'orderId' : 'transactionId';
    final String idValue = _transactionData![idKey]?.toString() ?? 'N/A';

    // Format amount properly
    final dynamic rawAmount =
        _transactionData!['amount'] ?? _transactionData!['totalAmount'];
    final String amount =
        rawAmount != null ? '₹${rawAmount.toString()}' : 'N/A';

    // Format customer name
    final String customerName = _transactionData!['customerName'] ??
        _transactionData!['userName'] ??
        'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOrder) ...[
          Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildDetailRow('${isOrder ? 'Order' : 'Transaction'} ID', idValue),
        _buildDetailRow('Amount', amount),
        _buildDetailRow('Date', _formatDate(_transactionData!['timestamp'])),
        _buildDetailRow('Customer', customerName),
        if (isOrder && _transactionData!.containsKey('status')) ...[
          _buildDetailRow(
              'Status', _transactionData!['status'].toString().toUpperCase()),
        ],
        if (isOrder && _transactionData!.containsKey('paymentStatus')) ...[
          _buildDetailRow('Payment',
              _transactionData!['paymentStatus'].toString().toUpperCase()),
        ],
        if (_verificationSuccess) ...[
          const Divider(height: 30),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Verified at ${_formatTime(DateTime.now())}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime date;

      if (timestamp is int) {
        // Handle milliseconds since epoch
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        // Try to parse as ISO string
        date = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        // Handle Firestore timestamp
        date = timestamp.toDate();
      } else {
        return 'Invalid date format';
      }

      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    } catch (e) {
      // Return the raw value if parsing fails
      return timestamp.toString();
    }
  }

  String _formatTime(dynamic timeInput) {
    try {
      DateTime date;

      if (timeInput is DateTime) {
        date = timeInput;
      } else if (timeInput is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timeInput);
      } else if (timeInput is String) {
        date = DateTime.parse(timeInput);
      } else if (timeInput is Timestamp) {
        date = timeInput.toDate();
      } else {
        return 'Invalid time format';
      }

      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeInput.toString();
    }
  }
}