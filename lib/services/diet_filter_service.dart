import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';

class DietFilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının diyet tercihlerini ve alerjilerini al
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'preferences': [], 'allergies': []};
      }

      final doc = await _firestore.collection('user_infos').doc(user.uid).get();
      
      if (!doc.exists) {
        return {'preferences': [], 'allergies': []};
      }

      final data = doc.data()!;
      return {
        'preferences': (data['dietaryPreferences'] as List?)?.map((e) => e.toString()).toList() ?? [],
        'allergies': (data['allergies'] as List?)?.map((e) => e.toString()).toList() ?? [],
        'dietType': data['selectedDietType'],
      };
    } catch (e) {
      print('Kullanıcı tercihleri alınırken hata: $e');
      return {'preferences': [], 'allergies': []};
    }
  }

  // Öğün önerilerini filtrele ve diyet tipine göre sırala
  Future<List<String>> getFilteredMeals(String mealType, List<String> availableMeals) async {
    try {
      final preferences = await getUserPreferences();
      final userPreferences = preferences['preferences'] as List<String>;
      final userAllergies = preferences['allergies'] as List<String>;
      final dietType = preferences['dietType'] as String?;

      // Diyet tipine uygun öğünler ve genel öğünler
      List<String> dietCompatibleMeals = [];
      List<String> otherMeals = [];

      for (var meal in availableMeals) {
        bool isCompatible = true;
        bool isDietCompatible = false;

        // Diyet tipine göre uyumluluk kontrolü
        if (dietType != null && dietType.isNotEmpty) {
          isDietCompatible = _isMealCompatibleWithDiet(meal, dietType);
        }

        // Vegan kontrolü
        if (userPreferences.contains('Vegan')) {
          if (_containsNonVeganFood(meal)) {
            isCompatible = false;
          }
        }

        // Vejetaryen kontrolü
        if (userPreferences.contains('Vejetaryen')) {
          if (_containsMeat(meal)) {
            isCompatible = false;
          }
        }

        // Glutensiz kontrolü
        if (userPreferences.contains('Glutensiz')) {
          if (_containsGluten(meal)) {
            isCompatible = false;
          }
        }

        // Alerji kontrolü
        for (var allergy in userAllergies) {
          if (_containsAllergen(meal, allergy)) {
            isCompatible = false;
            break;
          }
        }

        if (isCompatible) {
          // Diyet tipine uygun olanları önce ekle
          if (isDietCompatible) {
            dietCompatibleMeals.add(meal);
          } else {
            otherMeals.add(meal);
          }
        }
      }

      // Diyet tipine uygun öğünleri öne al, diğerlerini sona ekle
      List<String> sortedMeals = [...dietCompatibleMeals, ...otherMeals];
      
      return sortedMeals.isNotEmpty ? sortedMeals : availableMeals;
    } catch (e) {
      print('Öğünler filtrelenirken hata: $e');
      return availableMeals;
    }
  }

  // Öğünün diyet tipine uygun olup olmadığını kontrol et
  bool _isMealCompatibleWithDiet(String meal, String dietType) {
    final lowerMeal = meal.toLowerCase();
    
    switch (dietType) {
      case 'Keto':
        // Keto: Düşük karbonhidrat, yüksek yağ
        // Karbonhidratlı yiyeceklerden kaçın
        final ketoAvoid = ['ekmek', 'makarna', 'pirinç', 'patates', 'şeker', 'bal', 'meyve suyu', 'tam buğday', 'yulaf'];
        final ketoPreferred = ['yumurta', 'avokado', 'yağ', 'zeytin', 'peynir', 'et', 'tavuk', 'balık', 'somon', 'ceviz', 'fındık'];
        // Keto'dan kaçınılması gerekenleri içermesin
        if (ketoAvoid.any((keyword) => lowerMeal.contains(keyword))) {
          return false;
        }
        // Keto'ya uygun yiyecekler içeriyorsa true
        return ketoPreferred.any((keyword) => lowerMeal.contains(keyword));
        
      case 'Aralıklı Oruç':
        // Aralıklı oruç: Genel olarak düşük kalorili, besleyici
        // Özel bir kısıtlama yok, ama hafif öğünler tercih edilir
        final lightMealKeywords = ['salata', 'sebze', 'çorba', 'yoğurt', 'meyve', 'yeşil'];
        return lightMealKeywords.any((keyword) => lowerMeal.contains(keyword)) || 
               !lowerMeal.contains('kızartma') && !lowerMeal.contains('fast food');
        
      case 'Akdeniz':
        // Akdeniz: Zeytinyağı, sebze, meyve, balık, tam tahıl
        final mediterraneanKeywords = ['zeytin', 'zeytinyağı', 'balık', 'somon', 'ton', 'sebze', 'salata', 'tam buğday', 'baklagil', 'domates', 'salatalık'];
        return mediterraneanKeywords.any((keyword) => lowerMeal.contains(keyword)) ||
               (lowerMeal.contains('balık') || lowerMeal.contains('sebze'));
        
      case 'Su Diyeti':
        // Su diyeti: Genellikle çok düşük kalorili, sıvı ağırlıklı
        final waterDietKeywords = ['çorba', 'smoothie', 'su', 'çay', 'bitki çayı', 'limon'];
        return waterDietKeywords.any((keyword) => lowerMeal.contains(keyword));
        
      default:
        return true; // Diğer diyetler için varsayılan olarak uyumlu kabul et
    }
  }

  // Tarifleri kullanıcı tercihlerine göre filtrele
  Future<List<Recipe>> getFilteredRecipes() async {
    try {
      final preferences = await getUserPreferences();
      final userPreferences = preferences['preferences'] as List<String>;
      final userAllergies = preferences['allergies'] as List<String>;

      QuerySnapshot querySnapshot = await _firestore.collection('recipes').get();
      List<Recipe> recipes = [];

      for (var doc in querySnapshot.docs) {
        final recipe = Recipe.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        
        bool isCompatible = true;

        // Vegan kontrolü
        if (userPreferences.contains('Vegan')) {
          if (!recipe.tags.contains('vegan')) {
            isCompatible = false;
          }
        }

        // Vejetaryen kontrolü
        if (userPreferences.contains('Vejetaryen')) {
          if (recipe.tags.contains('protein') && !recipe.tags.contains('vegan') && !recipe.tags.contains('vejetaryen')) {
            isCompatible = false;
          }
        }

        // Glutensiz kontrolü
        if (userPreferences.contains('Glutensiz')) {
          if (!recipe.tags.contains('glutensiz')) {
            isCompatible = false;
          }
        }

        if (isCompatible) {
          recipes.add(recipe);
        }
      }

      return recipes;
    } catch (e) {
      print('Tarifler filtrelenirken hata: $e');
      return [];
    }
  }

  bool _containsNonVeganFood(String meal) {
    final nonVeganKeywords = ['et', 'tavuk', 'balık', 'somon', 'tuna', 'ton balığı', 'yumurta', 'süt', 'peynir', 'yoğurt'];
    final lowerMeal = meal.toLowerCase();
    return nonVeganKeywords.any((keyword) => lowerMeal.contains(keyword));
  }

  bool _containsMeat(String meal) {
    final meatKeywords = ['et', 'tavuk', 'balık', 'somon', 'tuna', 'ton balığı', 'köfte', 'ızgara'];
    final lowerMeal = meal.toLowerCase();
    return meatKeywords.any((keyword) => lowerMeal.contains(keyword));
  }

  bool _containsGluten(String meal) {
    final glutenKeywords = ['ekmek', 'buğday', 'tam buğday', 'pankek'];
    final lowerMeal = meal.toLowerCase();
    return glutenKeywords.any((keyword) => lowerMeal.contains(keyword));
  }

  bool _containsAllergen(String meal, String allergen) {
    final allergyKeywords = {
      'Fındık': ['fındık', 'hazelnut'],
      'Fıstık': ['fıstık', 'peanut'],
      'Süt': ['süt', 'milk', 'yoğurt', 'peynir'],
      'Yumurta': ['yumurta', 'egg'],
      'Balık': ['balık', 'fish', 'somon', 'tuna', 'levrek'],
      'Buğday': ['buğday', 'wheat', 'ekmek'],
    };

    final keywords = allergyKeywords[allergen] ?? [allergen.toLowerCase()];
    final lowerMeal = meal.toLowerCase();
    
    return keywords.any((keyword) => lowerMeal.contains(keyword));
  }
}
