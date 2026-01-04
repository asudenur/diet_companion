import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hoş Geldiniz',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Diyet Yoldaşınız',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home_outlined,
              title: 'Ana Sayfa',
              onTap: () {
                Navigator.pop(context); // Close drawer
                // Pop until home, or just pop if already on a single-level screen
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.restaurant_menu,
              title: 'Besin Veritabanı',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/foods');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.favorite_outline,
              title: 'Favori Besinler',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/favorites');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.history,
              title: 'Öğün Geçmişi',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/history');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Bildirimler',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notification_settings');
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.smart_toy,
              title: 'Kalori Asistanı',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
