class MacroGoals {
  final int dailyCalories;
  final int protein; // g
  final int carbs; // g
  final int fat; // g

  MacroGoals({
    required this.dailyCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MacroGoals.fromMap(Map<String, dynamic> map) {
    return MacroGoals(
      dailyCalories: (map['dailyCalories'] ?? 0) as int,
      protein: (map['protein'] ?? 0) as int,
      carbs: (map['carbs'] ?? 0) as int,
      fat: (map['fat'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyCalories': dailyCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}


