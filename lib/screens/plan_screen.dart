import 'package:flutter/material.dart';
import '../services/plan_service.dart';
import '../services/recipe_service.dart';
import '../models/meal_entry.dart';
import '../models/recipe.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({Key? key}) : super(key: key);

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final PlanService _service = PlanService();
  final RecipeService _recipeService = RecipeService();
  bool _loading = false;
  List<MealEntry> _preview = [];
  
  // MealEntry'ler için recipe cache
  Map<String, Recipe?> _recipeCache = {};

  Future<void> _generateWeekly() async {
    setState(() => _loading = true);
    try {
      // Önce Firebase'den mevcut planı kontrol et
      final savedPlan = await _service.getSavedWeeklyPlan();
      if (savedPlan != null && savedPlan.isNotEmpty) {
        // Mevcut plan varsa göster
        _recipeCache.clear();
        for (final entry in savedPlan) {
          if (entry.recipeId != null && entry.recipeId!.isNotEmpty) {
            try {
              final recipe = await _recipeService.getRecipe(entry.recipeId!);
              _recipeCache[entry.recipeId!] = recipe;
            } catch (e) {
              _recipeCache[entry.recipeId!] = null;
            }
          }
        }
        setState(() {
          _preview = savedPlan;
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mevcut plan yüklendi. Yeni plan oluşturmak için tekrar basın.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Yeni plan oluştur
      final plan = await _service.generateWeeklyPlan();
      // Recipe'leri cache'le
      _recipeCache.clear();
      for (final entry in plan) {
        if (entry.recipeId != null && entry.recipeId!.isNotEmpty) {
          try {
            final recipe = await _recipeService.getRecipe(entry.recipeId!);
            _recipeCache[entry.recipeId!] = recipe;
          } catch (e) {
            // Recipe bulunamazsa null olarak kaydet
            _recipeCache[entry.recipeId!] = null;
          }
        }
      }
      setState(() {
        _preview = plan;
        _loading = false;
      });
      if (plan.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uygun tarif bulunamadı. Lütfen tarif etiketlerini kontrol edin.'), backgroundColor: Colors.orange),
        );
      } else if (plan.isNotEmpty && mounted) {
        // Plan oluşturulduğunda otomatik olarak Firebase'e kaydet
        try {
          await _service.saveWeeklyPlanToFirebase(plan);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan oluşturuldu ve Firebase\'e kaydedildi!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Plan Firebase\'e kaydedilemedi: $e');
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan oluşturulamadı: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Meal description'dan malzemeleri parse et (home_screen'deki gibi)
  List<Map<String, dynamic>> _parseMealComponents(String mealDescription) {
    List<Map<String, dynamic>> components = [];
    
    final lines = mealDescription.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Sadece kalori aralığı olan satırları atla
      if (RegExp(r'^\d+\s*-\s*\d+\s*kcal$', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      
      // Sadece sayı olan satırları atla
      if (RegExp(r'^\d+$').hasMatch(line)) {
        continue;
      }
      
      // Sadece kalori değeri olan satırları atla
      if (RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      
      // Kalori bilgisini çıkar
      int calories = 0;
      final calorieMatch = RegExp(r'(\d+)(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false).firstMatch(line);
      if (calorieMatch != null && calorieMatch.group(1) != null) {
        calories = int.tryParse(calorieMatch.group(1)!) ?? 0;
      }
      
      // Bileşen adını çıkar (kalori kısmını çıkar)
      String name = line
          .replaceAll(RegExp(r'\s*:\s*\d+(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'≈|~'), '')
          .trim();
      
      // Sadece gerçek besin adları olan satırları ekle
      if (name.isNotEmpty && 
          !RegExp(r'^\d+$').hasMatch(name) && 
          !RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(name) &&
          !RegExp(r'^\d+\s*-\s*\d+\s*kcal$', caseSensitive: false).hasMatch(name)) {
        // Eğer kalori yoksa varsayılan bir değer ver
        if (calories == 0 && components.isNotEmpty) {
          // Önceki bileşenlerin ortalamasını al
          final avg = components.map((c) => c['calories'] as int).reduce((a, b) => a + b) / components.length;
          calories = avg.round();
        } else if (calories == 0) {
          calories = 50; // Varsayılan kalori
        }
        
        components.add({
          'name': name,
          'calories': calories,
          'isSelected': true, // Varsayılan olarak seçili
        });
      }
    }
    
    // Eğer parse edilemezse, tüm öğünü tek bileşen olarak ekle
    if (components.isEmpty) {
      int totalCalories = 0;
      final calorieMatch = RegExp(r'(\d+)\s*-\s*\d+\s*kcal', caseSensitive: false).firstMatch(mealDescription);
      if (calorieMatch != null && calorieMatch.group(1) != null) {
        totalCalories = int.tryParse(calorieMatch.group(1)!) ?? 0;
      }
      
      String cleanName = mealDescription
          .replaceAll(RegExp(r'\s*:\s*\d+(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
          .trim();
      
      if (cleanName.isEmpty) {
        cleanName = 'Öğün';
      }
      
      components.add({
        'name': cleanName,
        'calories': totalCalories > 0 ? totalCalories : 200,
        'isSelected': true,
      });
    }
    
    return components;
  }

  // Meal için ExpansionTile widget'ı oluştur
  Widget _buildMealExpansionTile(MealEntry meal) {
    // Recipe'yi cache'den al veya description'dan parse et
    Recipe? recipe;
    if (meal.recipeId != null && meal.recipeId!.isNotEmpty) {
      recipe = _recipeCache[meal.recipeId!];
    }
    
    // Malzemeleri parse et
    List<Map<String, dynamic>> components;
    if (recipe != null) {
      // Eğer tarif malzeme listesi varsa kaloriyi porsiyon başı toplamdan eşit dağıt
      if (recipe.ingredients.isNotEmpty) {
        final count = recipe.ingredients.length;
        int baseCalories = recipe.caloriesPerServing;
        if (baseCalories == 0) {
          baseCalories = meal.calories; // tarifte kalori yoksa öğün kalorisine düş
        }
        final perItem = count > 0 ? (baseCalories / count).round() : 0;
        components = recipe.ingredients
            .map((ing) => {
                  'name': ing,
                  'calories': perItem,
                  'isSelected': true,
                })
            .toList();
      } else if (recipe.description.isNotEmpty) {
        components = _parseMealComponents(recipe.description);
      } else {
        components = [
          {
            'name': meal.foodName,
            'calories': meal.calories,
            'isSelected': true,
          }
        ];
      }
    } else if (meal.description.isNotEmpty) {
      components = _parseMealComponents(meal.description);
    } else {
      // Eğer description yoksa, tek bileşen olarak ekle
      components = [{
        'name': meal.foodName,
        'calories': meal.calories,
        'isSelected': true,
      }];
    }

    return StatefulBuilder(
      builder: (context, setState) {
        // Seçilen bileşenlerin kalori toplamını hesapla
        int totalCalories = components
            .where((component) => component['isSelected'] == true)
            .fold(0, (sum, component) => sum + (component['calories'] as int));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text('${meal.mealType} - ${meal.foodName}'),
            subtitle: Row(
              children: [
                Text(
                  'Toplam: $totalCalories kcal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meal.calories != totalCalories)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '(Orijinal: ${meal.calories} kcal)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Malzemeler:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...components.map((component) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        value: component['isSelected'] as bool,
                        onChanged: (bool? value) {
                          setState(() {
                            component['isSelected'] = value ?? false;
                          });
                        },
                        title: Text(
                          component['name'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${component['calories']} kcal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    )),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Seçilen Malzemelerin Toplam Kalorisi:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$totalCalories kcal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_preview.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _service.savePlan(_preview);
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan kaydedildi! Ana ekrana yönlendiriliyorsunuz...'), backgroundColor: Colors.green),
      );
      // Ana ekrana (HomeScreen) yönlendir
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Tüm önceki route'ları temizle
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showShoppingList() {
    if (_preview.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce bir plan oluşturun.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final shoppingList = _service.generateShoppingList(_preview);
    final formattedList = _service.formatShoppingList(shoppingList);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Haftalık Alışveriş Listesi'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: shoppingList.isEmpty
              ? const Text('Alışveriş listesi boş.')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bu hafta ihtiyacınız olan malzemeler:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...shoppingList.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toplam ${shoppingList.length} farklı malzeme',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Kopyalama işlevi (opsiyonel - clipboard'a kopyala)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alışveriş listesi hazır: $formattedList'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Tamam'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<MealEntry>>{};
    for (final m in _preview) {
      final k = DateFormat('yyyy-MM-dd').format(m.date);
      grouped.putIfAbsent(k, () => []).add(m);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otomatik Plan'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _generateWeekly,
                        child: const Text('Haftalık Plan Oluştur'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading || _preview.isEmpty ? null : _save,
                        child: const Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
                if (_preview.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showShoppingList,
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Alışveriş Listesi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _preview.isEmpty
                ? Center(
                    child: Text(
                      'Henüz bir plan bulunmuyor.\n"Haftalık Plan Oluştur"a basın.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  )
                : ListView(
                    children: grouped.entries.map((e) {
                      final day = DateFormat('EEE, dd MMM', 'tr').format(DateTime.parse(e.key));
                      final meals = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(day, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 8),
                                ...meals.map((m) => _buildMealExpansionTile(m)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}


