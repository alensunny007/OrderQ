import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CafHomePage extends StatefulWidget {
  final dynamic userId;

  const CafHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<CafHomePage> createState() => _CafHomePageState();
}

class _CafHomePageState extends State<CafHomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildAddItemsPage(),
          _buildOrderedItemsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D),
        selectedItemColor: const Color(0xFF53E3C6),
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Items'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Ordered Items'),
        ],
      ),
    );
  }

  Widget _buildAddItemsPage() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    Future<void> _uploadItem() async {
      final String name = nameController.text.trim();
      final String cost = costController.text.trim();
      final String description = descriptionController.text.trim();

      if (name.isEmpty || cost.isEmpty || description.isEmpty) {
        Fluttertoast.showToast(
          msg: "Please fill in all fields",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 14.0,
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('Food').add({
          'name': name,
          'cost': cost,
          'description': description,
        });

        Fluttertoast.showToast(
          msg: "Item added successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 14.0,
        );

        nameController.clear();
        costController.clear();
        descriptionController.clear();
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Failed to add item: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Items Page',
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name of Item',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              decoration: InputDecoration(
                labelText: 'Cost of Item',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53E3C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderedItemsPage() {
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
      child: Center(
        child: Text(
          'Ordered Items Page',
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
      ),
    );
  }
}
