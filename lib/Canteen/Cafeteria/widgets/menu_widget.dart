import 'package:flutter/material.dart';

import '../../../services/daily_menu_service.dart';
import '../../../utils/food_data.dart';
import '../../../utils/cafeteria_data.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  final DailyMenuService _menuService = DailyMenuService();
  String selectedType = 'canteen';
  DateTime selectedDate = DateTime.now();
  List<String> selectedFoodIds = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selector
              SafeArea(
                child: Card(
                  child: Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Select Date',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: TextButton(
                            child: Text(
                              selectedDate.toString().split(' ')[0],
                              style: const TextStyle(color: Color(0xFF00122D)),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 7)),
                              );
                              if (date != null) {
                                setState(() => selectedDate = date);
                                _loadSelectedItems();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Type Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton('canteen', 'Canteen'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeButton('cafeteria', 'Cafeteria'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Food Items List
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          key: PageStorageKey<String>(selectedType),
                          padding: const EdgeInsets.all(8),
                          itemCount: selectedType == 'canteen'
                              ? foodItems.length
                              : cafefoodItems.length,
                          itemBuilder: (context, index) {
                            final item = selectedType == 'canteen'
                                ? foodItems[index]
                                : cafefoodItems[index];
                            return CheckboxListTile(
                              title: Text(item['title']),
                              subtitle: Text('₹${item['price']}'),
                              secondary: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  item['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              value: selectedFoodIds.contains(item['id']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedFoodIds.add(item['id']);
                                  } else {
                                    selectedFoodIds.remove(item['id']);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00122D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveMenu,
                    child: const Text('Save Daily Menu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedType == type ? const Color(0xFF00122D) : Colors.white,
        foregroundColor:
            selectedType == type ? Colors.white : const Color(0xFF00122D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedType = type;
          selectedFoodIds.clear();
        });
        _loadSelectedItems();
      },
      child: Text(label),
    );
  }

  Future<void> _loadSelectedItems() async {
    try {
      final items =
          await _menuService.getDailyMenuItems(selectedType, selectedDate);

      if (!mounted) return;

      setState(() {
        selectedFoodIds = items.map((item) => item['id'].toString()).toList();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading menu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveMenu() async {
    try {
      await _menuService.setDailyMenu(
        foodIds: selectedFoodIds,
        type: selectedType,
        date: selectedDate,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu saved successfully!'),
          backgroundColor: Color(0xFF00122D),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving menu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
