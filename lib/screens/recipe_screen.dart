import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/meal_service.dart';
import '../models/meal_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class RecipeScreen extends StatefulWidget {
  final String recipeId;
  final String mealName;
  final int calories;

  const RecipeScreen({
    Key? key,
    required this.recipeId,
    required this.mealName,
    required this.calories,
  }) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  Recipe? recipe;
  bool isLoading = true;
  String? error;
  final MealService _mealService = MealService();
  
  // Bileşen bazlı onay sistemi için state
  Map<String, bool> selectedIngredients = {};
  int calculatedCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (doc.exists) {
        setState(() {
          recipe = Recipe.fromMap(widget.recipeId, doc.data()!);
          isLoading = false;
          _initializeIngredientSelection();
        });
      } else {
        setState(() {
          error = 'Tarif bulunamadı';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Tarif yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
  }

  void _initializeIngredientSelection() {
    if (recipe != null) {
      // Tüm malzemeleri varsayılan olarak seçili yap
      for (String ingredient in recipe!.ingredients) {
        selectedIngredients[ingredient] = true;
      }
      calculatedCalories = recipe!.caloriesPerServing;
    }
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      selectedIngredients[ingredient] = !(selectedIngredients[ingredient] ?? false);
      _calculateCalories();
    });
  }

  void _calculateCalories() {
    if (recipe == null) return;
    
    int selectedCount = selectedIngredients.values.where((isSelected) => isSelected).length;
    int totalIngredients = recipe!.ingredients.length;
    
    if (totalIngredients > 0) {
      double ratio = selectedCount / totalIngredients;
      calculatedCalories = (recipe!.caloriesPerServing * ratio).round();
    } else {
      calculatedCalories = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Tarifler'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Geri Dön'),
                      ),
                    ],
                  ),
                )
              : recipe != null
                  ? _buildRecipeContent()
                  : const Center(child: Text('Tarif bulunamadı')),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildRecipeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarif Başlığı ve Resim
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                if (recipe!.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      recipe!.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe!.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe!.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tarif Bilgileri
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.access_time,
                            '${recipe!.totalTime} dk',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.people,
                            '${recipe!.servings} kişilik',
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.local_fire_department,
                            '${recipe!.caloriesPerServing} kcal',
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoChip(
                        Icons.star,
                        recipe!.difficulty,
                        Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Makro Besinler
          _buildMacroNutrientsCard(),
          const SizedBox(height: 24),

          // Malzemeler
          _buildIngredientsCard(),
          const SizedBox(height: 24),

          // Yapılış
          _buildInstructionsCard(),
          const SizedBox(height: 24),

          // Yedim Butonu
          _buildEatButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroNutrientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Makro Besinler (Porsiyon Başına)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroItem(
                  'Protein',
                  '${recipe!.proteinPerServing.toStringAsFixed(1)}g',
                  Colors.red,
                  Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _buildMacroItem(
                  'Karbonhidrat',
                  '${recipe!.carbsPerServing.toStringAsFixed(1)}g',
                  Colors.blue,
                  Icons.grain,
                ),
              ),
              Expanded(
                child: _buildMacroItem(
                  'Yağ',
                  '${recipe!.fatPerServing.toStringAsFixed(1)}g',
                  Colors.orange,
                  Icons.opacity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Malzemeler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Hesaplanan: $calculatedCalories kcal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Yediğiniz malzemeleri işaretleyin:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...recipe!.ingredients.map((ingredient) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CheckboxListTile(
                  value: selectedIngredients[ingredient] ?? false,
                  onChanged: (bool? value) {
                    _toggleIngredient(ingredient);
                  },
                  title: Text(
                    ingredient,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Yapılış',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recipe!.instructions.asMap().entries.map((entry) {
            int index = entry.key + 1;
            String instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEatButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _showEatConfirmationDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Yedim! ($calculatedCalories kcal)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEatConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedim Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu öğünü yediğinizi onaylıyor musunuz?'),
            const SizedBox(height: 16),
            Text(
              '${recipe!.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('$calculatedCalories kcal (Seçilen malzemelere göre)'),
            const SizedBox(height: 8),
            Text(
              'Seçilen malzemeler:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ...selectedIngredients.entries
                .where((entry) => entry.value)
                .map((entry) => Text('• ${entry.key}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveMealEntry();
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMealEntry() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı giriş yapmamış'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final mealEntry = MealEntry(
        id: '', // Firebase otomatik ID oluşturacak
        userId: user.uid,
        date: DateTime.now(),
        mealType: recipe!.category,
        foodName: recipe!.name,
        calories: calculatedCalories,
        protein: recipe!.proteinPerServing,
        carbs: recipe!.carbsPerServing,
        fat: recipe!.fatPerServing,
        isEaten: true,
        eatenAt: DateTime.now(),
        recipeId: widget.recipeId,
        description: recipe!.description,
      );

      await _mealService.saveMealEntry(mealEntry);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe!.name} öğünü kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Ana sayfaya geri dön
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
