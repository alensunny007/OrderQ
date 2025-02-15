import 'package:flutter/material.dart';

class Checkout extends StatelessWidget {
  const Checkout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF53E3C6),
              Color(0xFF00122D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Item 1: ₹20.00",
                      style: TextStyle(color: Colors.white),
                    ),
                    const Text(
                      "Item 2: ₹30.00",
                      style: TextStyle(color: Colors.white),
                    ),
                    const Divider(
                      height: 32,
                      color: Colors.white70, // Light divider color
                    ),
                    const Text(
                      "Total: ₹50.00",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // Handle order confirmation or payment logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order Confirmed!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, // Accent button color
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Confirm and Pay",
                        style: TextStyle(color: Colors.black),
                         // Black text
                      ),
                    ),
                   const SizedBox(height: 50,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
