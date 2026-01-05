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
      {
        'name': 'Portakal',
        'category': 'Meyve',
        'calories': 47,
        'protein': 0.9,
        'carbs': 12,
        'fat': 0.1,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Taze portakal',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 47},
          {'name': '1 adet (150 g)', 'grams': 150, 'calories': 71},
        ],
      },
      {
        'name': 'Beyaz Peynir',
        'category': 'Protein',
        'calories': 264,
        'protein': 18,
        'carbs': 1.5,
        'fat': 21,
        'tags': ['vejetaryen', 'gluten-free'],
        'allergens': ['süt'],
        'description': 'Tam yağlı beyaz peynir',
        'hasRecipe': false,
        'portions': [
          {'name': '30 g', 'grams': 30, 'calories': 79},
          {'name': '50 g', 'grams': 50, 'calories': 132},
        ],
      },
      {
        'name': 'Domates',
        'category': 'Sebze',
        'calories': 18,
        'protein': 0.9,
        'carbs': 3.9,
        'fat': 0.2,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Taze domates',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 18},
          {'name': '1 orta (123 g)', 'grams': 123, 'calories': 22},
        ],
      },
      {
        'name': 'Salatalık',
        'category': 'Sebze',
        'calories': 15,
        'protein': 0.7,
        'carbs': 3.6,
        'fat': 0.1,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Taze salatalık',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 15},
          {'name': '1 adet (300 g)', 'grams': 300, 'calories': 45},
        ],
      },
      {
        'name': 'Pirinç Pilavı',
        'category': 'Tahıl',
        'calories': 130,
        'protein': 2.7,
        'carbs': 28,
        'fat': 0.3,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Haşlanmış beyaz pirinç',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 130},
          {'name': '1 kase (150 g)', 'grams': 150, 'calories': 195},
        ],
      },
      {
        'name': 'Mercimek Çorbası',
        'category': 'Protein',
        'calories': 116,
        'protein': 6.2,
        'carbs': 19,
        'fat': 1.8,
        'tags': ['vegan', 'vejetaryen'],
        'allergens': [],
        'description': 'Geleneksel mercimek çorbası',
        'hasRecipe': false,
        'portions': [
          {'name': '1 kase (250 ml)', 'grams': 250, 'calories': 116},
          {'name': '1 büyük kase (350 ml)', 'grams': 350, 'calories': 162},
        ],
      },
      {
        'name': 'Zeytinyağı',
        'category': 'Diğer',
        'calories': 884,
        'protein': 0,
        'carbs': 0,
        'fat': 100,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Sızma zeytinyağı',
        'hasRecipe': false,
        'portions': [
          {'name': '1 çay kaşığı (5 ml)', 'grams': 5, 'calories': 44},
          {'name': '1 yemek kaşığı (15 ml)', 'grams': 15, 'calories': 133},
        ],
      },
      {
        'name': 'Makarna (Pişmiş)',
        'category': 'Tahıl',
        'calories': 131,
        'protein': 5,
        'carbs': 25,
        'fat': 1.1,
        'tags': ['vegan', 'vejetaryen'],
        'allergens': ['gluten'],
        'description': 'Haşlanmış makarna',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 131},
          {'name': '1 tabak (200 g)', 'grams': 200, 'calories': 262},
        ],
      },
      {
        'name': 'Badem',
        'category': 'Atıştırmalık',
        'calories': 579,
        'protein': 21,
        'carbs': 22,
        'fat': 50,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': ['fındık'],
        'description': 'Çiğ badem',
        'hasRecipe': false,
        'portions': [
          {'name': '10 adet (14 g)', 'grams': 14, 'calories': 81},
          {'name': '30 g', 'grams': 30, 'calories': 174},
        ],
      },
      {
        'name': 'Çilek',
        'category': 'Meyve',
        'calories': 32,
        'protein': 0.7,
        'carbs': 7.7,
        'fat': 0.3,
        'tags': ['vegan', 'vejetaryen', 'gluten-free'],
        'allergens': [],
        'description': 'Taze çilek',
        'hasRecipe': false,
        'portions': [
          {'name': '100 g', 'grams': 100, 'calories': 32},
          {'name': '1 kase (150 g)', 'grams': 150, 'calories': 48},
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
    
    // meal_entries koleksiyonundan yenilen yemekleri çek
    final snap = await _db
        .collection('meal_entries')
        .where('userId', isEqualTo: uid)
        .where('isEaten', isEqualTo: true)
        .get();
    
    final Map<DateTime, int> totals = {};
    for (final d in snap.docs) {
      final data = d.data();
      final dateField = data['date'];
      DateTime entryDate;
      
      if (dateField is Timestamp) {
        entryDate = dateField.toDate();
      } else if (dateField is DateTime) {
        entryDate = dateField;
      } else {
        continue;
      }
      
      // Tarih aralığını kontrol et
      final day = DateTime(entryDate.year, entryDate.month, entryDate.day);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);
      
      if (day.isBefore(startDay) || day.isAfter(endDay)) {
        continue;
      }
      
      // Kaloriyi hesapla - components varsa seçili bileşenlerin kalorilerini topla
      int calValue = 0;
      if (data['components'] != null && (data['components'] as List).isNotEmpty) {
        final components = List<Map<String, dynamic>>.from(data['components'] as List);
        final selectedComponents = components.where((component) => component['isSelected'] == true);
        
        for (var component in selectedComponents) {
          final cals = component['calories'] ?? 0;
          calValue += cals is int ? cals : (cals as num).toInt();
        }
      } else {
        // Components yoksa, öğünün toplam kalorisini kullan
        final cals = (data['calories'] ?? 0);
        calValue = cals is int ? cals : (cals as num).toInt();
      }
      
      totals[day] = (totals[day] ?? 0) + calValue;
    }
    return totals;
  }
}
