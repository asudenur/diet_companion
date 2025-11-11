import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_entry.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Öğün kaydetme
  Future<String> saveMealEntry(MealEntry mealEntry) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final docRef = await _firestore
          .collection('meal_entries')
          .add(mealEntry.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Öğün kaydedilemedi: $e');
    }
  }

  // Öğün güncelleme (yedim durumu için)
  Future<void> updateMealEntry(String mealEntryId, bool isEaten) async {
    try {
      await _firestore.collection('meal_entries').doc(mealEntryId).update({
        'isEaten': isEaten,
        'eatenAt': isEaten ? DateTime.now() : null,
      });
    } catch (e) {
      throw Exception('Öğün güncellenemedi: $e');
    }
  }

  // Kullanıcının günlük öğünlerini getirme
  Future<List<MealEntry>> getDailyMeals(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('meal_entries')
          .where('userId', isEqualTo: user.uid)
          .get();

      final allMeals = querySnapshot.docs
          .map((doc) => MealEntry.fromMap(doc.id, doc.data()))
          .toList();

      // Client-side tarih filtrelemesi
      return allMeals.where((meal) {
        final mealDate = meal.date;
        return mealDate.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
               mealDate.isBefore(endOfDay.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      throw Exception('Öğünler getirilemedi: $e');
    }
  }

  // Kullanıcının tüm öğünlerini getirme
  Future<List<MealEntry>> getAllMeals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final querySnapshot = await _firestore
          .collection('meal_entries')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MealEntry.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Öğünler getirilemedi: $e');
    }
  }

  // Günlük kalori toplamı
  Future<int> getDailyCalorieTotal(DateTime date) async {
    try {
      final meals = await getDailyMeals(date);
      return meals.where((meal) => meal.isEaten).fold<int>(0, (sum, meal) => sum + meal.calories);
    } catch (e) {
      throw Exception('Kalori toplamı hesaplanamadı: $e');
    }
  }

  // Öğün silme
  Future<void> deleteMealEntry(String mealEntryId) async {
    try {
      await _firestore.collection('meal_entries').doc(mealEntryId).delete();
    } catch (e) {
      throw Exception('Öğün silinemedi: $e');
    }
  }

  // Belirli bir tarih aralığındaki öğünleri getirme
  Future<List<MealEntry>> getMealsInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final querySnapshot = await _firestore
          .collection('meal_entries')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MealEntry.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Öğünler getirilemedi: $e');
    }
  }
}



