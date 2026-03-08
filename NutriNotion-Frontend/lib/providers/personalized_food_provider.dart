import 'package:flutter/material.dart';
import '../models/calorie_summary.dart';
import '../models/personalized_meal_item.dart';
import '../services/personalized_meal_service.dart';

/// Provider managing today's personalized meal plan and calorie summary.
class PersonalizedMealProvider extends ChangeNotifier {
  final PersonalizedMealService _service = PersonalizedMealService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, List<PersonalizedMealItem>> _mealsByType = {};
  CalorieSummary? _calorieSummary;
  String? _nutritionTip;
  final Set<int> _togglingIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, List<PersonalizedMealItem>> get mealsByType => _mealsByType;
  CalorieSummary? get calorieSummary => _calorieSummary;
  String? get nutritionTip => _nutritionTip;

  static const List<String> _mealOrder = [
    'Breakfast',
    'Lunch',
    'Snacks',
    'Dinner',
  ];

  /// Returns meal types in display order, filtered to those present today.
  List<String> get orderedMealTypes =>
      _mealOrder.where((t) => _mealsByType.containsKey(t)).toList();

  /// True while item with [id] is being toggled via the backend.
  bool isToggling(int? id) => id != null && _togglingIds.contains(id);

  // ─── Data Loading ─────────────────────────────────────────────────────────

  /// Loads today's meal items and calorie summary concurrently.
  Future<void> loadTodayData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print('PersonalizedMealProvider.loadTodayData: userId=$userId');
      await Future.wait([
        _loadMeals(userId),
        _loadCalorieSummary(userId),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
      print('PersonalizedMealProvider.loadTodayData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates today's meal plan via Gemini and refreshes state.
  /// Called from the onboarding generating screen.
  Future<bool> generateTodayMeal(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      print('PersonalizedMealProvider.generateTodayMeal: userId=$userId');
      final raw = await _service.generateTodayMeal(userId);
      if (raw != null) {
        _applyRawMeals(raw);
        await _loadCalorieSummary(userId);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      print('PersonalizedMealProvider.generateTodayMeal error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMeals(String userId) async {
    Map<String, dynamic>? raw = await _service.getTodayMeal(userId);
    raw ??= await _service.generateTodayMeal(userId);
    print(
        'PersonalizedMealProvider._loadMeals: raw keys=${raw?.keys.toList()}');
    if (raw == null) {
      _mealsByType = {};
      _nutritionTip = null;
      return;
    }
    _applyRawMeals(raw);
  }

  void _applyRawMeals(Map<String, dynamic> raw) {
    _nutritionTip = (raw['nutritionTip'] ?? raw['nutrition_tip'])?.toString();
    final grouped = <String, List<PersonalizedMealItem>>{};
    for (final entry in raw.entries) {
      final k = entry.key;
      if (k == 'nutritionTip' ||
          k == 'nutrition_tip' ||
          k == 'id' ||
          k == 'userId' ||
          k == 'date') continue;
      final normalizedKey =
          k.isNotEmpty ? k[0].toUpperCase() + k.substring(1) : k;
      final items = _parseMealItems(entry.value, normalizedKey);
      if (items.isNotEmpty) grouped[normalizedKey] = items;
    }
    print(
        'PersonalizedMealProvider._applyRawMeals: keys=${grouped.keys.toList()}, tip=$_nutritionTip');
    _mealsByType = grouped;
  }

  Future<void> _loadCalorieSummary(String userId) async {
    final summary = await _service.getTodayCalorieSummary(userId);
    print('PersonalizedMealProvider._loadCalorieSummary: $summary');
    _calorieSummary = summary;
  }

  // ─── Item Toggle ──────────────────────────────────────────────────────────

  /// Optimistically toggles [item]'s checked state and syncs with backend.
  Future<void> toggleItem(String userId, PersonalizedMealItem item) async {
    final newChecked = !item.isChecked;
    final id = item.id;
    if (id != null) _togglingIds.add(id);

    // Optimistic update – immediately reflect in UI
    _updateItemLocally(item, newChecked);
    _updateCalorieSummaryLocally(item.calories, newChecked);
    notifyListeners();

    try {
      bool success = false;
      if (id != null) {
        print(
            'PersonalizedMealProvider.toggleItem: id=$id, newChecked=$newChecked');
        success = await _service.checkItem(id, newChecked);
      }
      if (success) {
        _errorMessage = null;
        // Refresh authoritative summary from backend
        await _loadCalorieSummary(userId);
      } else {
        // Revert on failure
        _updateItemLocally(item, item.isChecked);
        _updateCalorieSummaryLocally(item.calories, item.isChecked);
        _errorMessage = 'Failed to update item. Please try again.';
      }
    } catch (e) {
      _updateItemLocally(item, item.isChecked);
      _updateCalorieSummaryLocally(item.calories, item.isChecked);
      _errorMessage = e.toString();
      print('PersonalizedMealProvider.toggleItem error: $e');
    } finally {
      if (id != null) _togglingIds.remove(id);
      notifyListeners();
    }
  }

  // ─── Local Mutations ──────────────────────────────────────────────────────

  /// Adds [item] to the local meal list for [mealType] without a server call.
  void addItemLocally(String mealType, PersonalizedMealItem item) {
    final list = _mealsByType[mealType] ?? [];
    _mealsByType[mealType] = [...list, item];
    notifyListeners();
  }

  void _updateItemLocally(PersonalizedMealItem item, bool newChecked) {
    for (final type in _mealsByType.keys) {
      final list = _mealsByType[type]!;
      final idx = list.indexWhere((e) =>
          (e.id != null && e.id == item.id) || e.foodName == item.foodName);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isChecked: newChecked);
        return;
      }
    }
  }

  void _updateCalorieSummaryLocally(int calories, bool increment) {
    if (_calorieSummary == null) return;
    final delta = increment ? calories : -calories;
    final newConsumed =
        (_calorieSummary!.consumedCalories + delta).clamp(0, 99999);
    final newRemaining =
        (_calorieSummary!.targetCalories - newConsumed).clamp(0, 99999);
    _calorieSummary = _calorieSummary!.copyWith(
      consumedCalories: newConsumed,
      remainingCalories: newRemaining,
    );
  }

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Converts a raw backend meal field value into a typed list.
  ///
  /// Accepts:
  ///  - `List` of maps  → `PersonalizedMealItem.fromJson` each element.
  ///  - Comma-separated `String` → split and parse name + parenthetical quantity.
  ///  - Anything else → empty list (no crash).
  List<PersonalizedMealItem> _parseMealItems(dynamic value, String mealType) {
    if (value is List) {
      return value.map<PersonalizedMealItem>((e) {
        if (e is Map<String, dynamic>) {
          final withType = Map<String, dynamic>.from(e)
            ..putIfAbsent('mealType', () => mealType);
          return PersonalizedMealItem.fromJson(withType);
        }
        return PersonalizedMealItem(
            foodName: e.toString(),
            quantity: '',
            calories: 0,
            mealType: mealType);
      }).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      final itemRegex = RegExp(r'^(.+?)\s*\(([^)]+)\)$');
      return value
          .split(',')
          .map((raw) {
            final s = raw.trim();
            if (s.isEmpty) return null;
            final match = itemRegex.firstMatch(s);
            if (match != null) {
              return PersonalizedMealItem(
                foodName: match.group(1)!.trim(),
                quantity: match.group(2)!.trim(),
                calories: 0,
                mealType: mealType,
              );
            }
            return PersonalizedMealItem(
                foodName: s, quantity: '', calories: 0, mealType: mealType);
          })
          .whereType<PersonalizedMealItem>()
          .toList();
    }
    return [];
  }
}
