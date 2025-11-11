class FoodItem {
  final String id;
  final String name;
  final String category; // e.g., Meyve, Sebze, Protein, Tahıl, İçecek
  final int calories; // per serving kcal
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final List<String> tags; // e.g., vegan, vejetaryen, gluten-free
  final List<String> allergens; // e.g., gluten, süt, fıstık
  final String? recipeId; // Tarif ID'si (eğer bu yemek bir tarifse)
  final String description; // Yemek açıklaması
  final bool hasRecipe; // Tarifi var mı?
  // Porsiyon seçenekleri. Örn: [{'name': '100 g', 'grams': 100, 'calories': 52}]
  final List<Map<String, dynamic>> portions;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.tags = const [],
    this.allergens = const [],
    this.recipeId,
    this.description = '',
    this.hasRecipe = false,
    this.portions = const [],
  });

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    return FoodItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Diğer',
      calories: (map['calories'] ?? 0) as int,
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergens: (map['allergens'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      recipeId: map['recipeId'],
      description: map['description'] ?? '',
      hasRecipe: map['hasRecipe'] ?? false,
      portions: (map['portions'] as List?)
              ?.map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'tags': tags,
      'allergens': allergens,
      'recipeId': recipeId,
      'description': description,
      'hasRecipe': hasRecipe,
      'portions': portions,
    };
  }
}


