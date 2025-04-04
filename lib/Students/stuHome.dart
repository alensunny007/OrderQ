import 'package:flutter/material.dart';
import 'package:orderq/pages/studenthome/cart.dart';
import 'package:orderq/pages/studenthome/contact_us.dart';
import 'package:orderq/pages/studenthome/favourites.dart';
import 'package:orderq/pages/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orderq/services/daily_menu_service.dart';

class StuHomePage extends StatefulWidget {
  final dynamic userId;

  const StuHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<StuHomePage> createState() => _StuHomePageState();
}

class _StuHomePageState extends State<StuHomePage> {
  int _selectedIndex = 0;
  String selectedOption = 'Canteen';
  final PageController _pageController = PageController();
  List<bool> _isInCart = [];
  final Map<String, bool> _favoriteStates = {};
  final DailyMenuService _menuService = DailyMenuService();
  List<Map<String, dynamic>> availableItems = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _favoritesSubscription;
  StreamSubscription<QuerySnapshot>? _cartSubscription;
  final Map<String, List<bool>> _cartStates = {
    'canteen': [],
    'cafeteria': [],
  };

  // User data variables
  String name = "User";
  bool _isLoadingUserData = false;
  String? _profileImageUrl;
  bool _isLoadingProfileImage = false;

  // Search variables
  Timer? _searchDebounce;
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  // 3D Card Touch Effect Variables
  final Map<int, Offset> _cardTouchPositions = {};
  final Map<int, bool> _cardsBeingTouched = {};

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoadingUserData = true;
      _isLoadingProfileImage = true;
      _filteredItems = [];
    });
    _loadUserData();
    _loadDailyMenu();
    _setupFavoritesListener();
    _setupCartListener();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _favoritesSubscription?.cancel();
    _cartSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isLoadingUserData) {
        setState(() {
          _isLoadingUserData = false;
          _isLoadingProfileImage = false;
        });
      }
    });
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        
        if (userData != null) {
          setState(() {
            if (userData.containsKey('name')) {
              name = userData['name'];
            }
            
            if (userData.containsKey('profileImageUrl')) {
              _profileImageUrl = userData['profileImageUrl'];
            }
            
            _isLoadingUserData = false;
            _isLoadingProfileImage = false;
          });
        } else {
          setState(() {
            _isLoadingUserData = false;
            _isLoadingProfileImage = false;
          });
        }
      } else {
        setState(() {
          _isLoadingUserData = false;
          _isLoadingProfileImage = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUserData = false;
        _isLoadingProfileImage = false;
      });
    }
  }

  Future<void> _loadDailyMenu() async {
    try {
      final menuItems = await _menuService.getDailyMenuItems(
          selectedOption.toLowerCase(), DateTime.now());

      setState(() {
        availableItems = menuItems;
        _filteredItems = menuItems;
        _isInCart = List.generate(availableItems.length, (index) => false);
        _updateCartStatesAfterMenuLoad();
      });
    } catch (e) {
      print('Error loading daily menu: $e');
      setState(() {
        availableItems = [];
        _filteredItems = [];
        _isInCart = [];
      });
    }
  }

  void _updateCartStatesAfterMenuLoad() async {
    try {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('cart')
          .get();
      
      Set<String> cartItemIds = {};
      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        final itemId = data['id'] as String;
        cartItemIds.add(itemId);
      }
      
      String source = selectedOption.toLowerCase();
      List<bool> newCartState = List.generate(availableItems.length, (_) => false);
      
      for (int i = 0; i < availableItems.length; i++) {
        final item = availableItems[i];
        final itemId = '${source}_${item['id']}';
        
        if (cartItemIds.contains(itemId)) {
          newCartState[i] = true;
        }
      }
      
      setState(() {
        if (_cartStates.containsKey(source)) {
          _cartStates[source] = newCartState;
        }
        _isInCart = List.from(newCartState);
      });
    } catch (e) {
      print('Error updating cart states after menu load: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
    }

    setState(() {
      _searchQuery = query;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery.isNotEmpty) {
        _searchItems(_searchQuery);
      } else {
        setState(() {
          _filteredItems = availableItems;
        });
      }
    });
  }

  void _searchItems(String query) {
    setState(() {
      _filteredItems = availableItems.where((item) {
        final title = item['title'].toString().toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _setupFavoritesListener() {
    _favoritesSubscription = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _favoriteStates.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _favoriteStates[data['itemId']] = true;
        }
      });
    });
  }

  void _setupCartListener() {
    _cartSubscription = _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      Set<String> cartItemIds = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final itemId = data['id'] as String;
        cartItemIds.add(itemId);
      }
      
      setState(() {
        _cartStates['canteen'] = List.generate(availableItems.length, (index) => false);
        _cartStates['cafeteria'] = List.generate(availableItems.length, (index) => false);

        for (int i = 0; i < availableItems.length; i++) {
          final item = availableItems[i];
          final source = selectedOption.toLowerCase();
          final itemId = '${source}_${item['id']}';
          
          if (cartItemIds.contains(itemId)) {
            if (i < _cartStates[source]!.length) {
              _cartStates[source]![i] = true;
            }
          }
        }

        String source = selectedOption.toLowerCase();
        if (_cartStates.containsKey(source) && 
            _cartStates[source] != null && 
            _cartStates[source]!.length == availableItems.length) {
          _isInCart = List.from(_cartStates[source]!);
        } else {
          _isInCart = List.generate(availableItems.length, (index) => false);
        }
      });
    });
  }

  Future<void> toggleFavorite(Map<String, dynamic> item, int index) async {
    try {
      final String userId = widget.userId;
      final String itemId =
          '${selectedOption.toLowerCase()}_${item['id'] ?? DateTime.now().toString()}';

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'title': item['title'],
          'price': item['price'],
          'imageUrl': item['imageUrl'],
          'description': item['description'],
          'dateAdded': DateTime.now(),
          'itemId': itemId,
          'source': selectedOption.toLowerCase(),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorites')),
      );
    }
  }

  Future<void> toggleCart(Map<String, dynamic> item, int index) async {
    if (index >= availableItems.length || index >= _isInCart.length) {
      print('Error: Index out of bounds in toggleCart');
      return;
    }
    
    try {
      final String userId = widget.userId;
      final String source = selectedOption.toLowerCase();
      final String itemId = '${source}_${item['id']}';

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId);

      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        setState(() {
          if (_cartStates.containsKey(source) && 
              _cartStates[source] != null && 
              index < _cartStates[source]!.length) {
            _cartStates[source]![index] = false;
          }
          
          if (index < _isInCart.length) {
            _isInCart[index] = false;
          }
        });
      } else {
        await docRef.set({
          'id': itemId,
          'title': item['title'],
          'price': double.parse(item['price'].toString()),
          'imageUrl': item['imageUrl'],
          'quantity': 1,
          'source': source,
        });
        setState(() {
          if (_cartStates.containsKey(source) && 
              _cartStates[source] != null && 
              index < _cartStates[source]!.length) {
            _cartStates[source]![index] = true;
          }
          
          if (index < _isInCart.length) {
            _isInCart[index] = true;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item['title']} added to cart'),
            backgroundColor: const Color(0xFF53E3C6),
            duration: const Duration(seconds: 1),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                _onItemTapped(2);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error toggling cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating cart')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _updateSelectedOption(String option) {
    setState(() {
      selectedOption = option;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadDailyMenu();
  }

  void _updateCardTouchPosition(int index, Offset localPosition, Size cardSize) {
    setState(() {
      _cardTouchPositions[index] = localPosition;
      _cardsBeingTouched[index] = true;
    });
  }

  void _resetCardTouchPosition(int index) {
    setState(() {
      _cardsBeingTouched[index] = false;
    });
  }

  Matrix4 _getCardTransformMatrix(int index, Size cardSize) {
    if (!(_cardsBeingTouched[index] ?? false) || !_cardTouchPositions.containsKey(index)) {
      return Matrix4.identity();
    }

    final position = _cardTouchPositions[index]!;
    
    final double dx = (position.dx - (cardSize.width / 2)) / (cardSize.width / 2);
    final double dy = (position.dy - (cardSize.height / 2)) / (cardSize.height / 2);
    
    final double rotateY = dx * 0.15;
    final double rotateX = -dy * 0.1;
    
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(rotateX)
      ..rotateY(rotateY)
      ..scale(1.02)
      ..translate(0.0, 0.0, 20 * (1 - (dx.abs() + dy.abs()) / 2));
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
          const ProfilePage(),
          const CartPage(),
          const Favourites(),
          const ContactUsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF00122D),
        selectedItemColor: const Color(0xFF53E3C6),
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'MyCart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favourites'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'About Us'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF00122D),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 16, right: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF53E3C6), Color(0xFF00122D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _onItemTapped(1);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: _isLoadingProfileImage
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF00122D),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            _profileImageUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                      : null,
                                                    color: const Color(0xFF00122D),
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              print("Error loading profile image in home: $error");
                                              return const Icon(
                                                Icons.person,
                                                color: Color(0xFF00122D),
                                                size: 24,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Color(0xFF00122D),
                                          size: 24,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: _isLoadingUserData
                                  ? const SizedBox(
                                      height: 22,
                                      width: 120,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.white30,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                      ),
                                    )
                                  : Text(
                                      "Hello, $name",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ordersPage');
                        },
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'My Orders',
                      ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF00122D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
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
                                            Navigator.of(context).pop();
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
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCategoryChip("Canteen", selectedOption == "Canteen"),
                        _buildCategoryChip("Cafeteria", selectedOption == "Cafeteria"),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Popular Foods",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFoodGrid(),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GestureDetector(
          onTap: () {
            if (label == "Canteen" || label == "Cafeteria") {
              _updateSelectedOption(label);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF53E3C6) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF53E3C6) : Colors.grey.shade300,
              ),
              boxShadow: isSelected 
                ? [BoxShadow(
                    color: const Color(0xFF53E3C6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )]
                : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _filteredItems = availableItems;
                });
              },
              child: const Icon(Icons.clear, color: Colors.grey, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodGrid() {
    final itemsToDisplay = _searchQuery.isEmpty ? availableItems : _filteredItems;
    
    if (itemsToDisplay.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                ? 'No items available in $selectedOption today'
                : 'No items match "$_searchQuery"',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: itemsToDisplay.length,
      itemBuilder: (context, index) {
        final item = itemsToDisplay[index];
        return _buildFoodCard(item, index);
      },
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> item, int index) {
    bool isInCart = index < _isInCart.length ? _isInCart[index] : false;
    
    final String itemId =
        '${selectedOption.toLowerCase()}_${item['id'] ?? DateTime.now().toString()}';
    bool isFavorite = _favoriteStates[itemId] == true;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final cardSize = box.size;
        _updateCardTouchPosition(index, localPosition, cardSize);
      },
      onTapUp: (details) => _resetCardTouchPosition(index),
      onTapCancel: () => _resetCardTouchPosition(index),
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final cardSize = box.size;
        _updateCardTouchPosition(index, localPosition, cardSize);
      },
      onPanEnd: (details) => _resetCardTouchPosition(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _getCardTransformMatrix(index, const Size(160, 220)),
        transformAlignment: Alignment.center,
        child: Card(
          elevation: (_cardsBeingTouched[index] ?? false) ? 8 : 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          shadowColor: (_cardsBeingTouched[index] ?? false) 
              ? const Color(0xFF53E3C6).withOpacity(0.5)
              : Colors.black.withOpacity(0.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Image.asset(
                        item['imageUrl'],
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => toggleFavorite(item, index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00122D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedOption,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '₹${item['price']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF900C3F),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => toggleCart(item, index),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isInCart ? const Color(0xFF53E3C6) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                    color: isInCart ? Colors.white : Colors.grey.shade700,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      title: Text(item['title']),
                                      content: Text(item['description'] ?? 'No description available'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.grey,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}