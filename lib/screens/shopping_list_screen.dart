import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/plan_service.dart';
import '../models/meal_entry.dart';

class ShoppingListScreen extends StatefulWidget {
  final List<MealEntry>? weeklyPlan;

  const ShoppingListScreen({Key? key, this.weeklyPlan}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final PlanService _service = PlanService();
  List<ShoppingItem> _items = [];
  bool _isLoading = false;

  // Kategori ikonları ve renkleri
  final Map<String, Map<String, dynamic>> _categoryInfo = {
    'Meyve & Sebze': {'icon': Icons.eco, 'color': Color(0xFF4CAF50)},
    'Et & Balık': {'icon': Icons.set_meal, 'color': Color(0xFFE53935)},
    'Süt Ürünleri': {'icon': Icons.water_drop, 'color': Color(0xFF42A5F5)},
    'Tahıl & Baklagil': {'icon': Icons.grain, 'color': Color(0xFFFF9800)},
    'Baharat & Sos': {'icon': Icons.restaurant, 'color': Color(0xFF9C27B0)},
    'Diğer': {'icon': Icons.shopping_basket, 'color': Color(0xFF607D8B)},
  };

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  String _getCategoryForItem(String itemName) {
    final name = itemName.toLowerCase();
    
    // Meyve & Sebze
    if (['domates', 'biber', 'salatalık', 'marul', 'soğan', 'sarımsak', 'havuç', 
         'patates', 'patlıcan', 'kabak', 'brokoli', 'ıspanak', 'elma', 'muz', 
         'portakal', 'üzüm', 'çilek', 'ananas', 'limon', 'mantar', 'maydanoz',
         'nane', 'dereotu', 'roka', 'avokado', 'mısır'].any((v) => name.contains(v))) {
      return 'Meyve & Sebze';
    }
    
    // Et & Balık
    if (['tavuk', 'et', 'köfte', 'balık', 'somon', 'ton', 'hindi', 'dana', 
         'kuzu', 'sucuk', 'sosis', 'jambon', 'karides'].any((v) => name.contains(v))) {
      return 'Et & Balık';
    }
    
    // Süt Ürünleri
    if (['süt', 'yoğurt', 'peynir', 'tereyağı', 'krema', 'ayran', 'lor',
         'kaşar', 'beyaz peynir', 'yumurta', 'kefir'].any((v) => name.contains(v))) {
      return 'Süt Ürünleri';
    }
    
    // Tahıl & Baklagil
    if (['ekmek', 'makarna', 'pirinç', 'bulgur', 'mercimek', 'nohut', 'fasulye',
         'un', 'yulaf', 'müsli', 'gevrek', 'börek', 'pide', 'lavaş'].any((v) => name.contains(v))) {
      return 'Tahıl & Baklagil';
    }
    
    // Baharat & Sos
    if (['tuz', 'karabiber', 'pul biber', 'kekik', 'kimyon', 'zerdeçal', 
         'sos', 'ketçap', 'mayonez', 'hardal', 'soya', 'sirke', 'yağ',
         'zeytinyağı', 'bal', 'şeker', 'tarçın'].any((v) => name.contains(v))) {
      return 'Baharat & Sos';
    }
    
    return 'Diğer';
  }

  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true);
    try {
      if (widget.weeklyPlan != null) {
        _items = _service.generateShoppingList(widget.weeklyPlan!);
      } else {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 7));
        final savedPlan = await _service.getSavedWeeklyPlan(start, end);
        if (savedPlan != null && savedPlan.isNotEmpty) {
          _items = _service.generateShoppingList(savedPlan);
        }
      }
    } catch (e) {
      debugPrint('Alışveriş listesi yüklenemedi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (_items.isEmpty) return;

    final text = _items.map((e) => e.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Alışveriş listesi kopyalandı!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearChecked() {
    setState(() {
      _items.removeWhere((item) => item.isChecked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkedCount = _items.where((i) => i.isChecked).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    
    // Kategorilere göre grupla
    final Map<String, List<ShoppingItem>> categorizedItems = {};
    for (var item in _items) {
      final category = _getCategoryForItem(item.name);
      categorizedItems.putIfAbsent(category, () => []);
      categorizedItems[category]!.add(item);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Alışveriş Listesi',
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
                      Theme.of(context).colorScheme.primary,
                      Color(0xFF2E7D32),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Icon(
                        Icons.shopping_cart,
                        size: 80,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (_items.isNotEmpty) ...[
                IconButton(
                  icon: Icon(Icons.content_copy, color: Colors.white),
                  tooltip: 'Listeyi Kopyala',
                  onPressed: _copyToClipboard,
                ),
                if (checkedCount > 0)
                  IconButton(
                    icon: Icon(Icons.delete_sweep, color: Colors.white),
                    tooltip: 'Alınanları Temizle',
                    onPressed: _clearChecked,
                  ),
              ],
            ],
          ),
          
          // Content
          if (_isLoading)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Progress Card
                  _buildProgressCard(progress, checkedCount, totalCount),
                  SizedBox(height: 20),
                  
                  // Quick Stats
                  _buildQuickStats(categorizedItems),
                  SizedBox(height: 20),
                  
                  // Category Lists
                  ...categorizedItems.entries.map((entry) {
                    return _buildCategorySection(entry.key, entry.value);
                  }).toList(),
                  
                  SizedBox(height: 80),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: _items.isNotEmpty ? FloatingActionButton.extended(
        onPressed: _copyToClipboard,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.share, color: Colors.white),
        label: Text('Paylaş', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Alışveriş listeniz boş',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Haftalık plan oluşturduğunuzda malzemeler burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, int checked, int total) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alışveriş İlerlemesi',
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
                        '$checked',
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
                          '/ $total ürün',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, List<ShoppingItem>> categorizedItems) {
    return Row(
      children: categorizedItems.entries.take(3).map((entry) {
        final info = _categoryInfo[entry.key] ?? _categoryInfo['Diğer']!;
        final checkedInCategory = entry.value.where((i) => i.isChecked).length;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    info['icon'] as IconData,
                    color: info['color'] as Color,
                    size: 22,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '$checkedInCategory/${entry.value.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  entry.key.split(' ').first,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection(String category, List<ShoppingItem> items) {
    final info = _categoryInfo[category] ?? _categoryInfo['Diğer']!;
    final color = info['color'] as Color;
    final icon = info['icon'] as IconData;
    final checkedCount = items.where((i) => i.isChecked).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          margin: EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: checkedCount == items.length && items.isNotEmpty
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$checkedCount/${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: checkedCount == items.length && items.isNotEmpty
                        ? Colors.green
                        : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Items
        ...items.map((item) => _buildShoppingItem(item, color)).toList(),
        
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildShoppingItem(ShoppingItem item, Color categoryColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: item.isChecked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isChecked ? Colors.grey.shade200 : categoryColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: item.isChecked ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              item.isChecked = !item.isChecked;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.isChecked ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isChecked ? Colors.green : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                SizedBox(width: 16),
                // Item Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          color: item.isChecked ? Colors.grey : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${item.amount.toString().replaceAll(RegExp(r'\.0$'), '')} ${item.unit}',
                        style: TextStyle(
                          fontSize: 13,
                          color: item.isChecked ? Colors.grey[400] : categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button when checked
                if (item.isChecked)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      setState(() {
                        _items.remove(item);
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
