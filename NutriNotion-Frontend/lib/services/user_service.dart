import '../models/user_model.dart';
import 'api_client.dart';

/// REST service for user profile/onboarding operations against Spring Boot.
class UserService {
  /// GET /api/onboarding/{userId}
  Future<UserModel?> loadUser(String userId) async {
    try {
      final data =
          await ApiClient.get('/onboarding/$userId') as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// PUT /api/onboarding/{userId}
  Future<void> saveUser(UserModel user) async {
    if (user.userId == null) throw Exception('userId is required');
    await ApiClient.put('/onboarding/${user.userId}', user.toMap());
  }

  /// PUT /api/onboarding/{userId}
  Future<void> completeOnboarding(UserModel user) async {
    if (user.userId == null) throw Exception('userId is required');
    await ApiClient.put('/onboarding/${user.userId}', user.toMap());
  }
}
