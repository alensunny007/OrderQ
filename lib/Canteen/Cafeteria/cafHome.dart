import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orderq/Canteen/Cafeteria/widgets/home_widget.dart';
import 'package:orderq/Canteen/Cafeteria/widgets/menu_widget.dart';
import 'package:orderq/Canteen/Cafeteria/widgets/orders_widget.dart';

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
        children: const [
          HomeWidget(),
          MenuWidget(),
          OrdersWidget(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D),
        selectedItemColor: const Color(0xFF53E3C6),
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Menu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Orders'),
        ],
      ),
    );
  }


 
}
