/// Represents a single food item in a personalized meal plan.
class PersonalizedMealItem {
  final int? id;
  final String foodName;
  final String quantity;
  final int calories;
  final String mealType;
  bool isChecked;

  PersonalizedMealItem({
    this.id,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.mealType,
    this.isChecked = false,
  });

  factory PersonalizedMealItem.fromJson(Map<String, dynamic> json) {
    return PersonalizedMealItem(
      id: json['id'] as int?,
      foodName: (json['foodName'] ?? json['item'] ?? '').toString(),
      quantity: (json['quantity'] ?? '').toString(),
      calories: _parseCalories(json['calories']),
      mealType: (json['mealType'] ?? '').toString(),
      isChecked: json['isChecked'] == true,
    );
  }

  static int _parseCalories(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  PersonalizedMealItem copyWith({bool? isChecked}) {
    return PersonalizedMealItem(
      id: id,
      foodName: foodName,
      quantity: quantity,
      calories: calories,
      mealType: mealType,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  String toString() =>
      'PersonalizedMealItem(id=$id, foodName=$foodName, qty=$quantity, cal=$calories, mealType=$mealType, checked=$isChecked)';
}
