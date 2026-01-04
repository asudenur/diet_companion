import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class FoodDatabaseScreen extends StatefulWidget {
  const FoodDatabaseScreen({Key? key}) : super(key: key);

  @override
  State<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends State<FoodDatabaseScreen> {
  final FoodService _service = FoodService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _category = 'Tümü';
  bool _vegan = false;
  bool _vegetarian = false;
  final Set<String> _excludeAllergens = {};
  Future<List<FoodItem>>? _future;
  // Her besin için seçilen porsiyon index'i
  final Map<String, int> _selectedPortionIndex = {};

  final List<String> _categories = const [
    'Tümü', 'Meyve', 'Sebze', 'Protein', 'Tahıl', 'İçecek', 'Atıştırmalık', 'Diğer'
  ];

  @override
  void initState() {
    super.initState();
    // Seed sample foods once, then load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _service.ensureFoodsSeeded();
      } catch (_) {}
      if (mounted) {
        _load();
      }
    });
  }

  void _load() {
    _future = _service.searchFoods(
      query: _searchCtrl.text.trim(),
      category: _category == 'Tümü' ? null : _category,
      limit: 200,
      vegan: _vegan ? true : null,
      vegetarian: _vegetarian ? true : null,
      excludeAllergens: _excludeAllergens.isEmpty ? null : _excludeAllergens.toList(),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Besin Veritabanı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
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
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                            hintText: 'Ara (ör. elma, tavuk...)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _load(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButton<String>(
                        value: _category,
                        underline: const SizedBox(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                          _load();
                        },
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('🌱 Vegan'),
                      selected: _vegan,
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      onSelected: (v) {
                        setState(() => _vegan = v);
                        _load();
                      },
                    ),
                    FilterChip(
                      label: const Text('🥬 Vejetaryen'),
                      selected: _vegetarian,
                      selectedColor: Colors.green.withOpacity(0.2),
                      checkmarkColor: Colors.green,
                      onSelected: (v) {
                        setState(() => _vegetarian = v);
                        _load();
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (a) {
                        if (_excludeAllergens.contains(a)) {
                          _excludeAllergens.remove(a);
                        } else {
                          _excludeAllergens.add(a);
                        }
                        setState(() {});
                        _load();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'gluten', child: Text('🌾 Gluten')),
                        PopupMenuItem(value: 'süt', child: Text('🥛 Süt')),
                        PopupMenuItem(value: 'fıstık', child: Text('🥜 Fıstık')),
                        PopupMenuItem(value: 'yumurta', child: Text('🥚 Yumurta')),
                        PopupMenuItem(value: 'soya', child: Text('🫘 Soya')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _excludeAllergens.isEmpty 
                            ? Colors.grey[100] 
                            : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_alt_outlined,
                              size: 16,
                              color: _excludeAllergens.isEmpty 
                                ? Colors.grey[600] 
                                : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _excludeAllergens.isEmpty ? 'Alerjenler' : _excludeAllergens.join(','),
                              style: TextStyle(
                                color: _excludeAllergens.isEmpty 
                                  ? Colors.grey[600] 
                                  : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Besinler yükleniyor...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sonuç bulunamadı',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Farklı arama terimleri deneyin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final f = items[i];
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
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          f.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    f.category,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (_) {
                                    final hasPortions = f.portions.isNotEmpty;
                                    final selectedIndex = _selectedPortionIndex[f.id] ?? 0;
                                    final cals = hasPortions
                                        ? (f.portions[selectedIndex]['calories'] as num?)?.toInt() ?? f.calories
                                        : f.calories;
                                    return Row(
                                      children: [
                                        if (hasPortions)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DropdownButton<int>(
                                              value: selectedIndex,
                                              underline: const SizedBox(),
                                              items: List.generate(
                                                f.portions.length,
                                                (idx) => DropdownMenuItem(
                                                  value: idx,
                                                  child: Text(
                                                    f.portions[idx]['name']?.toString() ?? 'Porsiyon',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ),
                                              ),
                                              onChanged: (v) {
                                                if (v == null) return;
                                                setState(() {
                                                  _selectedPortionIndex[f.id] = v;
                                                });
                                              },
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${cals} kcal',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () async {
                              await _service.toggleFavorite(f);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Favoriler güncellendi'),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, f);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}


