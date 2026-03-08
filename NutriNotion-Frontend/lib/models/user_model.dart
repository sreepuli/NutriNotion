class UserModel {
  String? userId;
  String? name;
  String? email;
  double? height;
  int? weight;
  int? age;
  String? gender;
  String? activityLevel;
  String? fitnessGoal;
  String? dietType;
  List<String>? allergies;
  List<String>? dislikedFoods;
  double? bmi;
  bool profileCompleted = false;
  int? calorieTargetPerDay;

  UserModel({
    this.userId,
    this.name,
    this.email,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.activityLevel,
    this.fitnessGoal,
    this.dietType,
    this.allergies,
    this.dislikedFoods,
    this.bmi,
    this.profileCompleted = false,
    this.calorieTargetPerDay,
  });

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'heightCm': height,
        'weightKg': weight?.toDouble(),
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'goal': fitnessGoal,
        'dietaryPreferences': dietType,
        'allergies': allergies ?? [],
        'dislikedFoods': dislikedFoods ?? [],
        'bmi': bmi,
        'isProfileSetup': profileCompleted,
        'calorieTargetPerDay': calorieTargetPerDay,
      };

  UserModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId']?.toString();
    name = json['name'] as String?;
    email = json['email'] as String?;
    height = (json['heightCm'] as num?)?.toDouble() ??
        (json['height'] as num?)?.toDouble();
    weight = (json['weightKg'] as num?)?.toInt() ??
        (json['weight'] as num?)?.toInt();
    age = (json['age'] as num?)?.toInt();
    gender = json['gender'] as String?;
    activityLevel = json['activityLevel'] as String?;
    fitnessGoal = (json['goal'] as String?) ?? (json['fitnessGoal'] as String?);
    dietType = (json['dietaryPreferences'] as String?) ??
        (json['dietType'] as String?);
    allergies = _parseStringOrList(json['allergies']);
    dislikedFoods =
        _parseStringOrList(json['dislikedFoods'] ?? json['disLikedFoods']);
    bmi = (json['bmi'] as num?)?.toDouble();
    profileCompleted = (json['isProfileSetup'] as bool?) ??
        (json['onboardingCompleted'] as bool?) ??
        false;
    calorieTargetPerDay =
        (json['calorieTargetPerDay'] ?? json['dailyCalorieTarget'] as num?)
                ?.toInt() ??
            0;
  }

  static List<String> _parseStringOrList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    final s = value.toString().trim();
    if (s.isEmpty) return [];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void updateUID(String newUserId) => userId = newUserId;

  /// Format date as YYYY-MM-DD for consistent storage.
  static String formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
