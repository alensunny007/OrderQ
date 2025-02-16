import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orderq/utils/cafeteria_data.dart';
import 'package:orderq/utils/food_data.dart';


class DailyMenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getTodayMenu(String type) async {
    try {
      final today = DateTime.now();
      final todayStr =
          DateTime(today.year, today.month, today.day).toIso8601String();

      final snapshot = await _firestore
          .collection('dailyMenu')
          .where('type', isEqualTo: type.toLowerCase())
          .where('date', isEqualTo: todayStr)
          .where('isAvailable', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['foodId'] as String)
          .toList();
    } catch (e) {
      print('Error getting daily menu: $e');
      return [];
    }
  }

  Future<void> setDailyMenu({
    required List<String> foodIds,
    required String type,
    required DateTime date,
  }) async {
    try {
      final batch = _firestore.batch();
      final dateStr =
          DateTime(date.year, date.month, date.day).toIso8601String();

      // First, delete existing items
      final existing = await _firestore
          .collection('dailyMenu')
          .where('type', isEqualTo: type.toLowerCase())
          .where('date', isEqualTo: dateStr)
          .get();

      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }

      // Add new items
      for (var foodId in foodIds) {
        final docRef = _firestore.collection('dailyMenu').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'foodId': foodId.toString(), // Ensure foodId is stored as String
          'type': type.toLowerCase(),
          'date': dateStr,
          'isAvailable': true,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error setting daily menu: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDailyMenuItems(
      String type, DateTime date) async {
    try {
      final dateStr =
          DateTime(date.year, date.month, date.day).toIso8601String();

      final snapshot = await _firestore
          .collection('dailyMenu')
          .where('type', isEqualTo: type.toLowerCase())
          .where('date', isEqualTo: dateStr)
          .where('isAvailable', isEqualTo: true)
          .get();

      final foodIds =
          snapshot.docs.map((doc) => doc.data()['foodId'] as String).toList();

      // Get items from the appropriate list based on type
      final sourceList =
          type.toLowerCase() == 'canteen' ? foodItems : cafefoodItems;
      return sourceList.where((item) => foodIds.contains(item['id'])).toList();
    } catch (e) {
      print('Error getting daily menu items: $e');
      return [];
    }
  }
}
