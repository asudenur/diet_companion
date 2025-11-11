import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/plan_service.dart';

/// Firebase'e diyet plan şablonlarını yüklemek için script
/// 
/// Kullanım: Bu script'i çalıştırmak için main.dart'ta çağırın veya
/// ayrı bir script olarak çalıştırın.
Future<void> seedMealPlanTemplates() async {
  try {
    final db = FirebaseFirestore.instance;
    
    // Tüm kalori aralıkları için planları al
    final calorieRanges = [
      {'range': '1200-1400', 'plans': MealPlanTemplates.getLowCaloriePlans()},
      {'range': '1400-1600', 'plans': MealPlanTemplates.getMediumLowCaloriePlans()},
      {'range': '1600-1800', 'plans': MealPlanTemplates.getMediumCaloriePlans()},
      {'range': '1800-2000', 'plans': MealPlanTemplates.getMediumHighCaloriePlans()},
      {'range': '2000-2200', 'plans': MealPlanTemplates.getHighCaloriePlans()},
      {'range': '2200+', 'plans': MealPlanTemplates.getVeryHighCaloriePlans()},
    ];

    for (final rangeData in calorieRanges) {
      final calorieRange = rangeData['range'] as String;
      final plans = rangeData['plans'] as List<Map<String, Map<String, String>>>;
      
      print('📝 $calorieRange kalori aralığı için planlar yükleniyor...');
      
      // Önce mevcut planları sil (isteğe bağlı)
      final existingPlans = await db
          .collection('meal_plan_templates')
          .where('calorieRange', isEqualTo: calorieRange)
          .get();
      
      final batch = db.batch();
      for (final doc in existingPlans.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Yeni planları ekle
      for (int dayIndex = 0; dayIndex < plans.length; dayIndex++) {
        final dayPlan = plans[dayIndex];
        
        // Firebase formatına dönüştür
        final meals = <String, Map<String, dynamic>>{};
        for (final entry in dayPlan.entries) {
          meals[entry.key] = {
            'name': entry.value['name'] ?? entry.key,
            'description': entry.value['description'] ?? '',
            'calories': entry.value['calories'] ?? '0',
          };
        }
        
        await db.collection('meal_plan_templates').add({
          'calorieRange': calorieRange,
          'dayIndex': dayIndex,
          'meals': meals,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      print('✅ $calorieRange kalori aralığı için ${plans.length} günlük plan yüklendi');
    }
    
    print('🎉 Tüm plan şablonları başarıyla Firebase\'e yüklendi!');
  } catch (e) {
    print('❌ Hata: $e');
    rethrow;
  }
}

/// Firebase'de index oluşturmak için gerekli bilgileri yazdır
void printIndexInfo() {
  print('''
📋 Firebase Firestore Index Bilgisi:

Collection: meal_plan_templates
Fields to index:
  - calorieRange (Ascending)
  - dayIndex (Ascending)

Firebase Console'da şu index'i oluşturun:
1. Firebase Console > Firestore Database > Indexes
2. Create Index
3. Collection ID: meal_plan_templates
4. Fields:
   - calorieRange: Ascending
   - dayIndex: Ascending
5. Query scope: Collection
6. Create
  ''');
}

