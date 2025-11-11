class UserInfoModel {
  final String uid;
  final double height; // boy (cm)
  final double weight; // kilo (kg)
  final String gender; // cinsiyet
  final int age; // yaş
  final String activityLevel; // hareket durumu
  final double calculatedCalories; // hesaplanan kalori
  final List<String> dietaryPreferences; // Vegan, Vejetaryen, Glutensiz, Su diyeti, vb.
  final List<String> allergies; // Fındık, Süt, Gluten, vb.
  final String? selectedDietType; // Seçili diyet tipi

  UserInfoModel({
    required this.uid,
    required this.height,
    required this.weight,
    required this.gender,
    required this.age,
    required this.activityLevel,
    required this.calculatedCalories,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.selectedDietType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'height': height,
      'weight': weight,
      'gender': gender,
      'age': age,
      'activityLevel': activityLevel,
      'calculatedCalories': calculatedCalories,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'selectedDietType': selectedDietType,
    };
  }

  factory UserInfoModel.fromMap(Map<String, dynamic> map) {
    return UserInfoModel(
      uid: map['uid'],
      height: map['height'],
      weight: map['weight'],
      gender: map['gender'],
      age: map['age'],
      activityLevel: map['activityLevel'],
      calculatedCalories: map['calculatedCalories'],
      dietaryPreferences: (map['dietaryPreferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergies: (map['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      selectedDietType: map['selectedDietType'],
    );
  }
} 