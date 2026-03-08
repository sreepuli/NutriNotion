/// Today's calorie summary returned by GET /api/calories/{userId}/today.
class CalorieSummary {
  final int targetCalories;
  final int consumedCalories;
  final int remainingCalories;

  const CalorieSummary({
    required this.targetCalories,
    required this.consumedCalories,
    required this.remainingCalories,
  });

  factory CalorieSummary.fromJson(Map<String, dynamic> json) {
    return CalorieSummary(
      targetCalories: (json['targetCalories'] as num?)?.toInt() ?? 0,
      consumedCalories: (json['consumedCalories'] as num?)?.toInt() ?? 0,
      remainingCalories: (json['remainingCalories'] as num?)?.toInt() ?? 0,
    );
  }

  CalorieSummary copyWith({int? consumedCalories, int? remainingCalories}) {
    return CalorieSummary(
      targetCalories: targetCalories,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      remainingCalories: remainingCalories ?? this.remainingCalories,
    );
  }

  @override
  String toString() =>
      'CalorieSummary(target=$targetCalories, consumed=$consumedCalories, remaining=$remainingCalories)';
}
