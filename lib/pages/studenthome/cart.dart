import 'package:flutter/material.dart';
import 'package:orderq/pages/studenthome/checkout.dart';
import 'package:orderq/utils/cart_data.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

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
                  "My Cart",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(cartItems[index]['imageUrl'],
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      title: Text(cartItems[index]['title']),
                      subtitle: Text("₹${cartItems[index]['price']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Logic for removing items
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              
              
              width: double.infinity, // Full width of the screen
              child: Card(
                
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8), // Space between text and amount
                    const Text(
                      "Total Amount: \₹50.00",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), // Space between amount and button
                    ElevatedButton(
                      
                       onPressed: () {
                  // Navigate to CheckoutPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Checkout()),
                  );
                },// Replace with your checkout logic
                      child: const Text("Checkout"),
                      
                    ),
                    const SizedBox(height: 8), // Space below the button
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22,)
          ],
        ),
      ),
    );
  }
}
