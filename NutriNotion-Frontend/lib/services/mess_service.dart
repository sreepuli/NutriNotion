import 'api_client.dart';

/// Fetches daily mess menu from Spring Boot.
class MessService {
  /// GET /api/menu/{dayOfWeek} — returns a stream-like periodic poll.
  /// For real-time feel, use [getMenuForDay] in a FutureBuilder.
  Future<Map<String, dynamic>> getMenuForDay(String dayOfWeek) async {
    try {
      final data = await ApiClient.get(
              '/menu/${dayOfWeek.toLowerCase()}') as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {};
    }
  }

  /// GET /api/menu — returns the full weekly menu.
  Future<Map<String, dynamic>> getWeeklyMenu() async {
    try {
      final data =
          await ApiClient.get('/menu') as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {};
    }
  }
}
