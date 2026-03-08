import '../models/user_model.dart';
import 'api_client.dart';

/// Handles calorie tracking via Spring Boot /api/calories endpoints.
class CalorieTrackingService {
  /// POST /api/calories/update
  Future<void> updateCalorieIntake({
    required String userId,
    required String date,
    required int calories,
    required bool isIncrement,
    required String itemKey,
    required String itemName,
    required String mealType,
  }) async {
    await ApiClient.post('/calories/update', {
      'userId': userId,
      'date': date,
      'calories': calories,
      'isIncrement': isIncrement,
      'itemKey': itemKey,
      'itemName': itemName,
      'mealType': mealType,
    });
  }

  /// GET /api/calories/{userId}/range?start=...&end=...
  Future<Map<String, int>> getCalorieIntakeRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final start = UserModel.formatDate(startDate);
      final end = UserModel.formatDate(endDate);
      final data = await ApiClient.get(
        '/calories/$userId/range?start=$start&end=$end',
      );
      if (data is Map<String, dynamic>) {
        return data.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// GET /api/calories/{userId}/checked?date=...
  Future<int> getCheckedCalories(String userId, String date) async {
    try {
      final data = await ApiClient.get('/calories/$userId/checked?date=$date');
      if (data is Map<String, dynamic>) {
        return (data['calories'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
