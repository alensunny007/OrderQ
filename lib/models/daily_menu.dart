class DailyMenu {
  final String id;
  final String foodId;
  final String type; // 'canteen' or 'cafeteria'
  final DateTime date;
  final bool isAvailable;

  DailyMenu({
    required this.id,
    required this.foodId,
    required this.type,
    required this.date,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': foodId,
      'type': type,
      'date': date.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }

  factory DailyMenu.fromMap(Map<String, dynamic> map) {
    return DailyMenu(
      id: map['id'],
      foodId: map['foodId'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      isAvailable: map['isAvailable'],
    );
  }
}