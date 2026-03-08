import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/api_client.dart';

/// Lightweight user object returned after authentication.
class AppUser {
  final String uid;
  final String email;
  final String displayName;

  const AppUser(
      {required this.uid, required this.email, required this.displayName});
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _onboardingCompleted = false;

  AppUser? get currentUser => _currentUser;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;
  String? get userDisplayName => _currentUser?.displayName;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get onboardingCompleted => _onboardingCompleted;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _authService.signIn(email, password);
      // userId may come as int or String from backend
      final uid = data['userId']?.toString() ?? '';
      final token = (data['token'] as String?) ?? '';
      final name = (data['name'] as String?) ?? email;
      _onboardingCompleted = (data['onboardingCompleted'] as bool?) ?? false;
      if (token.isNotEmpty) ApiClient.setAuth(token, uid);
      _currentUser = AppUser(uid: uid, email: email, displayName: name);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _authService.signUp(email, password, name);
      final uid = data['userId']?.toString() ?? '';
      final token = (data['token'] as String?) ?? '';
      final displayName = (data['name'] as String?) ?? name;
      _onboardingCompleted = (data['onboardingCompleted'] as bool?) ?? false;
      if (token.isNotEmpty) ApiClient.setAuth(token, uid);
      _currentUser = AppUser(uid: uid, email: email, displayName: displayName);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
