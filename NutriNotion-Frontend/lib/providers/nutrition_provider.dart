import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/user_api_service.dart';

class NutritionProvider extends ChangeNotifier {
  final UserApiService _firestoreServices = UserApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Recalculates BMR/TDEE-based nutrition goals from [user] and saves to the
  /// Spring Boot backend.
  Future<void> recalculateAndSaveUserNutrition(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final goals = _calculateNutritionGoals(user);
      final updatedUser = UserModel(
        userId: user.userId,
        name: user.name,
        email: user.email,
        height: user.height,
        weight: user.weight,
        age: user.age,
        gender: user.gender,
        activityLevel: user.activityLevel,
        fitnessGoal: user.fitnessGoal,
        dietType: user.dietType,
        allergies: user.allergies,
        dislikedFoods: user.dislikedFoods,
        bmi: user.bmi,
        profileCompleted: user.profileCompleted,
        calorieTargetPerDay: goals['calories']!.toInt(),
      );
      await _firestoreServices.saveUserDetails(updatedUser);
      await ApiClient.put('/users/${user.userId}/nutrition-goals', goals);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, double> _calculateNutritionGoals(UserModel user) {
    final weight = user.weight?.toDouble() ?? 70.0;
    final height = user.height ?? 170.0;
    final age = user.age ?? 25;

    // Mifflin-St Jeor BMR
    double bmr;
    if ((user.gender ?? '').toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    const multipliers = {
      'sedentary': 1.2,
      'lightly active': 1.375,
      'moderately active': 1.55,
      'very active': 1.725,
      'extra active': 1.9,
    };
    final multiplier =
        multipliers[(user.activityLevel ?? '').toLowerCase()] ?? 1.375;
    double tdee = bmr * multiplier;

    switch ((user.fitnessGoal ?? '').toLowerCase()) {
      case 'lose weight':
        tdee -= 500;
        break;
      case 'gain weight':
      case 'gain muscle':
        tdee += 300;
        break;
    }

    final calories = tdee.clamp(1200.0, 4000.0);
    return {
      'calories': calories,
      'protein': calories * 0.30 / 4,
      'carbs': calories * 0.45 / 4,
      'fat': calories * 0.25 / 9,
    };
  }
}
