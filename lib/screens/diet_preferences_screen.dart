import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DietPreferencesScreen extends StatefulWidget {
  const DietPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends State<DietPreferencesScreen> {
  List<String> _selectedPreferences = [];
  List<String> _selectedAllergies = [];
  String? _selectedDietType;

  // Diyet tercihleri
  final List<String> _dietaryPreferences = [
    'Vegan',
    'Vejetaryen',
    'Glutensiz',
    'Su Diyeti',
    'Keto',
    'Paleo',
    'Akdeniz',
    'Düşük Karbonhidrat',
    'Yüksek Protein',
    'Kalori Kontrolü',
  ];

  // Alerjiler
  final List<String> _allergies = [
    'Fındık',
    'Fıstık',
    'Süt',
    'Yumurta',
    'Balık',
    'Kabuklu Deniz Ürünleri',
    'Soya',
    'Buğday',
    'Sülfit',
    'Susam',
  ];

  // Diyet tipleri (home_screen ile uyumlu olmalı)
  final List<String> _dietTypes = [
    'Önerilen Diyet',
    'Keto',
    'Aralıklı Oruç',
    'Akdeniz',
    'Su Diyeti',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _selectedPreferences = (data?['dietaryPreferences'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _selectedAllergies = (data?['allergies'] as List?)?.map((e) => e.toString()).toList() ?? [];
          _selectedDietType = data?['selectedDietType'];
        });
      }
    } catch (e) {
      print('Tercihler yüklenirken hata: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .set({
        'dietaryPreferences': _selectedPreferences,
        'allergies': _selectedAllergies,
        'selectedDietType': _selectedDietType,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tercihleriniz kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diyet Tercihleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diyet Tipi Seçimi
            _buildSectionTitle('Diyet Tipi'),
            const SizedBox(height: 12),
            _buildDietTypeSelector(),
            const SizedBox(height: 32),

            // Diyet Tercihleri
            _buildSectionTitle('Diyet Tercihleri'),
            const SizedBox(height: 12),
            _buildChipSelector(
              items: _dietaryPreferences,
              selectedItems: _selectedPreferences,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedPreferences = selected;
                });
              },
            ),
            const SizedBox(height: 32),

            // Alerjiler
            _buildSectionTitle('Alerjiler'),
            const SizedBox(height: 12),
            _buildChipSelector(
              items: _allergies,
              selectedItems: _selectedAllergies,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedAllergies = selected;
                });
              },
            ),
            const SizedBox(height: 32),

            // Kaydet Butonu
            ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDietTypeSelector() {
    // Eğer _selectedDietType items listesinde yoksa, null yap (hata önleme)
    String? validValue = _selectedDietType;
    if (_selectedDietType != null && !_dietTypes.contains(_selectedDietType)) {
      validValue = null;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: const Icon(Icons.restaurant_menu),
        ),
        hint: const Text('Diyet tipi seçin'),
        items: _dietTypes.map((dietType) {
          return DropdownMenuItem(
            value: dietType,
            child: Text(dietType),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDietType = value;
          });
        },
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            final updatedList = List<String>.from(selectedItems);
            if (selected) {
              updatedList.add(item);
            } else {
              updatedList.remove(item);
            }
            onSelectionChanged(updatedList);
          },
          checkmarkColor: Colors.white,
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}
