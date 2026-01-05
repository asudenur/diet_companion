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

  // Diyet tercihleri with icons
  final List<Map<String, dynamic>> _dietaryPreferences = [
    {'name': 'Vegan', 'icon': Icons.eco, 'color': Color(0xFF4CAF50)},
    {'name': 'Vejetaryen', 'icon': Icons.grass, 'color': Color(0xFF8BC34A)},
    {'name': 'Glutensiz', 'icon': Icons.no_food, 'color': Color(0xFFFF9800)},
    {'name': 'Su Diyeti', 'icon': Icons.water_drop, 'color': Color(0xFF03A9F4)},
    {'name': 'Keto', 'icon': Icons.local_fire_department, 'color': Color(0xFFE91E63)},
    {'name': 'Paleo', 'icon': Icons.fitness_center, 'color': Color(0xFF795548)},
    {'name': 'Akdeniz', 'icon': Icons.wb_sunny, 'color': Color(0xFFFF5722)},
    {'name': 'Düşük Karbonhidrat', 'icon': Icons.trending_down, 'color': Color(0xFF9C27B0)},
    {'name': 'Yüksek Protein', 'icon': Icons.trending_up, 'color': Color(0xFF3F51B5)},
    {'name': 'Kalori Kontrolü', 'icon': Icons.speed, 'color': Color(0xFF009688)},
  ];

  // Alerjiler with icons
  final List<Map<String, dynamic>> _allergies = [
    {'name': 'Fındık', 'icon': Icons.circle, 'color': Color(0xFF8D6E63)},
    {'name': 'Fıstık', 'icon': Icons.circle, 'color': Color(0xFFD7CCC8)},
    {'name': 'Süt', 'icon': Icons.local_drink, 'color': Color(0xFF90CAF9)},
    {'name': 'Yumurta', 'icon': Icons.egg, 'color': Color(0xFFFFE082)},
    {'name': 'Balık', 'icon': Icons.set_meal, 'color': Color(0xFF4FC3F7)},
    {'name': 'Kabuklu Deniz Ürünleri', 'icon': Icons.pest_control, 'color': Color(0xFFEF5350)},
    {'name': 'Soya', 'icon': Icons.circle, 'color': Color(0xFFA5D6A7)},
    {'name': 'Buğday', 'icon': Icons.grain, 'color': Color(0xFFFFCC80)},
    {'name': 'Sülfit', 'icon': Icons.science, 'color': Color(0xFFCE93D8)},
    {'name': 'Susam', 'icon': Icons.circle, 'color': Color(0xFFBCAAA4)},
  ];

  // Diyet tipleri with icons
  final List<Map<String, dynamic>> _dietTypes = [
    {'name': 'Önerilen Diyet', 'icon': Icons.auto_awesome, 'description': 'Size özel AI tavsiyesi'},
    {'name': 'Keto', 'icon': Icons.local_fire_department, 'description': 'Yüksek yağ, düşük karbonhidrat'},
    {'name': 'Aralıklı Oruç', 'icon': Icons.timer, 'description': '16:8 veya 18:6 modeli'},
    {'name': 'Akdeniz', 'icon': Icons.wb_sunny, 'description': 'Sağlıklı yağlar ve sebzeler'},
    {'name': 'Su Diyeti', 'icon': Icons.water_drop, 'description': 'Düşük kalorili detoks'},
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Tercihleriniz kaydedildi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Diyet Tercihleri'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.tune, size: 48, color: Colors.white.withOpacity(0.9)),
                  SizedBox(height: 12),
                  Text(
                    'Beslenme tercihlerinizi özelleştirin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Diyet Tipi Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionHeader(
                icon: Icons.restaurant_menu,
                title: 'Diyet Tipi',
                subtitle: 'Temel beslenme yaklaşımınızı seçin',
              ),
            ),
            SizedBox(height: 16),
            _buildDietTypeCards(),
            
            SizedBox(height: 32),
            
            // Diyet Tercihleri Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionHeader(
                icon: Icons.checklist,
                title: 'Diyet Tercihleri',
                subtitle: 'Önerilerimizi kişiselleştirin',
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildPreferenceGrid(_dietaryPreferences, _selectedPreferences, (selected) {
                setState(() => _selectedPreferences = selected);
              }),
            ),
            
            SizedBox(height: 32),
            
            // Alerjiler Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildSectionHeader(
                icon: Icons.warning_amber_rounded,
                title: 'Alerjiler',
                subtitle: 'Kaçınmanız gereken besinleri seçin',
                iconColor: Colors.orange,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildAllergyGrid(),
            ),
            
            SizedBox(height: 32),
            
            // Kaydet Butonu
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _savePreferences,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Tercihleri Kaydet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDietTypeCards() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dietTypes.length,
        itemBuilder: (context, index) {
          final diet = _dietTypes[index];
          final isSelected = _selectedDietType == diet['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDietType = diet['name'];
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 130,
              margin: EdgeInsets.symmetric(horizontal: 6),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    diet['icon'],
                    size: 32,
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    diet['name'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreferenceGrid(List<Map<String, dynamic>> items, List<String> selectedItems, Function(List<String>) onChanged) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item['name']);
        
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selectedItems);
            if (isSelected) {
              updated.remove(item['name']);
            } else {
              updated.add(item['name']);
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? (item['color'] as Color).withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? item['color'] : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'],
                  size: 20,
                  color: isSelected ? item['color'] : Colors.grey[400],
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? item['color'] : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: item['color']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllergyGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _allergies.map((allergy) {
        final isSelected = _selectedAllergies.contains(allergy['name']);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAllergies.remove(allergy['name']);
              } else {
                _selectedAllergies.add(allergy['name']);
              }
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.red.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.block, size: 16, color: Colors.red.shade400),
                  SizedBox(width: 6),
                ],
                Text(
                  allergy['name'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
