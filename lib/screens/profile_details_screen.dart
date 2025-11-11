import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  Future<void> _calculateAndSaveWaterNeeded(double weight) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final waterNeeded = (weight * 30).round(); // ml cinsinden günlük su ihtiyacı
      
      await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .set({
        'waterNeeded': waterNeeded,
        'lastCalculated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Su ihtiyacı hesaplanırken hata oluştu: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Profil'),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_infos')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Bilgiler yüklenirken bir hata oluştu',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Veri tiplerini kontrol et ve dönüştür
          final height = (data['height'] as num?)?.toDouble() ?? 0.0;
          final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
          final age = (data['age'] as num?)?.toInt() ?? 0;
          final gender = data['gender'] as String? ?? 'Belirtilmemiş';
          final activityLevel = data['activityLevel'] as String? ?? 'Belirtilmemiş';
          final dailyCalorieNeed = (data['dailyCalorieNeed'] as num?)?.toInt() ?? 
                                  (data['calculatedCalories'] as num?)?.toInt() ?? 0;
          final waterNeeded = (data['waterNeeded'] as num?)?.toInt() ?? 0;
          final selectedDietType = data['selectedDietType'] as String? ?? 'Seçilmedi';

          // Su ihtiyacını hesapla ve kaydet
          if (weight > 0) {
            _calculateAndSaveWaterNeeded(weight);
          }

          return Container(
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Profil Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
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
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userEmail.split('@').first,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // İstatistikler
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Günlük Kalori',
                            dailyCalorieNeed > 0 ? '$dailyCalorieNeed kcal' : 'Hesaplanmadı',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Su İhtiyacı',
                            waterNeeded > 0 ? '$waterNeeded ml' : 'Hesaplanmadı',
                            Icons.water_drop,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Profil Bilgileri
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Bilgiler',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Yaş',
                          '$age yaş',
                          Icons.cake,
                          Colors.pink,
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Cinsiyet',
                          gender,
                          Icons.person_outline,
                          Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Boy',
                          '${height.toStringAsFixed(1)} cm',
                          Icons.height,
                          Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Kilo',
                          '${weight.toStringAsFixed(1)} kg',
                          Icons.monitor_weight_outlined,
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Aktivite Seviyesi',
                          activityLevel,
                          Icons.directions_run,
                          Colors.orange,
                        ),
                        const SizedBox(height: 24),
                        
                        // Diyet Bilgisi
                        Text(
                          'Diyet Tercihleri',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildModernProfileInfoRow(
                          context,
                          'Seçili Diyet',
                          selectedDietType,
                          Icons.restaurant_menu,
                          Colors.teal,
                        ),
                        const SizedBox(height: 24),
                        
                        // Aksiyon Butonları
                        _buildModernActionButton(
                          context,
                          'Diyet Tercihlerini Düzenle',
                          'Diyet tipi, tercihler ve alerjilerinizi güncelleyin',
                          Icons.restaurant_menu,
                          Colors.green,
                          () {
                            Navigator.pushNamed(context, '/diet_preferences');
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildModernActionButton(
                          context,
                          'Kalori Hesapla',
                          'Günlük kalori ihtiyacınızı yeniden hesaplayın',
                          Icons.calculate,
                          Colors.blue,
                          () {
                            Navigator.pushNamed(context, '/calorie_calculator');
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildModernActionButton(
                          context,
                          'Gösterge Paneli',
                          'İlerlemenizi ve istatistiklerinizi görüntüleyin',
                          Icons.dashboard,
                          Colors.orange,
                          () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileInfoRow(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 