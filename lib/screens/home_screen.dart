import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'calorie_calculator_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Store selected meals for each type
  Map<String, String> _selectedMeals = {
    'Kahvaltı': '',
    'Öğle Yemeği': '',
    'Akşam Yemeği': '',
    'Ara Öğün 1': '',
    'Ara Öğün 2': '',
  };

  int? _dailyCalorieNeed; // Store user's daily calorie need
  int? _waterNeeded; // Store user's daily water need
  String? _goal; // Store user's goal

  @override
  void initState() {
    super.initState();
    _fetchDailyCalorieNeed();
  }

  Future<void> _fetchDailyCalorieNeed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _dailyCalorieNeed = userData.data()?['dailyCalorieNeed'] as int?; // Assuming calorie need is an int field
          _waterNeeded = userData.data()?['waterNeeded'] as int?; // Assuming water need is an int field
          _goal = userData.data()?['goal'] as String?; // Assuming goal is a string field
        });
      }
    } catch (e) {
      print('Error fetching daily calorie need: $e');
    }
  }

  Future<void> _fetchMealOptions(String mealType) async {
    print('Attempting to fetch options for: $mealType'); // Debug print
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc(mealType) // Use mealType as the document ID
          .collection('options') // Assuming options are in a subcollection
          .get();

      final mealOptions = querySnapshot.docs.map((doc) => doc.id).toList();
      print('Fetched meal options: $mealOptions'); // Debug print
      _showMealSelectionDialog(mealType, mealOptions);
    } catch (e) {
      print('Error fetching meal options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Öğün seçenekleri getirilirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchSnackOptions(String snackType) async {
    print('Attempting to fetch snack options for: $snackType'); // Debug print
    if (_dailyCalorieNeed == null) {
      // Optionally show a message to the user that calorie need is not available
      print('Daily calorie need not available for snack fetching.'); // Debug print
      return;
    }

    print('User daily calorie need: $_dailyCalorieNeed'); // Debug print

    try {
      final snackOptionsSnapshot = await FirebaseFirestore.instance
          .collection('meals')
          .doc('Ara Öğün')
          .collection('options')
          .get();

      print('Fetched all snack calorie ranges: ${snackOptionsSnapshot.docs.map((doc) => doc.id).toList()}'); // Debug print

      // Find the document whose ID matches the calorie range
      String? matchingRangeDocId;
      for (var doc in snackOptionsSnapshot.docs) {
        final rangeString = doc.id;
        final range = rangeString.split(' - ').map(int.parse).toList();
        print('Checking range: $rangeString'); // Debug print
        if (range.length == 2 && _dailyCalorieNeed! >= range[0] && _dailyCalorieNeed! <= range[1]) {
          matchingRangeDocId = doc.id;
          print('Matching range found: $matchingRangeDocId'); // Debug print
          break;
        }
      }

      if (matchingRangeDocId != null) {
        final mealDetailsSnapshot = await FirebaseFirestore.instance
            .collection('meals')
            .doc('Ara Öğün')
            .collection('options')
            .doc(matchingRangeDocId)
            .get();

        if (mealDetailsSnapshot.exists) {
          final data = mealDetailsSnapshot.data()!;
          print('Fetched snack details data: $data'); // Debug print
          // Extract meal description from fields 1, 2, etc.
          List<String> snackOptions = [];
          data.forEach((key, value) {
            if (int.tryParse(key) != null) {
              snackOptions.add(value.toString());
            }
          });
          print('Extracted snack options: $snackOptions'); // Debug print
          _showMealSelectionDialog(snackType, snackOptions); // Reuse the meal selection dialog
        } else {
          print('Snack details document not found for range: $matchingRangeDocId'); // Debug print
          _showMealSelectionDialog(snackType, []); // Show empty dialog if document not found
        }
      } else {
        print('No matching calorie range found for snack.'); // Debug print
        _showMealSelectionDialog(snackType, []); // Show empty dialog if no matching range found
      }

    } catch (e) {
      print('Error fetching snack options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ara öğün seçenekleri getirilirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMealSelectionDialog(String mealType, List<String> mealOptions) {
    print('Showing meal selection dialog for $mealType with options: $mealOptions'); // Debug print
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$mealType Menüsü Seçin'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: mealOptions.length,
            itemBuilder: (context, index) {
              final option = mealOptions[index];
              print('Building dialog list tile for option: $option'); // Debug print
              return ListTile(
                title: Text(option), // Display calorie range as option
                onTap: () async {
                  // TODO: Fetch and display meal details
                  print('Selected $mealType: $option in dialog.'); // Debug print

                  try {
                    final mealDetailsSnapshot = await FirebaseFirestore.instance
                        .collection('meals')
                        .doc(mealType)
                        .collection('options')
                        .doc(option) // Use the selected calorie range as document ID or description for snacks
                        .get();

                    if (mealDetailsSnapshot.exists) {
                      final data = mealDetailsSnapshot.data()!;
                      print('Fetched meal details after selection: $data'); // Debug print
                      // Extract meal description from fields 1, 2, etc.
                      String mealDescription = '';
                      data.forEach((key, value) {
                        // Assuming keys are numeric strings like "1", "2", etc.
                        if (int.tryParse(key) != null) {
                           mealDescription += '$value\n';
                        }
                      });
                       // Remove trailing newline if any
                      if (mealDescription.endsWith('\n')) {
                         mealDescription = mealDescription.substring(0, mealDescription.length - 1);
                      }

                      print('Extracted meal description after selection: $mealDescription'); // Debug print

                      setState(() {
                        _selectedMeals[mealType] = mealDescription; // Store meal description
                      });
                    } else {
                       print('Meal details document not found for $mealType and option $option.'); // Debug print
                       setState(() {
                        _selectedMeals[mealType] = 'Detay bulunamadı.'; // Store a placeholder if details not found
                      });
                    }
                  } catch (e) {
                    print('Error fetching meal details after selection: $e'); // Debug print
                     setState(() {
                        _selectedMeals[mealType] = 'Detay yüklenemedi.'; // Store error message
                      });
                  }

                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 50.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Diet Companion'),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                background: Container(
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
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Bildirimler sayfasına yönlendir
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Günlük Özet Kartı
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük Özet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                'Kalori',
                                '2100',
                                'kcal',
                                Icons.local_fire_department,
                              ),
                              _buildStatItem(
                                context,
                                'Su',
                                '1.5',
                                'L',
                                Icons.water_drop,
                              ),
                              _buildStatItem(
                                context,
                                'Adım',
                                '5,420',
                                'adım',
                                Icons.directions_walk,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Kalori Hesaplama Kartı
                  Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/calorie_calculator');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calculate_outlined,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kalori Hesaplama',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Günlük kalori ihtiyacınızı hesaplayın',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Su Tüketimi Hesaplama Kartı
                  Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            throw Exception('Kullanıcı oturum açmamış');
                          }

                          final userData = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();

                          if (!userData.exists) {
                            throw Exception('Kullanıcı bilgileri bulunamadı');
                          }

                          final data = userData.data()!;
                          final weight = data['weight'] as num;
                          final waterNeeded = (weight * 30).round();

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.water_drop,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Günlük Su İhtiyacınız'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$waterNeeded ml',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kilonuz: ${weight.round()} kg\nFormül: Kilo × 30 ml',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Tamam'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.8),
                              Colors.lightBlue.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.water_drop_outlined,
                                  size: 24,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Su Tüketimi',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Günlük su ihtiyacınızı hesaplayın',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Öğün Takibi Kartı
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bugünkü Öğünler',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildMealItem(
                            context,
                            'Kahvaltı',
                            '320 kcal',
                            Icons.breakfast_dining,
                            onTap: () => _fetchMealOptions('Kahvaltı'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Ara Öğün',
                            '-', // Placeholder calories
                            Icons.fastfood_outlined, // Snack icon
                            onTap: () => _fetchSnackOptions('Ara Öğün 1'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Öğle Yemeği',
                            '450 kcal',
                            Icons.lunch_dining,
                            onTap: () => _fetchMealOptions('Öğle Yemeği'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Ara Öğün',
                            '-', // Placeholder calories
                            Icons.fastfood_outlined, // Snack icon
                            onTap: () => _fetchSnackOptions('Ara Öğün 2'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Akşam Yemeği',
                            '580 kcal',
                            Icons.dinner_dining,
                            onTap: () => _fetchMealOptions('Akşam Yemeği'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, String unit, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealItem(BuildContext context, String title, String calories, IconData icon, {VoidCallback? onTap}) {
    // Get the selected meal description for this meal type
    // final selectedMealDescription = _selectedMeals[title]; // Keep this for updating the map, but not for display here

    return InkWell(
      onTap: onTap, // Use the provided onTap callback
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  // Always display the initial calorie placeholder
                  Text(
                    calories,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Always display "Ekle" text
            const Icon(Icons.add), // Plus icon
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

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
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 50.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(user?.displayName ?? 'Profil'),
              background: Container(
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'Kullanıcı',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Kişisel Hedefler Kartı
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Hedefler',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileInfoRow(
                          context,
                          'Günlük Kalori İhtiyacı',
                          _dailyCalorieNeed != null ? '${_dailyCalorieNeed} kcal' : 'Yükleniyor...',
                          Icons.local_fire_department_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileInfoRow(
                          context,
                          'Günlük Su İhtiyacı',
                          _waterNeeded != null ? '${_waterNeeded} ml' : 'Yükleniyor...',
                          Icons.water_drop_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildProfileInfoRow(
                          context,
                          'Hedef',
                          _goal ?? 'Yükleniyor...',
                          Icons.track_changes_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Profil Bilgileri'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Ayarlar'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Ayarlar sayfasına yönlendir
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.exit_to_app),
                        title: const Text('Çıkış Yap'),
                        onTap: () async {
                          await authService.signOut();
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
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
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
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
    );
  }
} 