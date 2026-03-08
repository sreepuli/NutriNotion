import '../models/user_model.dart';
import 'api_client.dart';

/// Handles user profile & personalized menu CRUD via Spring Boot.
class UserApiService {
  // ── User profile ───────────────────────────────────────────

  /// POST /api/users
  Future<void> addUserDetails(UserModel user) async {
    await ApiClient.post('/users', user.toMap());
  }

  /// PUT /api/users/{userId}
  Future<void> updateUserDetails(UserModel user) async {
    await ApiClient.put('/users/${user.userId}', user.toMap());
  }

  /// PUT /api/users/{userId} with merge behaviour
  Future<void> saveUserDetails(UserModel user) async {
    await ApiClient.put('/users/${user.userId}', user.toMap());
  }

  /// GET /api/users/{userId}
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      final data =
          await ApiClient.get('/users/$userId') as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// DELETE /api/users/{userId}
  Future<void> deleteUserDetails(String userId) async {
    await ApiClient.delete('/users/$userId');
  }

  /// PUT /api/users/{userId}/nutrition-goals
  Future<void> updateUserNutritionGoals(
      String userId, Map<String, dynamic> goals) async {
    await ApiClient.put('/users/$userId/nutrition-goals', goals);
  }

  // ── Personalized menu ──────────────────────────────────────

  /// PUT /api/users/{userId}/personalized-menu
  Future<void> updatePersonalizedMenu(
      String userId, Map<String, dynamic> menuData) async {
    if (menuData.isEmpty) return;
    await ApiClient.put('/users/$userId/personalized-menu', menuData);
  }

  /// PUT /api/users/{userId}/personalized-menu/{day}/{mealType}
  Future<void> updatePersonalizedFood({
    required String userId,
    required String day,
    required String mealType,
    required List<Map<String, dynamic>> updatedItems,
  }) async {
    await ApiClient.put('/users/$userId/personalized-menu/$day/$mealType',
        {'items': updatedItems});
  }

  /// GET /api/users/{userId}/personalized-menu
  Future<Map<String, dynamic>?> getPersonalizedMenuData(String userId) async {
    try {
      final data = await ApiClient.get('/users/$userId/personalized-menu')
          as Map<String, dynamic>;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/users/{userId}/personalized-menu/check
  Future<bool> checkForPersonalizedFood(String userId) async {
    try {
      final data = await ApiClient.get('/users/$userId/personalized-menu/check')
          as Map<String, dynamic>;
      return (data['shouldGenerate'] as bool?) ?? true;
    } catch (_) {
      return true;
    }
  }
}
