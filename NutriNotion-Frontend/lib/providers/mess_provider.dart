import 'package:flutter/material.dart';
import '../services/mess_service.dart';

class MessProvider extends ChangeNotifier {
  final MessService _messService = MessService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _menuData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get menuData => _menuData;

  /// Loads the menu for today automatically based on the current weekday.
  Future<void> loadTodayMenu() async {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final dayName = days[DateTime.now().weekday - 1];
    await getMenuForDay(dayName);
  }

  Future<Map<String, dynamic>?> getMenuForDay(String dayOfWeek) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _menuData = await _messService.getMenuForDay(dayOfWeek);
      return _menuData;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getWeeklyMenu() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _messService.getWeeklyMenu();
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
