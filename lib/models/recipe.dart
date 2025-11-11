class Recipe {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients; // Malzemeler listesi
  final List<String> instructions; // Yapılış adımları
  final int prepTime; // Hazırlık süresi (dakika)
  final int cookTime; // Pişirme süresi (dakika)
  final int servings; // Kaç kişilik
  final int calories; // Toplam kalori
  final double protein; // Protein (g)
  final double carbs; // Karbonhidrat (g)
  final double fat; // Yağ (g)
  final List<String> tags; // Etiketler (vegan, glutensiz, vb.)
  final String difficulty; // Kolay, Orta, Zor
  final String imageUrl; // Resim URL'i (opsiyonel)
  final String category; // Kahvaltı, Öğle, Akşam, Ara Öğün

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tags = const [],
    required this.difficulty,
    this.imageUrl = '',
    required this.category,
  });

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    return Recipe(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ingredients: (map['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      instructions: (map['instructions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      prepTime: (map['prepTime'] ?? 0) as int,
      cookTime: (map['cookTime'] ?? 0) as int,
      servings: (map['servings'] ?? 1) as int,
      calories: (map['calories'] ?? 0) as int,
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      difficulty: map['difficulty'] ?? 'Orta',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'Diğer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'tags': tags,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  // Toplam süre hesaplama
  int get totalTime => prepTime + cookTime;

  // Porsiyon başına kalori hesaplama
  int get caloriesPerServing => (calories / servings).round();

  // Porsiyon başına makro besinler
  double get proteinPerServing => protein / servings;
  double get carbsPerServing => carbs / servings;
  double get fatPerServing => fat / servings;
}



