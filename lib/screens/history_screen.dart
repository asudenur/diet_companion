import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../services/meal_service.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final MealService _service = MealService();
  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _meals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meals = await _service.getDailyMeals(_selectedDate);
      // Sadece "yedim" işaretlenmiş öğünleri göster
      final eatenMeals = meals.where((meal) => meal.isEaten).toList();
      setState(() {
        _meals = eatenMeals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Öğünler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _meals.where((m) => m.isEaten).fold<int>(0, (sum, m) => sum + m.calories);
    final totalProtein = _meals.where((m) => m.isEaten).fold<double>(0, (sum, m) => sum + m.protein);
    final totalCarbs = _meals.where((m) => m.isEaten).fold<double>(0, (sum, m) => sum + m.carbs);
    final totalFat = _meals.where((m) => m.isEaten).fold<double>(0, (sum, m) => sum + m.fat);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğün Geçmişi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Tarih Seçici ve Özet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
              children: [
                Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.today),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                        _loadMeals();
                      },
                      tooltip: 'Bugün',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Günlük Özet
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
            child: Row(
              children: [
                Expanded(
                        child: _buildStatItem(
                          'Kalori',
                          totalCalories.toString(),
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Protein',
                          '${totalProtein.toStringAsFixed(1)}g',
                          Icons.fitness_center,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Karbonhidrat',
                          '${totalCarbs.toStringAsFixed(1)}g',
                          Icons.grain,
                          Colors.blue,
                        ),
                      ),
                Expanded(
                        child: _buildStatItem(
                          'Yağ',
                          '${totalFat.toStringAsFixed(1)}g',
                          Icons.opacity,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Öğün Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _meals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bu tarihte yenilmiş öğün bulunamadı',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Öğünlerinizi "Yedim" olarak işaretleyin',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          final meal = _meals[index];
                          return _buildMealCard(meal);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(MealEntry meal) {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == 
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getMealColor(meal.mealType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getMealIcon(meal.mealType),
            color: _getMealColor(meal.mealType),
            size: 24,
          ),
        ),
        title: Text(
          meal.mealType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              meal.foodName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMacroChip('${meal.calories} kcal', Colors.orange),
                const SizedBox(width: 8),
                _buildMacroChip('P: ${meal.protein.toInt()}g', Colors.red),
                const SizedBox(width: 8),
                _buildMacroChip('C: ${meal.carbs.toInt()}g', Colors.blue),
                const SizedBox(width: 8),
                _buildMacroChip('Y: ${meal.fat.toInt()}g', Colors.amber),
              ],
            ),
          ],
        ),
        trailing: meal.isEaten
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Yedim',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'Kahvaltı':
        return Icons.breakfast_dining;
      case 'Öğle Yemeği':
        return Icons.lunch_dining;
      case 'Akşam Yemeği':
        return Icons.dinner_dining;
      case 'Ara Öğün 1':
      case 'Ara Öğün 2':
        return Icons.fastfood_outlined;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case 'Kahvaltı':
        return Colors.orange;
      case 'Öğle Yemeği':
        return Colors.blue;
      case 'Akşam Yemeği':
        return Colors.purple;
      case 'Ara Öğün 1':
      case 'Ara Öğün 2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
