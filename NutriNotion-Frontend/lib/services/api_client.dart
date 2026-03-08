import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Central HTTP client for all Spring Boot REST API calls.
///
/// URL selection:
///  - Android emulator  → 10.0.2.2:8080  (host-machine loopback alias)
///  - Android physical  → set ApiClient.androidBaseUrl = 'http://127.0.0.1:8080/api'
///                         and run: adb reverse tcp:8080 tcp:8080
///  - Web / Desktop     → localhost:8080
class ApiClient {
  /// Override this to switch between emulator (10.0.2.2) and physical device
  /// (127.0.0.1 with adb reverse) at app startup, e.g. in main().
  static String? androidBaseUrl;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    try {
      if (Platform.isAndroid) {
        return androidBaseUrl ?? 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  static String? _authToken;
  static String? _userId;

  static void setAuth(String token, String userId) {
    _authToken = token;
    _userId = userId;
  }

  static void clearAuth() {
    _authToken = null;
    _userId = null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  static Future<dynamic> get(String path) async {
    final response =
        await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(response);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  static Future<dynamic> delete(String path) async {
    final response =
        await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(response);
  }

  static dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception('API error ${response.statusCode}: ${response.body}');
  }
}
