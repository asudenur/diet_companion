import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';

class FoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Foods collection: foods/{foodId}
  Future<List<FoodItem>> searchFoods({String? query, String? category, int? limit, bool? vegan, bool? vegetarian, List<String>? excludeAllergens}) async {
    Query<Map<String, dynamic>> ref = _db.collection('foods');
    if (category != null && category.isNotEmpty) {
      ref = ref.where('category', isEqualTo: category);
    }
    if (limit != null) {
      ref = ref.limit(limit);
    }
    final snap = await ref.get();
    final items = snap.docs
        .map((d) => FoodItem.fromMap(d.id, d.data()))
        .where((item) {
          if (query == null || query.trim().isEmpty) return true;
          final q = query.toLowerCase();
          return item.name.toLowerCase().contains(q) || item.category.toLowerCase().contains(q);
        })
        .where((item) {
          if (vegan == true && !item.tags.map((e) => e.toLowerCase()).contains('vegan')) return false;
          if (vegetarian == true && !item.tags.map((e) => e.toLowerCase()).any((t) => t == 'vegan' || t == 'vejetaryen' || t == 'vegetarian')) return false;
          if (excludeAllergens != null && excludeAllergens.isNotEmpty) {
            final itemAll = item.allergens.map((e) => e.toLowerCase()).toSet();
            for (final ex in excludeAllergens) {
              if (itemAll.contains(ex.toLowerCase())) return false;
            }
          }
          return true;
        })
        .toList();
    return items;
  }

  /// Uygulama ilk açıldığında örnek besinleri ekler (tek seferlik)
  Future<void> ensureFoodsSeeded() async {
    final snap = await _db.collection('foods').limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _db.batch();
    final foods = <Map<String, dynamic>>[
      {
        'name': 'Elma',
        'category': 'Meyve',
        'calories': 52,
        'protein': 0.3,
        'carbs': 14,
        'fat': 0.2,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Taze kırmızı elma',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 52},
          {'name': '1 orta (182 g)', 'grams': 182, 'calories': 95},
        ],
      },
      {
        'name': 'Muz',
        'category': 'Meyve',
        'calories': 89,
        'protein': 1.1,
        'carbs': 23,
        'fat': 0.3,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Olgun muz',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 89},
          {'name': '1 adet (118 g)', 'grams': 118, 'calories': 105},
        ],
      },
      {
        'name': 'Haşlanmış Yumurta',
        'category': 'Protein',
        'calories': 155,
        'protein': 13,
        'carbs': 1.1,
        'fat': 11,
        'tags': ['vejetaryen', 'gluten-free'],
        'allergens': ['yumurta'],
        'description': 'Orta pişmiş',
        'hasRecipe': false,
        'portions': [
          {'name': '1 adet', 'grams': 50, 'calories': 78},
          {'name': '2 adet', 'grams': 100, 'calories': 156},
        ],
      },
      {
        'name': 'Izgara Tavuk Göğsü',
        'category': 'Protein',
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 3.6,
        'tags': ['gluten-free'],
        'allergens': [],
        'description': 'Derisiz, yağsız',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 165},
          {'name': '150 g', 'grams': 150, 'calories': 248},
        ],
      },
      {
        'name': 'Yoğurt (Sade)',
        'category': 'İçecek',
        'calories': 59,
        'protein': 10.0,
        'carbs': 3.6,
        'fat': 0.4,
        'tags': ['vejetaryen', 'gluten-free'],
        'allergens': ['süt'],
        'description': 'Yağsız yoğurt',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 59},
          {'name': '1 kase (200 g)', 'grams': 200, 'calories': 118},
        ],
      },
      {
        'name': 'Kinoa (Pişmiş)',
        'category': 'Tahıl',
        'calories': 120,
        'protein': 4.4,
        'carbs': 21.3,
        'fat': 1.9,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Haşlanmış kinoa',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 120},
          {'name': '1 su bardağı (185 g)', 'grams': 185, 'calories': 222},
        ],
      },
    ];

    for (final f in foods) {
      final doc = _db.collection('foods').doc();
      batch.set(doc, f);
    }
    await batch.commit();
  }

  // Favorites: users/{uid}/favorites/{foodId}
  Future<void> toggleFavorite(FoodItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final doc = _db.collection('users').doc(uid).collection('favorites').doc(item.id);
    final exists = await doc.get();
    if (exists.exists) {
      await doc.delete();
    } else {
      await doc.set(item.toMap());
    }
  }

  Stream<List<FoodItem>> favoritesStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((d) => FoodItem.fromMap(d.id, d.data())).toList());
  }

  // Meal history: users/{uid}/meal_history/{entryId}
  Future<void> addMealEntry(MealEntry entry) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    await _db.collection('users').doc(uid).collection('meal_history').add({
      ...entry.toMap(),
      'date': Timestamp.fromDate(entry.date),
    });
  }

  Stream<List<MealEntry>> mealHistoryStream({DateTime? start, DateTime? end, int? minCalories, int? maxCalories}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    Query<Map<String, dynamic>> ref = _db.collection('users').doc(uid).collection('meal_history');
    if (start != null) {
      ref = ref.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }
    if (end != null) {
      ref = ref.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }
    return ref.snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final data = d.data();
        final ts = data['date'] as Timestamp?;
        final map = {
          ...data,
          'date': ts != null ? ts.toDate() : DateTime.now(),
        };
        return MealEntry.fromMap(d.id, map);
      }).where((e) {
        final okMin = minCalories == null || e.calories >= minCalories;
        final okMax = maxCalories == null || e.calories <= maxCalories;
        return okMin && okMax;
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<Map<DateTime, int>> dailyCaloriesBetween(DateTime start, DateTime end) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('meal_history')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    final Map<DateTime, int> totals = {};
    for (final d in snap.docs) {
      final ts = (d.data()['date'] as Timestamp).toDate();
      final day = DateTime(ts.year, ts.month, ts.day);
      final cals = (d.data()['calories'] ?? 0) as int;
      totals[day] = (totals[day] ?? 0) + cals;
    }
    return totals;
  }
}


