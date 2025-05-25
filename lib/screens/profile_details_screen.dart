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

  Widget _buildProfileInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Bilgiler yüklenirken bir hata oluştu'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Veri tiplerini kontrol et ve dönüştür
          final height = (data['height'] as num?)?.toDouble() ?? 0.0;
          final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
          final age = (data['age'] as num?)?.toInt() ?? 0;
          final gender = data['gender'] as String? ?? 'Belirtilmemiş';
          final activityLevel = data['activityLevel'] as String? ?? 'Belirtilmemiş';

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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileInfoRow(
                  context,
                  'Yaş',
                  '$age yaş',
                  Icons.cake,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  'Cinsiyet',
                  gender,
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  'Boy',
                  '${height.toStringAsFixed(1)} cm',
                  Icons.height,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  'Kilo',
                  '${weight.toStringAsFixed(1)} kg',
                  Icons.monitor_weight_outlined,
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(
                  context,
                  'Aktivite Seviyesi',
                  activityLevel,
                  Icons.directions_run,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 