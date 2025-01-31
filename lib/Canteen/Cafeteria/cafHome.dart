import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orderq/pages/cart.dart';
import 'package:orderq/pages/contact_us.dart';
import 'package:orderq/pages/favourites.dart';
import 'package:orderq/pages/profile.dart';
import 'package:orderq/utils/food_data.dart';
import 'package:orderq/utils/favour_data.dart';
import 'package:orderq/utils/cafeteria_data.dart';

class CafHomePage extends StatefulWidget {
  final dynamic userId;

  const CafHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<CafHomePage> createState() => _CafHomePageState();
}

class _CafHomePageState extends State<CafHomePage> {
  int _selectedIndex = 0;
  String selectedOption = 'Canteen';
  final PageController _pageController = PageController();
  final List<bool> _isInCart = List.generate(foodItems.length, (_) => false);
  final List<bool> _isFavorite = List.generate(foodItems.length, (_) => false);

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
          _buildHomePage(),
          _buildAddItemsPage(),
          _buildOrderedItemsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D),
        selectedItemColor: const Color(0xFF53E3C6),
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Items'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Ordered Items'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Hello, User", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFoodGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemsPage() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? imageUrl;

    Future<void> _uploadItem() async {
      final String name = nameController.text.trim();
      final String cost = costController.text.trim();
      final String description = descriptionController.text.trim();

      if (name.isEmpty || cost.isEmpty || description.isEmpty ) {
        Fluttertoast.showToast(
          msg: "Please fill in all fields and upload an image",
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
        setState(() {
          imageUrl = null;
        });
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

    /*Future<void> _pickImage() async {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        try {
          // Upload the image to Firebase Storage
          final Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('food_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
          final UploadTask uploadTask = storageReference.putFile(File(image.path));
          final TaskSnapshot downloadUrl = await uploadTask;
          final String url = await downloadUrl.ref.getDownloadURL();

          setState(() {
            imageUrl = url;
          });

          Fluttertoast.showToast(
            msg: "Image uploaded successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        } catch (e) {
          Fluttertoast.showToast(
            msg: "Failed to upload image: $e",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "No image selected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 14.0,
        );
      }
    }*/

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
              style: TextStyle(color: Colors.white, fontSize: 24),
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
              style: const TextStyle(color: Colors.white),
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
              style: const TextStyle(color: Colors.white),
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
            
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadItem,
              child: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF53E3C6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
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
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 24),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String option) {
    bool isSelected = selectedOption == option;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedOption = option;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.amber : Colors.white,
        foregroundColor: isSelected ? Colors.black : Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(option),
    );
  }

  Widget _buildFoodGrid() {
    List<Map<String, dynamic>> items = selectedOption == 'Canteen' ? foodItems : cafefoodItems;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: Colors.black45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(items[index]['imageUrl'], width: double.infinity, height: 120, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(items[index]['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₹${items[index]['price']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(items[index]['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isFavorite[index] = !_isFavorite[index]),
                      icon: Icon(Icons.favorite, color: _isFavorite[index] ? Colors.red : Colors.black),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _isInCart[index] = !_isInCart[index]),
                      icon: Icon(Icons.shopping_cart, color: _isInCart[index] ? Colors.red : Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}