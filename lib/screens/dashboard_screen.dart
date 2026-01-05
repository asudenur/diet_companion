import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/food_service.dart';
import '../models/macro_goals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FoodService _foodService = FoodService();
  bool _showWeekly = true;
  Future<Map<DateTime, int>>? _future;
  Future<MacroGoals?>? _macroFuture;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR').then((_) => _load());
  }

  void _load() {
    final now = DateTime.now();
    if (_showWeekly) {
      final start = now.subtract(const Duration(days: 6));
      _future = _foodService.dailyCaloriesBetween(
        DateTime(start.year, start.month, start.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    } else {
      final first = DateTime(now.year, now.month, 1);
      final last = DateTime(now.year, now.month + 1, 0);
      _future = _foodService.dailyCaloriesBetween(first, last);
    }
    _macroFuture = _fetchMacroGoals();
    setState(() {});
  }

  Future<MacroGoals?> _fetchMacroGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('macro_goals').get();
    if (!doc.exists) return null;
    return MacroGoals.fromMap(doc.data()!);
  }

  Future<Map<String, double>> _fetchTodayMacros() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'calories': 0.0};

      final now = DateTime.now();

      final snapshot = await FirebaseFirestore.instance
          .collection('meal_entries')
          .where('userId', isEqualTo: uid)
          .where('isEaten', isEqualTo: true)
          .get();

      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;
      double calories = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'];
        DateTime entryDate;
        
        if (date is Timestamp) {
          entryDate = date.toDate();
        } else if (date is DateTime) {
          entryDate = date;
        } else {
          continue;
        }

        final entryDateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
        final todayOnly = DateTime(now.year, now.month, now.day);
        
        if (entryDateOnly.isAtSameMomentAs(todayOnly)) {
          if (data['components'] != null && (data['components'] as List).isNotEmpty) {
            final components = List<Map<String, dynamic>>.from(data['components'] as List);
            final selectedComponents = components.where((component) => component['isSelected'] == true);
            
            for (var component in selectedComponents) {
              calories += (component['calories'] ?? 0).toDouble();
              protein += (component['protein'] ?? 0).toDouble();
              carbs += (component['carbs'] ?? 0).toDouble();
              fat += (component['fat'] ?? 0).toDouble();
            }
          } else {
            calories += (data['calories'] ?? 0).toDouble();
            protein += (data['protein'] ?? 0).toDouble();
            carbs += (data['carbs'] ?? 0).toDouble();
            fat += (data['fat'] ?? 0).toDouble();
          }
        }
      }

      return {'protein': protein, 'carbs': carbs, 'fat': fat, 'calories': calories};
    } catch (e) {
      print('Makro besinler getirilemedi: $e');
      return {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'calories': 0.0};
    }
  }

  // Streak hesaplama (kaç gün üst üste kalori hedefine ulaşıldı)
  Future<int> _calculateStreak() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return 0;

      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 30; i++) {
        final day = now.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        
        final snapshot = await FirebaseFirestore.instance
            .collection('meal_entries')
            .where('userId', isEqualTo: uid)
            .where('isEaten', isEqualTo: true)
            .get();

        double dayCalories = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final date = data['date'];
          DateTime entryDate;
          
          if (date is Timestamp) {
            entryDate = date.toDate();
          } else if (date is DateTime) {
            entryDate = date;
          } else {
            continue;
          }

          final entryDateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
          if (entryDateOnly.isAtSameMomentAs(dayStart)) {
            dayCalories += (data['calories'] ?? 0).toDouble();
          }
        }

        if (dayCalories > 0) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Gösterge Paneli',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats Row
                _buildQuickStatsRow(),
                SizedBox(height: 20),
                
                // Period Selector
                _buildPeriodSelector(),
                SizedBox(height: 16),
                
                // Chart Card
                _buildChartCard(),
                SizedBox(height: 20),
                
                // Today's Summary
                _buildTodaySummaryCard(),
                SizedBox(height: 20),
                
                // Macro Nutrients
                _buildMacroNutrientsCard(),
                SizedBox(height: 20),
                
                // Achievement Card
                _buildAchievementsCard(),
                SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildQuickStatsRow() {
    return FutureBuilder<Map<DateTime, int>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final totalCalories = data.values.fold<int>(0, (sum, val) => sum + val);
        final avgCalories = data.isNotEmpty ? (totalCalories / data.length).round() : 0;
        final maxCalories = data.values.fold<int>(0, (max, val) => val > max ? val : max);
        
        return Row(
          children: [
            Expanded(child: _buildQuickStatCard(
              icon: Icons.local_fire_department,
              label: 'Toplam',
              value: '$totalCalories',
              unit: 'kcal',
              color: Color(0xFFFF6B6B),
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickStatCard(
              icon: Icons.show_chart,
              label: 'Ortalama',
              value: '$avgCalories',
              unit: 'kcal',
              color: Color(0xFF4ECDC4),
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickStatCard(
              icon: Icons.emoji_events,
              label: 'En Yüksek',
              value: '$maxCalories',
              unit: 'kcal',
              color: Color(0xFFFFD93D),
            )),
          ],
        );
      },
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_showWeekly) {
                  _showWeekly = true;
                  _load();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _showWeekly ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_week,
                      size: 18,
                      color: _showWeekly ? Colors.white : Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Haftalık',
                      style: TextStyle(
                        color: _showWeekly ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showWeekly) {
                  _showWeekly = false;
                  _load();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_showWeekly ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: !_showWeekly ? Colors.white : Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aylık',
                      style: TextStyle(
                        color: !_showWeekly ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalori Trendi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _showWeekly ? 'Son 7 gün' : 'Bu ay',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          FutureBuilder<Map<DateTime, int>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final data = snapshot.data ?? {};
              final items = _buildSeries(data);
              final maxY = (items.map((e) => e.toY).fold<double>(0, (p, c) => c > p ? c : p) * 1.2).clamp(100, 4000).toDouble();
              
              final spots = items.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.toY))
                  .toList();
              
              return SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, 
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        preventCurveOverShooting: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Color(0xFF2E7D32),
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              Theme.of(context).colorScheme.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: _showWeekly ? 1 : 5,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                            if (!_showWeekly && idx % 5 != 0 && idx != items.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                items[idx].label, 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 12,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()} kcal',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    return FutureBuilder<Map<String, double>>(
      future: _fetchTodayMacros(),
      builder: (context, snapshot) {
        final macros = snapshot.data ?? {'calories': 0.0};
        final calories = macros['calories'] ?? 0.0;
        
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF6B6B),
                Color(0xFFFF8E53),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF6B6B).withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugün Tüketilen',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${calories.toInt()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            'kcal',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMacroNutrientsCard() {
    return FutureBuilder<MacroGoals?>(
      future: _macroFuture,
      builder: (context, goalSnap) {
        final goals = goalSnap.data;
        
        return FutureBuilder<Map<String, double>>(
          future: _fetchTodayMacros(),
          builder: (context, macroSnap) {
            final macros = macroSnap.data ?? {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
            final protein = macros['protein'] ?? 0.0;
            final carbs = macros['carbs'] ?? 0.0;
            final fat = macros['fat'] ?? 0.0;
            
            final proteinGoal = goals?.protein.toDouble() ?? 100.0;
            final carbsGoal = goals?.carbs.toDouble() ?? 250.0;
            final fatGoal = goals?.fat.toDouble() ?? 65.0;
            
            return Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.pie_chart, color: Colors.purple),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Makro Besinler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildMacroItem('Protein', protein, proteinGoal, Color(0xFFFF6B6B))),
                      SizedBox(width: 16),
                      Expanded(child: _buildMacroItem('Karb', carbs, carbsGoal, Color(0xFF4ECDC4))),
                      SizedBox(width: 16),
                      Expanded(child: _buildMacroItem('Yağ', fat, fatGoal, Color(0xFFFFD93D))),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMacroItem(String label, double value, double target, Color color) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${value.toInt()}/${target.toInt()}g',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.stars, color: Colors.orange),
              ),
              SizedBox(width: 12),
              Text(
                'Başarılar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAchievementItem(
                icon: Icons.local_fire_department,
                title: 'Kalori Takibi',
                subtitle: 'İlk hafta',
                color: Color(0xFFFF6B6B),
                isUnlocked: true,
              )),
              SizedBox(width: 12),
              Expanded(child: _buildAchievementItem(
                icon: Icons.water_drop,
                title: 'Su İçici',
                subtitle: '2L/gün',
                color: Color(0xFF4ECDC4),
                isUnlocked: true,
              )),
              SizedBox(width: 12),
              Expanded(child: _buildAchievementItem(
                icon: Icons.restaurant,
                title: 'Planlı Yemek',
                subtitle: '7 gün',
                color: Color(0xFFFFD93D),
                isUnlocked: false,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isUnlocked,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isUnlocked ? color : Colors.grey,
            size: 28,
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.black87 : Colors.grey,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  List<_BarItem> _buildSeries(Map<DateTime, int> totals) {
    final now = DateTime.now();
    final List<_BarItem> out = [];
    if (_showWeekly) {
      for (int i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final val = totals[DateTime(d.year, d.month, d.day)] ?? 0;
        out.add(_BarItem(DateFormat('E', 'tr_TR').format(d), val.toDouble()));
      }
    } else {
      final first = DateTime(now.year, now.month, 1);
      final last = DateTime(now.year, now.month + 1, 0);
      for (int day = 1; day <= last.day; day++) {
        final d = DateTime(now.year, now.month, day);
        final val = totals[DateTime(d.year, d.month, d.day)] ?? 0;
        out.add(_BarItem(day.toString(), val.toDouble()));
      }
    }
    return out;
  }
}

class _BarItem {
  final String label;
  final double toY;
  _BarItem(this.label, this.toY);
}
