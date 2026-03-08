import 'api_client.dart';

/// Handles authentication via Spring Boot /api/auth endpoints.
class AuthService {
  /// POST /api/auth/login → returns {token, userId, name, email}
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final data = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    return data;
  }

  /// POST /api/auth/signup → returns {userId, name, email, onboardingCompleted}
  Future<Map<String, dynamic>> signUp(
      String email, String password, String name) async {
    final data = await ApiClient.post('/auth/signup', {
      'email': email,
      'password': password,
      'name': name,
    }) as Map<String, dynamic>;

    return {
      'userId': data['userId'] ?? '',
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'token': data['token'] ?? '',
      'onboardingCompleted': data['onboardingCompleted'] ?? false,
    };
  }

  /// POST /api/auth/logout
  Future<void> signOut() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {
      // Always clear local state even if server call fails
    } finally {
      ApiClient.clearAuth();
    }
  }
}
