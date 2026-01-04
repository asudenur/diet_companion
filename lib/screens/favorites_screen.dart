import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({Key? key}) : super(key: key);

  final FoodService _service = FoodService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Favoriler'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<FoodItem>>(
        stream: _service.favoritesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final favs = snapshot.data!;
          if (favs.isEmpty) {
            return const Center(child: Text('Favori eklenmemiş'));
          }
          return ListView.separated(
            itemCount: favs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = favs[i];
              return ListTile(
                title: Text(f.name),
                subtitle: Text('${f.category} • ${f.calories} kcal'),
                trailing: PopupMenuButton<String>(
                  onSelected: (mealType) async {
                    Navigator.pop(context, {'mealType': mealType, 'food': f});
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Kahvaltı', child: Text('Kahvaltı')),
                    PopupMenuItem(value: 'Öğle Yemeği', child: Text('Öğle Yemeği')),
                    PopupMenuItem(value: 'Akşam Yemeği', child: Text('Akşam Yemeği')),
                    PopupMenuItem(value: 'Ara Öğün', child: Text('Ara Öğün')),
                  ],
                  child: const Icon(Icons.add_circle_outline),
                ),
                onLongPress: () async {
                  await _service.toggleFavorite(f);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}


