import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  const CalorieCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalorieCalculatorScreen> createState() => _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  double? _calculatedCalories;
  bool _isLoading = false;

  double _getActivityMultiplier(String activity) {
    if (activity.contains('Çok az hareketli')) return 1.2;
    if (activity.contains('Hafif aktif')) return 1.375;
    if (activity.contains('Orta aktif')) return 1.55;
    if (activity.contains('Çok aktif')) return 1.725;
    return 1.2;
  }

  double _getGoalAdjustment(String goal, double tdee) {
    if (goal.contains('Kilo vermek')) return tdee - 350; // 300-400 kcal aralığının ortası
    if (goal.contains('Kilo almak')) return tdee + 300;
    return tdee;
  }

  Future<void> _calculateCalories() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final userData = await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .get();

      if (!userData.exists) {
        throw Exception('Kullanıcı bilgileri bulunamadı');
      }

      final data = userData.data()!;
      
      // Calculate BMR using Mifflin-St Jeor Formula
      double bmr;
      if (data['gender'] == 'Kadın') {
        bmr = 10 * data['weight'] + 6.25 * data['height'] - 5 * data['age'] - 161;
      } else {
        bmr = 10 * data['weight'] + 6.25 * data['height'] - 5 * data['age'] + 5;
      }
      
      // Calculate TDEE
      double tdee = bmr * _getActivityMultiplier(data['activityLevel']);
      
      // Apply goal-based adjustment
      double finalCalories = _getGoalAdjustment(data['goal'], tdee);
      
      setState(() => _calculatedCalories = finalCalories);

      // Save to user_infos collection
      await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .set({
        'calculatedCalories': finalCalories,
        'lastCalculated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalori Hesaplama'),
        centerTitle: true,
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Kalori İhtiyacınızı Hesaplayın',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kayıt olurken girdiğiniz bilgiler kullanılarak günlük kalori ihtiyacınız hesaplanacaktır.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _calculateCalories,
                            icon: _isLoading
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: const EdgeInsets.all(2.0),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.calculate_outlined),
                            label: Text(_isLoading ? 'Hesaplanıyor...' : 'Hesapla'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_calculatedCalories != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Günlük Kalori İhtiyacınız',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_calculatedCalories!.toStringAsFixed(0)} kcal',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 