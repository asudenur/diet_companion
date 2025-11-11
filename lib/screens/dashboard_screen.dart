import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/food_service.dart';
import '../models/macro_goals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Bugün tüketilen makro besinleri getir
  Future<Map<String, double>> _fetchTodayMacros() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('meal_entries')
          .where('userId', isEqualTo: uid)
          .where('isEaten', isEqualTo: true)
          .get();

      double protein = 0.0;
      double carbs = 0.0;
      double fat = 0.0;

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

        // Sadece bugünün verilerini al (sadece gün bazında karşılaştır)
        final entryDateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
        final todayOnly = DateTime(now.year, now.month, now.day);
        
        if (entryDateOnly.isAtSameMomentAs(todayOnly)) {
          protein += (data['protein'] ?? 0).toDouble();
          carbs += (data['carbs'] ?? 0).toDouble();
          fat += (data['fat'] ?? 0).toDouble();
        }
      }

      return {'protein': protein, 'carbs': carbs, 'fat': fat};
    } catch (e) {
      print('Makro besinler getirilemedi: $e');
      return {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gösterge Paneli'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Haftalık')),
                        ButtonSegment(value: false, label: Text('Aylık')),
                      ],
                      selected: {_showWeekly},
                      onSelectionChanged: (s) {
                        _showWeekly = s.first;
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FutureBuilder<Map<DateTime, int>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                        }
                        final data = snapshot.data ?? {};
                        final items = _buildSeries(data);
                        final maxY = (items.map((e) => e.toY).fold<double>(0, (p, c) => c > p ? c : p) * 1.2).clamp(100, 4000).toDouble();
                        return SizedBox(
                          height: 240,
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              borderData: FlBorderData(show: false),
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barGroups: items
                                  .asMap()
                                  .entries
                                  .map((e) => BarChartGroupData(x: e.key, barRods: [
                                        BarChartRodData(toY: e.value.toY, color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                                      ]))
                                  .toList(),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                                      return Text(items[idx].label, style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<MacroGoals?>(
                  future: _macroFuture,
                  builder: (context, snap) {
                    final goals = snap.data;
                    if (goals == null) return const SizedBox.shrink();
                    
                    return FutureBuilder<Map<String, double>>(
                      future: _fetchTodayMacros(),
                      builder: (context, macroSnap) {
                        if (macroSnap.connectionState == ConnectionState.waiting) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }
                        
                        final macros = macroSnap.data ?? {'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
                        final protein = macros['protein'] ?? 0.0;
                        final carbs = macros['carbs'] ?? 0.0;
                        final fat = macros['fat'] ?? 0.0;
                        
                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bugünkü Makro Besinler',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _macroRing(context, 'Protein', protein, goals.protein.toDouble(), Colors.redAccent),
                                    _macroRing(context, 'Karb', carbs, goals.carbs.toDouble(), Colors.blueAccent),
                                    _macroRing(context, 'Yağ', fat, goals.fat.toDouble(), Colors.amber.shade700),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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

Widget _macroRing(BuildContext context, String label, double value, double target, Color color) {
  final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
  return Column(
    children: [
      SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: pct,
              strokeWidth: 8,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
            Center(
              child: Text('${(pct * 100).round()}%'),
            )
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text('$label ${value.toStringAsFixed(0)}/${target.toStringAsFixed(0)}g'),
    ],
  );
}


