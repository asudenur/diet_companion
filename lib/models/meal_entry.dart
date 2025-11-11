class MealEntry {
  final String id;
  final String userId;
  final DateTime date; // day-level date
  final String mealType; // Kahvaltı, Öğle Yemeği, Akşam Yemeği, Ara Öğün
  final String foodName;
  final int calories;
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final bool isEaten; // Yedim durumu
  final DateTime? eatenAt; // Ne zaman yendi
  final String? recipeId; // Eğer tarif varsa ID'si
  final String description; // Yemek açıklaması

  MealEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isEaten = false,
    this.eatenAt,
    this.recipeId,
    this.description = '',
  });

  factory MealEntry.fromMap(String id, Map<String, dynamic> map) {
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      // Firestore Timestamp
      try {
        // Avoid importing Timestamp here; rely on duck-typing
        final seconds = (v as dynamic).seconds as int?;
        final nanoseconds = (v as dynamic).nanoseconds as int?;
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + ((nanoseconds ?? 0) ~/ 1000000),
          );
        }
      } catch (_) {}
      return DateTime.now();
    }

    return MealEntry(
      id: id,
      userId: map['userId'] ?? '',
      date: _parseDate(map['date']),
      mealType: map['mealType'] ?? '',
      foodName: map['foodName'] ?? '',
      calories: (map['calories'] ?? 0) as int,
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      isEaten: map['isEaten'] ?? false,
      eatenAt: map['eatenAt'] != null ? _parseDate(map['eatenAt']) : null,
      recipeId: map['recipeId'],
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'isEaten': isEaten,
      'eatenAt': eatenAt,
      'recipeId': recipeId,
      'description': description,
    };
  }
}


