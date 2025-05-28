import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'calorie_calculator_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_details_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Store selected meals for each type with description and calories
  Map<String, Map<String, dynamic>> _selectedMeals = {
    'Kahvaltı': {'description': '', 'calories': 0, 'isEaten': false},
    'Öğle Yemeği': {'description': '', 'calories': 0, 'isEaten': false},
    'Akşam Yemeği': {'description': '', 'calories': 0, 'isEaten': false},
    'Ara Öğün 1': {'description': '', 'calories': 0, 'isEaten': false},
    'Ara Öğün 2': {'description': '', 'calories': 0, 'isEaten': false},
  };

  int? _dailyCalorieNeed; // Store user's daily calorie need
  int? _waterNeeded; // Store user's daily water need
  String? _goal; // Store user's goal
  int _consumedCalories = 0; // Store the total consumed calories

  @override
  void initState() {
    super.initState();
    _fetchDailyCalorieNeed();
  }

  Future<void> _fetchDailyCalorieNeed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not logged in.'); // Added debug print
        return;
      }

      final userData = await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        final data = userData.data(); // Get all data
        print('Fetched user data: $data'); // Added debug print to show all data

        setState(() {
          _dailyCalorieNeed = data?['dailyCalorieNeed'] as int?; // Assuming calorie need is an int field
          _waterNeeded = data?['waterNeeded'] as int?; // Assuming water need is an int field
          _goal = data?['goal'] as String?; // Assuming goal is a string field
        });

        print('Daily Calorie Need: $_dailyCalorieNeed'); // Added debug print
        print('Water Needed: $_waterNeeded'); // Added debug print
        print('Goal: $_goal'); // Added debug print

      } else {
        print('User data does not exist in Firestore.'); // Added debug print
      }
    } catch (e) {
      print('Error fetching daily calorie need: $e');
    }
  }

  Future<void> _fetchMealOptions(String mealType) async {
    print('Attempting to fetch options for: $mealType'); // Debug print
    if (_dailyCalorieNeed == null) {
      // Optionally show a message to the user that calorie need is not available
      print('Daily calorie need not available for $mealType fetching.'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Günlük kalori ihtiyacınız belirlenmedi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('User daily calorie need: $_dailyCalorieNeed'); // Debug print

    try {
      // Query the documents under the mealType collection (e.g., 'meals/Kahvaltı')
      final querySnapshot = await FirebaseFirestore.instance
          .collection(mealType) // Query the top-level collection named by mealType
          .get();

      print('Fetched all calorie ranges for $mealType: ${querySnapshot.docs.map((doc) => doc.id).toList()}'); // Debug print

      // Find the document whose ID matches the calorie range
      String? matchingRangeDocId;
      for (var doc in querySnapshot.docs) {
        final rangeString = doc.id;
        try {
          final range = rangeString.split(' - ').map(int.parse).toList();
           print('Checking range: $rangeString'); // Debug print
          if (range.length == 2 && _dailyCalorieNeed! >= range[0] && _dailyCalorieNeed! <= range[1]) {
            matchingRangeDocId = doc.id;
            print('Matching range found: $matchingRangeDocId'); // Debug print
            break; // Found the matching range, no need to check others
          }
    } catch (e) {
           print('Could not parse range string "$rangeString": $e'); // Debug print
           // Continue to the next document if parsing fails
        }
      }

      if (matchingRangeDocId != null) {
        final mealDetailsSnapshot = await FirebaseFirestore.instance
            .collection(mealType) // Use the mealType (e.g., Kahvaltı)
            .doc(matchingRangeDocId) // Use the selected calorie range document ID
            .get();

        if (mealDetailsSnapshot.exists) {
          final data = mealDetailsSnapshot.data()!;
          print('Fetched meal details data for $mealType and range $matchingRangeDocId: $data'); // Debug print
          // Extract meal descriptions from fields with numeric keys (1, 2, etc.)
          List<String> mealOptions = [];
          data.forEach((key, value) {
            if (int.tryParse(key) != null) { // Check if the key is a numeric string
               mealOptions.add(value.toString());
            }
          });
          print('Extracted meal options for $mealType: $mealOptions'); // Debug print

          if (mealOptions.isNotEmpty) {
             // Randomly select one meal option
            final random = Random();
            final selectedMeal = mealOptions[random.nextInt(mealOptions.length)];
            _showMealSelectionDialog(mealType, selectedMeal, mealOptions); // Pass the single selected meal and the full list for "Değiştir"
          } else {
             print('No meal options found for $mealType in range $matchingRangeDocId.'); // Debug print
             _showMealSelectionDialog(mealType, 'Bu aralıkta öğün bulunamadı.', []); // Show dialog with message and empty options list
          }

        } else {
          print('Meal details document not found for $mealType and range: $matchingRangeDocId'); // Debug print
          _showMealSelectionDialog(mealType, 'Detay bulunamadı.', []); // Show dialog with message and empty options list
        }
      } else {
        print('No matching calorie range found for $mealType.'); // Debug print
        _showMealSelectionDialog(mealType, 'Kalori aralığınıza uygun öğün bulunamadı.', []); // Show dialog with message and empty options list
      }

    } catch (e) {
      print('Error fetching $mealType options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mealType seçenekleri getirilirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
      _showMealSelectionDialog(mealType, 'Hata oluştu.', []); // Show dialog with error message
    }
  }

  Future<void> _fetchSnackOptions(String snackType) async {
    print('Attempting to fetch snack options for: $snackType'); // Debug print
    if (_dailyCalorieNeed == null) {
      // Optionally show a message to the user that calorie need is not available
      print('Daily calorie need not available for snack fetching.'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Günlük kalori ihtiyacınız belirlenmedi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('User daily calorie need: $_dailyCalorieNeed'); // Debug print

    try {
      final snackOptionsSnapshot = await FirebaseFirestore.instance
          .collection('Ara Öğün') // Query the top-level 'Ara Öğün' collection
          .get();

      print('Fetched all snack calorie ranges: ${snackOptionsSnapshot.docs.map((doc) => doc.id).toList()}'); // Debug print

      // Find the document whose ID matches the calorie range
      String? matchingRangeDocId;
      for (var doc in snackOptionsSnapshot.docs) {
        final rangeString = doc.id;
        try {
        final range = rangeString.split(' - ').map(int.parse).toList();
        print('Checking range: $rangeString'); // Debug print
        if (range.length == 2 && _dailyCalorieNeed! >= range[0] && _dailyCalorieNeed! <= range[1]) {
          matchingRangeDocId = doc.id;
          print('Matching range found: $matchingRangeDocId'); // Debug print
          break;
          }
        } catch (e) {
           print('Could not parse range string "$rangeString": $e'); // Debug print
           // Continue to the next document if parsing fails
        }
      }

      if (matchingRangeDocId != null) {
        final mealDetailsSnapshot = await FirebaseFirestore.instance
            .collection('Ara Öğün')
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

          if (snackOptions.isNotEmpty) {
            // Randomly select one snack option
            final random = Random();
            final selectedSnack = snackOptions[random.nextInt(snackOptions.length)];
            _showMealSelectionDialog(snackType, selectedSnack, snackOptions); // Pass the single selected snack and the full list
          } else {
             print('No snack options found for range: $matchingRangeDocId'); // Debug print
             _showMealSelectionDialog(snackType, 'Bu aralıkta ara öğün bulunamadı.', []); // Show dialog with message and empty options list
          }

        } else {
          print('Snack details document not found for range: $matchingRangeDocId'); // Debug print
          _showMealSelectionDialog(snackType, 'Detay bulunamadı.', []); // Show empty dialog with message and empty options list
        }
      } else {
        print('No matching calorie range found for snack.'); // Debug print
        _showMealSelectionDialog(snackType, 'Kalori aralığınıza uygun ara öğün bulunamadı.', []); // Show empty dialog with message and empty options list
      }

    } catch (e) {
      print('Error fetching snack options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ara öğün seçenekleri getirilirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
      _showMealSelectionDialog(snackType, 'Hata oluştu.', []); // Show dialog with error message
    }
  }

  void _showMealSelectionDialog(String mealType, String selectedMeal, List<String> mealOptions) {
    print('Showing meal selection dialog for $mealType with options: $mealOptions. Initially selected: $selectedMeal'); // Debug print

    // Use StatefulBuilder to manage the state of the dialog internally
    showDialog( // Use showDialog here
      context: context,
      builder: (BuildContext context) {
        // State variable to hold the currently displayed meal in the dialog
        String currentDisplayedMeal = selectedMeal;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('$mealType Menüsü'), // Updated title
              content: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum size
                crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
                children: [
                  Text(
                    'Seçilen Öğün:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentDisplayedMeal,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // "Değiştir" button: Select another random meal
                    if (mealOptions.isNotEmpty) {
                      final random = Random();
                      setState(() {
                        currentDisplayedMeal = mealOptions[random.nextInt(mealOptions.length)];
                        print('Changed $mealType to: $currentDisplayedMeal'); // Debug print
                      });
                    } else {
                      // Handle case where there are no options to change to
                       print('No other options to change for $mealType.'); // Debug print
                    }
                  },
                  child: const Text('Değiştir'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // "İptal" button
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    // "Ekle" button: Save the currentDisplayedMeal and close dialog
                    print('Adding $mealType: $currentDisplayedMeal'); // Debug print
                    // Extract calories from the meal description (e.g., "255 - 285 kcal")
                    int calories = 0;
                    final calorieMatch = RegExp(r'(\d+)\s*-\s*\d+\s*kcal').firstMatch(currentDisplayedMeal);
                    if (calorieMatch != null && calorieMatch.group(1) != null) {
                      calories = int.tryParse(calorieMatch.group(1)!) ?? 0;
                    }
                    // Update the state in the main HomeScreen widget
                    this.setState(() {
                      _selectedMeals[mealType] = {
                        'description': currentDisplayedMeal,
                        'calories': calories,
                        'isEaten': false
                      };
                    });
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
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
                title: const Text('Diyet Yoldaşı'),
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
                                '${_consumedCalories}',
                                'kcal',
                                Icons.local_fire_department,
                              ),
                              _buildStatItem(
                                context,
                                'Su',
                                _waterNeeded != null ? '${(_waterNeeded! / 1000).toStringAsFixed(1)}' : '--',
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
                            Icons.breakfast_dining,
                            onTap: () => _fetchMealOptions('Kahvaltı'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Ara Öğün 1',
                            Icons.fastfood_outlined, // Snack icon
                            onTap: () => _fetchSnackOptions('Ara Öğün 1'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Öğle Yemeği',
                            Icons.lunch_dining,
                            onTap: () => _fetchMealOptions('Öğle Yemeği'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Ara Öğün 2',
                            Icons.fastfood_outlined, // Snack icon
                            onTap: () => _fetchSnackOptions('Ara Öğün 2'),
                          ),
                          const Divider(),
                          _buildMealItem(
                            context,
                            'Akşam Yemeği',
                            Icons.dinner_dining,
                            onTap: () => _fetchMealOptions('Akşam Yemeği'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Seçilen Öğünler Kartı
                  Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _showSelectedMealsDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Seçilen Öğünler',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
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

  Widget _buildMealItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    // Get the selected meal data for this meal type
    final mealData = _selectedMeals[title];
    final mealDescription = mealData?['description'] ?? '';
    final mealCalories = mealData?['calories'] ?? 0; // Default to 0 if no calories found

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
                  if (mealDescription.isNotEmpty) ...[
                    Text(
                      '${mealCalories} kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      mealDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Text(
                      '-- kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.add),
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

  void _showSelectedMealsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seçilen Öğünler'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use minimum size for the column
            children: [
              // Check if any meals are selected before showing the list
              if (_selectedMeals.values.any((meal) => meal['description']!.isNotEmpty))
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _selectedMeals.length,
                  itemBuilder: (context, index) {
                    final mealType = _selectedMeals.keys.elementAt(index);
                      final mealData = _selectedMeals[mealType];
                      final mealDescription = mealData?['description'] ?? '';
                      final mealCalories = mealData?['calories'] ?? 0; // Get calorie value
                      final isEaten = mealData?['isEaten'] ?? false; // Get eaten status

                      // Only display meal types that have a selected meal
                      if (mealDescription.isEmpty) {
                        return const SizedBox.shrink(); // Hide if no meal is selected for this type
                      }

                      return CheckboxListTile(
                        title: Text('$mealType: $mealDescription ($mealCalories kcal)'), // Display calories
                        value: isEaten,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            setState(() {
                              // Update the isEaten status for the specific meal type
                              _selectedMeals[mealType]?['isEaten'] = newValue;

                              // Update consumed calories based on the change
                              if (newValue) {
                                _consumedCalories += mealCalories as int; // Add calories when marked as eaten
                              } else {
                                _consumedCalories -= mealCalories as int; // Subtract calories when unmarked
                              }
                              // Ensure consumed calories don't go below zero
                              if (_consumedCalories < 0) {
                                _consumedCalories = 0;
                              }
                            });
                             // Close the dialog after updating the state
                            Navigator.of(context).pop();
                             // Re-open the dialog to show updated checkboxes and total
                            _showSelectedMealsDialog(context);
                          }
                        },
                      );
                    },
                  ),
                ) else // Show a message if no meals are selected
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text(
                       'Henüz seçilen bir öğün bulunmamaktadır.',
                       style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                     ),
                   ),
                   const SizedBox(height: 16), // Add some spacing
                   Text(
                     'Toplam Tüketilen Kalori: ', // Label for total calories
                      style: Theme.of(context).textTheme.titleMedium,
                   ),
                   Text(
                     '$_consumedCalories kcal', // Display total consumed calories
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
} 