import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel();
  bool _isLoading = false;
  final UserService _userService = UserService();

  UserModel get user => _user;
  bool get isLoading => _isLoading;
  bool get isProfileComplete => _user.profileCompleted;

  String? get name => _user.name;
  String? get email => _user.email;
  int? get age => _user.age;
  double? get height => _user.height;
  int? get weight => _user.weight;
  String? get gender => _user.gender;
  String? get activityLevel => _user.activityLevel;
  String? get fitnessGoal => _user.fitnessGoal;
  String? get dietType => _user.dietType;
  List<String>? get allergies => _user.allergies;
  List<String>? get dislikedFoods => _user.dislikedFoods;
  double? get bmi => _user.bmi;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void initializeUser({String? userId, String? name, String? email}) {
    _user = UserModel(
        userId: userId, name: name, email: email, profileCompleted: false);
    notifyListeners();
  }

  void updateBasicInfo(
      {String? name, String? email, int? age, String? gender}) {
    if (name != null) _user.name = name;
    if (email != null) _user.email = email;
    if (age != null) _user.age = age;
    if (gender != null) _user.gender = gender;
    notifyListeners();
  }

  void updatePhysicalInfo({double? height, int? weight}) {
    if (height != null) _user.height = height;
    if (weight != null) _user.weight = weight;
    if (_user.height != null && _user.weight != null) {
      _user.bmi = calculateBMI();
    }
    notifyListeners();
  }

  void updateCalorieTarget(int calorieTarget) {
    _user.calorieTargetPerDay = calorieTarget;
    notifyListeners();
  }

  void updateLifestyleInfo({String? activityLevel, String? fitnessGoal}) {
    if (activityLevel != null) _user.activityLevel = activityLevel;
    if (fitnessGoal != null) _user.fitnessGoal = fitnessGoal;
    notifyListeners();
  }

  void updateDietInfo(
      {String? dietType,
      List<String>? allergies,
      List<String>? dislikedFoods}) {
    if (dietType != null) _user.dietType = dietType;
    if (allergies != null) _user.allergies = allergies;
    if (dislikedFoods != null) _user.dislikedFoods = dislikedFoods;
    notifyListeners();
  }

  void updateProfileField(String key, dynamic value) {
    switch (key.toLowerCase()) {
      case 'name':
        _user.name = value as String?;
        break;
      case 'email':
        _user.email = value as String?;
        break;
      case 'age':
        _user.age = value is int ? value : int.tryParse(value.toString());
        break;
      case 'gender':
        _user.gender = value as String?;
        break;
      case 'height':
        _user.height =
            value is double ? value : double.tryParse(value.toString());
        if (_user.height != null && _user.weight != null) {
          _user.bmi = calculateBMI();
        }
        break;
      case 'weight':
        _user.weight = value is int ? value : int.tryParse(value.toString());
        if (_user.height != null && _user.weight != null) {
          _user.bmi = calculateBMI();
        }
        break;
      case 'bmi':
        _user.bmi = value is double ? value : double.tryParse(value.toString());
        break;
      case 'activity_level':
        _user.activityLevel = value as String?;
        break;
      case 'fitness_goal':
        _user.fitnessGoal = value as String?;
        break;
      case 'diet_type':
        _user.dietType = value as String?;
        break;
      case 'allergies':
        _user.allergies = value is List<String> ? value : [value.toString()];
        break;
      case 'disliked_foods':
        _user.dislikedFoods =
            value is List<String> ? value : [value.toString()];
        break;
    }
    notifyListeners();
  }

  void markProfileComplete() {
    _user.profileCompleted = true;
    notifyListeners();
  }

  bool isBasicProfileComplete() =>
      _user.name != null && _user.age != null && _user.gender != null;

  bool isPhysicalInfoComplete() => _user.height != null && _user.weight != null;

  bool isLifestyleInfoComplete() =>
      _user.activityLevel != null && _user.fitnessGoal != null;

  bool isDietInfoComplete() => _user.dietType != null;

  double? calculateBMI() {
    if (_user.height != null && _user.weight != null) {
      final h = _user.height! / 100;
      return _user.weight! / (h * h);
    }
    return null;
  }

  String getBMICategory() {
    final bmi = calculateBMI();
    if (bmi == null) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  void loadUserFromJson(Map<String, dynamic> json) {
    _user = UserModel.fromJson(json);
    notifyListeners();
  }

  Map<String, dynamic> getUserAsJson() => _user.toMap();

  void clearUser() {
    _user = UserModel();
    notifyListeners();
  }

  void updateUserId(String userId) {
    _user.userId = userId;
    notifyListeners();
  }

  double getProfileCompletionPercentage() {
    int done = 0;
    if (isBasicProfileComplete()) done++;
    if (isPhysicalInfoComplete()) done++;
    if (isLifestyleInfoComplete()) done++;
    if (isDietInfoComplete()) done++;
    return done / 4;
  }

  String? getNextIncompleteSection() {
    if (!isBasicProfileComplete()) return 'basic_info';
    if (!isPhysicalInfoComplete()) return 'physical_info';
    if (!isLifestyleInfoComplete()) return 'lifestyle_info';
    if (!isDietInfoComplete()) return 'diet_info';
    return null;
  }

  /// Loads user profile from Spring Boot backend.
  Future<bool> loadFromBackend(String userId) async {
    try {
      setLoading(true);
      final userData = await _userService.loadUser(userId);
      if (userData != null) {
        _user = userData;
        notifyListeners();
      }
      setLoading(false);
      return userData != null;
    } catch (e) {
      setLoading(false);
      print('Error loading user: $e');
      return false;
    }
  }

  /// Backward-compatible alias for [loadFromBackend].
  Future<bool> loadFromFirestore(String userId) => loadFromBackend(userId);

  /// Persists current user profile to Spring Boot backend.
  Future<bool> saveToBackend() async {
    try {
      if (_user.userId == null) throw Exception('User ID required');
      setLoading(true);
      await _userService.saveUser(_user);
      setLoading(false);
      return true;
    } catch (e) {
      setLoading(false);
      print('Error saving user: $e');
      return false;
    }
  }

  /// Backward-compatible alias for [saveToBackend].
  Future<bool> saveToFirestore() => saveToBackend();

  /// Marks profile complete and sends the full onboarding data to the backend.
  Future<bool> completeProfile() async {
    markProfileComplete();
    try {
      if (_user.userId == null) throw Exception('User ID required');
      setLoading(true);
      await _userService.completeOnboarding(_user);
      setLoading(false);
      return true;
    } catch (e) {
      setLoading(false);
      print('Error completing profile: $e');
      return false;
    }
  }
}
