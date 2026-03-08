import 'api_client.dart';
import '../models/calorie_summary.dart';

/// Handles today's personalized meal generation, retrieval, item toggling,
/// and calorie summary via the Spring Boot REST API.
class PersonalizedMealService {
  /// GET /api/personalized-meals/{userId}/today
  Future<Map<String, dynamic>?> getTodayMeal(String userId) async {
    try {
      print('PersonalizedMealService.getTodayMeal: userId=$userId');
      final data = await ApiClient.get('/personalized-meals/$userId/today');
      print(
          'PersonalizedMealService.getTodayMeal: type=${data?.runtimeType}, value=$data');
      if (data is Map<String, dynamic>) return data;
      print('PersonalizedMealService.getTodayMeal: not a Map – returning null');
      return null;
    } catch (e) {
      print('PersonalizedMealService.getTodayMeal error: $e');
      return null;
    }
  }

  /// POST /api/personalized-meals/{userId}/generate-today
  Future<Map<String, dynamic>?> generateTodayMeal(String userId) async {
    try {
      print('PersonalizedMealService.generateTodayMeal: userId=$userId');
      final data = await ApiClient.post(
        '/personalized-meals/$userId/generate-today',
        {},
      );
      print(
          'PersonalizedMealService.generateTodayMeal: type=${data?.runtimeType}, value=$data');
      if (data is Map<String, dynamic>) return data;
      print(
          'PersonalizedMealService.generateTodayMeal: not a Map – returning null');
      return null;
    } catch (e) {
      print('PersonalizedMealService.generateTodayMeal error: $e');
      return null;
    }
  }

  /// PUT /api/personalized-meals/item/{itemId}/check
  Future<bool> checkItem(int itemId, bool checked) async {
    try {
      print(
          'PersonalizedMealService.checkItem: itemId=$itemId, checked=$checked');
      await ApiClient.put(
        '/personalized-meals/item/$itemId/check',
        {'checked': checked},
      );
      print('PersonalizedMealService.checkItem: success');
      return true;
    } catch (e) {
      print('PersonalizedMealService.checkItem error: $e');
      return false;
    }
  }

  /// GET /api/calories/{userId}/today
  Future<CalorieSummary?> getTodayCalorieSummary(String userId) async {
    try {
      print('PersonalizedMealService.getTodayCalorieSummary: userId=$userId');
      final data = await ApiClient.get('/calories/$userId/today');
      print('PersonalizedMealService.getTodayCalorieSummary: response=$data');
      if (data is Map<String, dynamic>) return CalorieSummary.fromJson(data);
      return null;
    } catch (e) {
      print('PersonalizedMealService.getTodayCalorieSummary error: $e');
      return null;
    }
  }
}
