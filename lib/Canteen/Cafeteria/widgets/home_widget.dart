import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
      
      // Get the transaction ID or order ID from the QR data
      String transactionId = parsedData['transactionId'] ?? parsedData['orderId'];
      
      // Query Firestore to verify the transaction
      DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (transactionDoc.exists) {
        Map<String, dynamic> data = transactionDoc.data() as Map<String, dynamic>;
        
        // Check if the transaction is valid and not already used
        if (data['status'] == 'SUCCESS' && data['verified'] != true) {
          // Mark the transaction as verified
          await FirebaseFirestore.instance
              .collection('transactions')
              .doc(transactionId)
              .update({
            'verified': true,
            'verifiedAt': DateTime.now().toIso8601String(),
            'verifiedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          
          setState(() {
            _transactionData = data;
            _verificationSuccess = true;
          });
        } else {
          // Transaction already used or invalid
          setState(() {
            _transactionData = {
              ...data,
              'error': data['verified'] == true ? 'Transaction already used' : 'Invalid transaction',
            };
            _verificationSuccess = false;
          });
        }
      } else {
        // Transaction not found
        setState(() {
          _transactionData = {
            'error': 'Transaction not found',
            'scannedData': parsedData,
          };
          _verificationSuccess = false;
        });
      }
    } catch (e) {
      // Error parsing QR or database error
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
        title: const Center(child: Text('Home', style: TextStyle(color: Colors.white))),
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
                      style: TextStyle(color: Colors.white)
                    ),
                    content: const Text(
                      'Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70)
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', 
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
                              const SnackBar(
                                content: Text('Error logging out. Please try again.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: const Text('Logout',
                          style: TextStyle(color: Colors.redAccent)
                        ),
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
        child: _isScanning ? _buildQRScanner() : _transactionData != null ? _buildTransactionResult() : _buildHomeContent(),
      ),
      floatingActionButton: _isScanning 
        ? FloatingActionButton(
            backgroundColor: Color(0xFF00122D),
            onPressed: () {
              setState(() {
                _isScanning = false;
              });
            },
            child: const Icon(Icons.close, color: Colors.white),
          )
        : FloatingActionButton.extended(
            backgroundColor: Color(0xFF00122D),
            onPressed: () {
              setState(() {
                _isScanning = true;
                _transactionData = null;
                _verificationSuccess = false;
              });
            },
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text('Scan QR', style: TextStyle(color: Colors.teal)),
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
        SizedBox(height: 20),
        const Text(
          'Transaction Verification',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
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
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          padding: EdgeInsets.all(20),
          child: Text(
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
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 20),
            Text(
              _verificationSuccess ? 'Transaction Verified' : 'Verification Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _verificationSuccess ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            if (hasError) ...[
              Text(
                _transactionData!['error'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ] else ...[
              _buildTransactionDetails(),
            ],
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _transactionData = null;
                });
              },
              child: Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00122D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Transaction ID', _transactionData!['transactionId'] ?? _transactionData!['orderId'] ?? 'N/A'),
        _buildDetailRow('Amount', '₹${_transactionData!['amount'] ?? 'N/A'}'),
        _buildDetailRow('Date', _formatDate(_transactionData!['timestamp'])),
        _buildDetailRow('Customer', _transactionData!['customerName'] ?? _transactionData!['userName'] ?? 'N/A'),
        if (_verificationSuccess) ...[
          Divider(height: 30),
          Text(
            'Successfully verified at ${_formatTime(DateTime.now().toString())}',
            style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
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
              style: TextStyle(
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(dateString)}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }
}