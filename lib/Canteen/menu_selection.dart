import 'package:flutter/material.dart';
import 'package:orderq/utils/cafeteria_data.dart';
import 'package:orderq/utils/food_data.dart';
import '../services/daily_menu_service.dart';

class MenuSelectionPage extends StatefulWidget {
  @override
  _MenuSelectionPageState createState() => _MenuSelectionPageState();
}

class _MenuSelectionPageState extends State<MenuSelectionPage> {
  final DailyMenuService _menuService = DailyMenuService();
  List<String> selectedFoodIds = [];
  String selectedType = 'canteen';
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Daily Menu'),
      ),
      body: Column(
        children: [
          // Date picker
          ListTile(
            title: Text('Select Date'),
            trailing: TextButton(
              child: Text(selectedDate.toString().split(' ')[0]),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 7)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
          ),

          // Type selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'canteen', label: Text('Canteen')),
              ButtonSegment(value: 'cafeteria', label: Text('Cafeteria')),
            ],
            selected: {selectedType},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => selectedType = newSelection.first);
            },
          ),

          // Food items list
          Expanded(
            child: ListView.builder(
              itemCount: selectedType == 'canteen' ? foodItems.length : cafefoodItems.length,
              itemBuilder: (context, index) {
                final item = selectedType == 'canteen' 
                    ? foodItems[index] 
                    : cafefoodItems[index];
                return CheckboxListTile(
                  title: Text(item['title']),
                  subtitle: Text('₹${item['price']}'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _menuService.setDailyMenu(
            foodIds: selectedFoodIds,
            type: selectedType,
            date: selectedDate,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menu updated successfully')),
          );
        },
        label: Text('Save Menu'),
        icon: Icon(Icons.save),
      ),
    );
  }
}