import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/daily_menu_service.dart';
import '../../../utils/food_data.dart';
import '../../../utils/cafeteria_data.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            Card(
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
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                      _loadSelectedItems();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTypeButton('canteen', 'Canteen'),
                _buildTypeButton('cafeteria', 'Cafeteria'),
              ],
            ),

            const SizedBox(height: 16),

            // Food Items List
            Expanded(
              child: Card(
                child: ListView.builder(
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

      setState(() {
        selectedFoodIds = items.map((item) => item['id'].toString()).toList();
      });
    } catch (e) {
      print('Error loading selected items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading menu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSelectedItemsList() {
    final items = selectedType == 'canteen' ? foodItems : cafefoodItems;
    final selectedItems =
        items.where((item) => selectedFoodIds.contains(item['id'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Selected Items for Today:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (selectedItems.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No items selected for today',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedItems.length,
            itemBuilder: (context, index) {
              final item = selectedItems[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item['imageUrl'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  item['title'],
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '₹${item['price']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _saveMenu() async {
    try {
      await _menuService.setDailyMenu(
        foodIds: selectedFoodIds,
        type: selectedType,
        date: selectedDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu saved successfully!'),
          backgroundColor: Color(0xFF00122D),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving menu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
