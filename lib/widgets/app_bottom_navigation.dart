import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  
  const AppBottomNavigation({
    Key? key, 
    this.currentIndex = -1, // -1 means no tab is selected (we're on a sub-page)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex >= 0 ? currentIndex : 0,
      onDestinationSelected: (index) {
        // Navigate to home and set the tab
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: {'tabIndex': 0});
        } else if (index == 1) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: {'tabIndex': 1});
        } else if (index == 2) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: {'tabIndex': 2});
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Diyetler',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
