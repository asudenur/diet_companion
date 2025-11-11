import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tarif getirme
  Future<Recipe?> getRecipe(String recipeId) async {
    try {
      final doc = await _firestore.collection('recipes').doc(recipeId).get();
      
      if (doc.exists) {
        return Recipe.fromMap(recipeId, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Tarif getirilemedi: $e');
    }
  }

  // Kategoriye göre tarifler getirme
  Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarifler getirilemedi: $e');
    }
  }

  // Tüm tarifleri getirme
  Future<List<Recipe>> getAllRecipes() async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarifler getirilemedi: $e');
    }
  }

  // Etiketlere göre tarifler getirme
  Future<List<Recipe>> getRecipesByTags(List<String> tags) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('tags', arrayContainsAny: tags)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarifler getirilemedi: $e');
    }
  }

  // Kalori aralığına göre tarifler getirme
  Future<List<Recipe>> getRecipesByCalorieRange(int minCalories, int maxCalories) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('calories', isGreaterThanOrEqualTo: minCalories)
          .where('calories', isLessThanOrEqualTo: maxCalories)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarifler getirilemedi: $e');
    }
  }

  // Zorluk seviyesine göre tarifler getirme
  Future<List<Recipe>> getRecipesByDifficulty(String difficulty) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('difficulty', isEqualTo: difficulty)
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarifler getirilemedi: $e');
    }
  }

  // Tarif arama
  Future<List<Recipe>> searchRecipes(String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: searchTerm + 'z')
          .get();

      return querySnapshot.docs
          .map((doc) => Recipe.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarif arama başarısız: $e');
    }
  }

  // Tarif ekleme (admin için)
  Future<String> addRecipe(Recipe recipe) async {
    try {
      final docRef = await _firestore
          .collection('recipes')
          .add(recipe.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Tarif eklenemedi: $e');
    }
  }

  // Tarif güncelleme (admin için)
  Future<void> updateRecipe(String recipeId, Recipe recipe) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update(recipe.toMap());
    } catch (e) {
      throw Exception('Tarif güncellenemedi: $e');
    }
  }

  // Tarif silme (admin için)
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).delete();
    } catch (e) {
      throw Exception('Tarif silinemedi: $e');
    }
  }
}



