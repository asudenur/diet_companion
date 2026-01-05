import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'profile_details_screen.dart';
import 'plan_screen.dart';
import 'dart:math';
import '../services/water_service.dart';
import '../services/meal_service.dart';
import '../services/recipe_service.dart';
import '../services/diet_filter_service.dart';
import '../services/plan_service.dart';
import '../models/meal_entry.dart';
import 'recipe_screen.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  // Store selected meals for each type with description and calories
  Map<String, Map<String, dynamic>> _selectedMeals = {
    'Kahvaltı': {'description': '', 'calories': 0, 'isEaten': false, 'recipeId': null},
    'Öğle Yemeği': {'description': '', 'calories': 0, 'isEaten': false, 'recipeId': null},
    'Akşam Yemeği': {'description': '', 'calories': 0, 'isEaten': false, 'recipeId': null},
    'Ara Öğün 1': {'description': '', 'calories': 0, 'isEaten': false, 'recipeId': null},
    'Ara Öğün 2': {'description': '', 'calories': 0, 'isEaten': false, 'recipeId': null},
  };

  int? _dailyCalorieNeed; // Store user's daily calorie need
  int? _waterNeeded; // Store user's daily water need
  
  // Profil fotoğrafı için değişkenler
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  
  // Profil sayfası Scaffold key'i
  final GlobalKey<ScaffoldState> _profileScaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Web ve mobil için bytes kullan
        final bytes = await pickedFile.readAsBytes();
        await _uploadImageBytes(bytes, pickedFile.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _uploadImageBytes(Uint8List imageBytes, String fileName) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Timeout ile yükleme (30 saniye)
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
      
      final downloadUrl = await storageRef.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Upload error: $e');
    }
  }
  String? _goal; // Store user's goal
  String? _selectedDietType; // Store user's selected diet type
  int _consumedCalories = 0; // Store the total consumed calories

  final MealService _mealService = MealService();
  final RecipeService _recipeService = RecipeService();
  final WaterService _waterService = WaterService();
  final DietFilterService _dietFilterService = DietFilterService();
  final PlanService _planService = PlanService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _fetchDailyCalorieNeed();
    _loadTodayMeals();
  }

  // mealDescription'dan ana yemek adını çıkaran yardımcı fonksiyon
  String _extractMainFoodName(String mealDescription) {
    String cleaned = mealDescription.replaceAll(RegExp(r'^\d+-\d+\s*kcal\s*'), '');
    
    int colonIndex = cleaned.indexOf(':');
    if (colonIndex != -1) {
      cleaned = cleaned.substring(0, colonIndex);
    }

    // Kalori bilgilerini temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+\s*(dilim|bardak|küçük bardak|adet)\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+/\d+\s*bardak\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'yarım\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'az tuzlu\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'tam buğday\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'unlu\s*'), '');

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Özel eşleştirmeler
    if (cleaned.toLowerCase().contains('avokado ezmesi')) return 'Avokado Tost';
    if (cleaned.toLowerCase().contains('yulaf ezmesi')) return 'Yulaf Ezmesi';
    if (cleaned.toLowerCase().contains('pankek')) return 'Tam Buğday Pankek';
    if (cleaned.toLowerCase().contains('haşlanmış yumurta') && cleaned.toLowerCase().contains('peynir')) return 'Haşlanmış Yumurta ve Peynir';
    if (cleaned.toLowerCase().contains('haşlanmış yumurta') && cleaned.toLowerCase().contains('zeytin')) return 'Zeytinli Kahvaltı';
    if (cleaned.toLowerCase().contains('ton balıklı salata')) return 'Ton Balıklı Salata';
    if (cleaned.toLowerCase().contains('elma ve badem')) return 'Elma ve Badem';
    if (cleaned.toLowerCase().contains('kinoa salatası')) return 'Kinoa Salatası';
    if (cleaned.toLowerCase().contains('köfte')) return 'Fırında Köfte';
    if (cleaned.toLowerCase().contains('ızgara somon')) return 'Izgara Somon';
    if (cleaned.toLowerCase().contains('ızgara tavuk')) return 'Izgara Tavuk';
    if (cleaned.toLowerCase().contains('ızgara balık')) return 'Izgara Balık';
    if (cleaned.toLowerCase().contains('yoğurt ve meyve')) return 'Yoğurt ve Meyve';

    return cleaned;
  }

  // Tarif ID'si oluşturma - recipes koleksiyonundan uygun tarifi bul
  Future<String?> _generateRecipeId(String mealDescription, String mealType) async {
    try {
      String mainFoodName = _extractMainFoodName(mealDescription);
      print('Extracted main food name: "$mainFoodName" for mealType: "$mealType"');
      
      if (mainFoodName.isEmpty) {
        return null;
      }

      // Önce kategoriye göre ara
      QuerySnapshot categoryQuerySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('category', isEqualTo: mealType)
          .get();

      for (var doc in categoryQuerySnapshot.docs) {
        String recipeName = doc['name'].toString();
        if (recipeName == mainFoodName) {
          print('Found recipe in category "$mealType": ${doc['name']}');
          return doc.id;
        }
      }

      // Kategoriye göre bulamazsa genel arama yap
      QuerySnapshot allRecipesQuerySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .get();

      for (var doc in allRecipesQuerySnapshot.docs) {
        String recipeName = doc['name'].toString();
        if (recipeName == mainFoodName) {
          print('Found recipe in all categories: ${doc['name']}');
          return doc.id;
        }
      }

      print('No recipe found for "$mainFoodName" in category "$mealType" or globally.');
      return null;
    } catch (e) {
      print('Tarif ID oluşturulurken hata: $e');
      return null;
    }
  }

  // Bugünkü öğünleri yükle
  Future<void> _loadTodayMeals() async {
    try {
      final todayMeals = await _mealService.getDailyMeals(DateTime.now());
      
      // Bugünün öğünlerini _selectedMeals'e yükle
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (var meal in todayMeals) {
        // Tarih karşılaştırması (sadece gün bazlı)
        final mealDate = DateTime(meal.date.year, meal.date.month, meal.date.day);
        if (mealDate.isAtSameMomentAs(today)) {
          // Öğün tipine göre _selectedMeals'i güncelle
          if (_selectedMeals.containsKey(meal.mealType)) {
            // Description varsa onu kullan, yoksa foodName kullan
            final mealDescription = meal.description.isNotEmpty ? meal.description : meal.foodName;
            
            // Components'ları parse et (eğer description varsa)
            List<Map<String, dynamic>> components = [];
            if (mealDescription.isNotEmpty) {
              components = _parseMealComponents(mealDescription, totalMealCalories: meal.calories > 0 ? meal.calories : null);
            }
            
            _selectedMeals[meal.mealType] = {
              'description': mealDescription,
              'calories': meal.calories,
              'isEaten': meal.isEaten,
              'recipeId': meal.recipeId,
              'components': components,
            };
          }
        }
      }
      
      // Tüketilen kaloriyi seçilen bileşenlerin kalorilerine göre hesapla
      _updateConsumedCalories();
    } catch (e) {
      print('Bugünkü öğünler yüklenemedi: $e');
    }
  }

  // Tüketilen kaloriyi seçilen bileşenlerin kalorilerine göre güncelle
  void _updateConsumedCalories() {
    int totalCalories = 0;
    
    for (var mealData in _selectedMeals.values) {
      if (mealData['isEaten'] == true) {
        // Eğer components varsa, seçilen bileşenlerin kalorilerini topla
        if (mealData['components'] != null && (mealData['components'] as List).isNotEmpty) {
          final components = List<Map<String, dynamic>>.from(mealData['components'] as List);
          final selectedComponentsCalories = components
              .where((component) => component['isSelected'] == true)
              .fold(0, (sum, component) => sum + (component['calories'] as int));
          totalCalories += selectedComponentsCalories;
        } else {
          // Components yoksa, öğünün toplam kalorisini kullan
          totalCalories += (mealData['calories'] ?? 0) as int;
        }
      }
    }
    
    setState(() {
      _consumedCalories = totalCalories;
    });
  }

  // Öğün detaylarını gösteren dialog
  void _showMealDetailsDialog(String mealDescription, int calories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğün Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealDescription,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '$calories kcal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bu öğün için henüz detaylı tarif mevcut değil. Yakında eklenecek!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Öğün kaydetme fonksiyonu
  Future<void> _saveMealAsEaten(String mealType, String mealDescription, int calories, String? recipeId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Mevcut öğünün description'ını al (eğer varsa)
      final currentMealData = _selectedMeals[mealType];
      final fullDescription = currentMealData?['description'] ?? mealDescription;
      
      final mealEntry = MealEntry(
        id: '', // Firebase otomatik ID oluşturacak
        userId: user.uid,
        date: DateTime.now(),
        mealType: mealType,
        foodName: mealDescription,
        calories: calories,
        protein: 0, // Bu değerler tarif varsa oradan gelecek
        carbs: 0,
        fat: 0,
        isEaten: true,
        eatenAt: DateTime.now(),
        recipeId: recipeId,
        description: fullDescription, // Tam description'ı kaydet
      );

      await _mealService.saveMealEntry(mealEntry);
      
      // Öğünü _selectedMeals'e kaydet
      setState(() {
        _selectedMeals[mealType]?['isEaten'] = true;
        _selectedMeals[mealType]?['calories'] = calories;
        // Description'ı da güncelle
        if (_selectedMeals[mealType] != null) {
          _selectedMeals[mealType]!['description'] = fullDescription;
        }
      });
      
      // Tüketilen kaloriyi güncelle (seçilen bileşenlerin kalorilerine göre)
      _updateConsumedCalories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mealType kaydedildi! ($calories kcal)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          _selectedDietType = data?['selectedDietType'] as String?; // Selected diet type
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
      // Determine which collection to query based on diet type
      String collectionName = mealType;
      
      // If user has selected a specific diet (and it's not "Önerilen Diyet"), 
      // try to find diet-specific meals
      if (_selectedDietType != null && 
          _selectedDietType!.isNotEmpty && 
          _selectedDietType != 'Önerilen Diyet') {
        // Try diet-specific collection first (e.g., "Kahvaltı_Keto")
        final dietCollectionName = '${mealType}_$_selectedDietType';
        final dietQuerySnapshot = await FirebaseFirestore.instance
            .collection(dietCollectionName)
            .get();
        
        // If diet-specific meals exist, use them
        if (dietQuerySnapshot.docs.isNotEmpty) {
          collectionName = dietCollectionName;
        }
      }
      
      // Query the documents under the mealType collection (e.g., 'meals/Kahvaltı')
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName) // Query the collection (with or without diet type)
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
        // Determine which collection to use (same logic as above)
        String collectionName = mealType;
        if (_selectedDietType != null && 
            _selectedDietType!.isNotEmpty && 
            _selectedDietType != 'Önerilen Diyet') {
          final dietCollectionName = '${mealType}_$_selectedDietType';
          final dietCheck = await FirebaseFirestore.instance
              .collection(dietCollectionName)
              .limit(1)
              .get();
          if (dietCheck.docs.isNotEmpty) {
            collectionName = dietCollectionName;
          }
        }
        
        final mealDetailsSnapshot = await FirebaseFirestore.instance
            .collection(collectionName) // Use the appropriate collection
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
            // Diyet tipine göre öğünleri filtrele ve sırala
            final filteredAndSortedMeals = await _dietFilterService.getFilteredMeals(mealType, mealOptions);
            print('Filtered and sorted meals for $mealType: $filteredAndSortedMeals'); // Debug print
            
            // Diyet tipine uygun öğünleri önce seç
            final random = Random();
            final selectedMeal = filteredAndSortedMeals.isNotEmpty 
                ? filteredAndSortedMeals[random.nextInt(filteredAndSortedMeals.length)]
                : mealOptions[random.nextInt(mealOptions.length)];
            
            _showMealSelectionDialog(mealType, selectedMeal, filteredAndSortedMeals.isNotEmpty ? filteredAndSortedMeals : mealOptions);
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

    try {
      // Direkt Ara Öğün koleksiyonundaki tek dokümanı al
      final snackDoc = await FirebaseFirestore.instance
            .collection('Ara Öğün')
          .doc('Ara Öğün')
            .get();

      if (snackDoc.exists) {
        final data = snackDoc.data()!;
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
          _showMealSelectionDialog(snackType, selectedSnack, snackOptions);
          } else {
          print('No snack options found.'); // Debug print
          _showMealSelectionDialog(snackType, 'Ara öğün bulunamadı.', []);
          }
        } else {
        print('Snack document not found.'); // Debug print
        _showMealSelectionDialog(snackType, 'Ara öğün dokümanı bulunamadı.', []);
      }

    } catch (e) {
      print('Error fetching snack options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ara öğün seçenekleri getirilirken hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
      _showMealSelectionDialog(snackType, 'Hata oluştu.', []);
    }
  }

  void _showMealSelectionDialog(String mealType, String selectedMeal, List<String> mealOptions) {
    print('Showing meal selection dialog for $mealType with options: $mealOptions. Initially selected: $selectedMeal');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String currentDisplayedMeal = selectedMeal;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('$mealType Menüsü'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (mealOptions.isNotEmpty) {
                      final random = Random();
                      setState(() {
                        currentDisplayedMeal = mealOptions[random.nextInt(mealOptions.length)];
                      });
                    }
                  },
                  child: const Text('Değiştir'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () async {
                    // Extract calories from the meal description
                    int calories = 0;
                    final calorieMatch = RegExp(r'(\d+)\s*-\s*\d+\s*kcal').firstMatch(currentDisplayedMeal);
                    if (calorieMatch != null && calorieMatch.group(1) != null) {
                      calories = int.tryParse(calorieMatch.group(1)!) ?? 0;
                    }
                    
                    // Tarif ID'sini async olarak oluştur
                    final recipeId = await _generateRecipeId(currentDisplayedMeal, mealType);
                    
                    // Update the state in the main HomeScreen widget
                    this.setState(() {
                      _selectedMeals[mealType] = {
                        'description': currentDisplayedMeal,
                        'calories': calories,
                        'isEaten': false,
                        'recipeId': recipeId,
                      };
                    });
                    Navigator.of(context).pop();
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

  // Öğün bileşenlerini parse eden fonksiyon
  List<Map<String, dynamic>> _parseMealComponents(String mealDescription, {int? totalMealCalories}) {
    List<Map<String, dynamic>> components = [];
    
    // Eğer description boşsa, totalMealCalories varsa onu kullan
    if (mealDescription.trim().isEmpty) {
      if (totalMealCalories != null && totalMealCalories > 0) {
        return [{
          'name': 'Öğün',
          'calories': totalMealCalories,
          'isSelected': true,
        }];
      }
      return [];
    }
    
    // Öğün açıklamasından bileşenleri çıkar
    // Örnek: "3/4 bardak granola (az şekerli): 220-260 kcal"
    final lines = mealDescription.split('\n');
    int totalParsedCalories = 0;
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Sadece kalori aralığı olan satırları atla (örn: "255 - 285 kcal")
      if (RegExp(r'^\d+\s*-\s*\d+\s*kcal$', caseSensitive: false).hasMatch(line)) {
        continue; // Bu satırı atla
      }
      
      // Sadece sayı olan satırları atla
      if (RegExp(r'^\d+$').hasMatch(line)) {
        continue;
      }
      
      // Sadece kalori değeri olan satırları atla
      if (RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      
      // Kalori bilgisini çıkar
      int calories = 0;
      final calorieMatch = RegExp(r'(\d+)(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false).firstMatch(line);
      if (calorieMatch != null && calorieMatch.group(1) != null) {
        calories = int.tryParse(calorieMatch.group(1)!) ?? 0;
      }
      
      // Bileşen adını çıkar (kalori kısmını çıkar)
      String name = line
          .replaceAll(RegExp(r'\s*:\s*\d+(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'≈|~'), '')
          .trim();
      
      // Sadece gerçek besin adları olan satırları ekle
      if (name.isNotEmpty && 
          !RegExp(r'^\d+$').hasMatch(name) && 
          !RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(name) &&
          !RegExp(r'^\d+\s*-\s*\d+\s*kcal$', caseSensitive: false).hasMatch(name)) {
        // Eğer kalori yoksa ve totalMealCalories varsa, şimdilik 0 olarak bırak
        if (calories == 0 && totalMealCalories != null && totalMealCalories > 0) {
          // Şimdilik 0, sonra dağıtacağız
          calories = 0;
        } else if (calories == 0 && components.isNotEmpty) {
          // Önceki bileşenlerin ortalamasını al
          final avg = components.map((c) => c['calories'] as int).where((c) => c > 0).fold(0, (a, b) => a + b);
          final count = components.where((c) => c['calories'] as int > 0).length;
          calories = count > 0 ? (avg / count).round() : 0;
        }
        
        if (calories > 0) {
          totalParsedCalories += calories;
        }
        
        components.add({
          'name': name,
          'calories': calories,
          'isSelected': true, // Varsayılan olarak seçili
        });
      }
    }
    
    // Eğer totalMealCalories varsa ve parse edilen kaloriler toplamından farklıysa, farkı dağıt
    if (totalMealCalories != null && totalMealCalories > 0) {
      final componentsWithCalories = components.where((c) => c['calories'] as int > 0).toList();
      final componentsWithoutCalories = components.where((c) => c['calories'] as int == 0).toList();
      
      if (totalParsedCalories == 0 && components.isNotEmpty) {
        // Hiç kalori parse edilemediyse, tüm kaloriyi eşit dağıt
        final caloriesPerComponent = (totalMealCalories / components.length).round();
        for (var component in components) {
          component['calories'] = caloriesPerComponent;
        }
      } else if (totalParsedCalories < totalMealCalories && componentsWithoutCalories.isNotEmpty) {
        // Parse edilen kaloriler toplamdan azsa, farkı kalorisiz bileşenlere dağıt
        final remaining = totalMealCalories - totalParsedCalories;
        final caloriesPerComponent = (remaining / componentsWithoutCalories.length).round();
        for (var component in componentsWithoutCalories) {
          component['calories'] = caloriesPerComponent;
        }
      } else if (totalParsedCalories < totalMealCalories && componentsWithCalories.isNotEmpty) {
        // Tüm bileşenlere eşit dağıt
        final diff = totalMealCalories - totalParsedCalories;
        final addPerComponent = (diff / componentsWithCalories.length).round();
        for (var component in componentsWithCalories) {
          component['calories'] = (component['calories'] as int) + addPerComponent;
        }
      }
    }
    
    // Eğer parse edilemezse, tüm öğünü tek bileşen olarak ekle
    if (components.isEmpty) {
      int totalCalories = totalMealCalories ?? 0;
      if (totalCalories == 0) {
        final calorieMatch = RegExp(r'(\d+)(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false).firstMatch(mealDescription);
        if (calorieMatch != null && calorieMatch.group(1) != null) {
          totalCalories = int.tryParse(calorieMatch.group(1)!) ?? 0;
        }
      }
      
      String cleanName = mealDescription
          .replaceAll(RegExp(r'\s*:\s*\d+(?:\s*-\s*\d+)?\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
          .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
          .trim();
      
      if (cleanName.isEmpty) {
        cleanName = 'Öğün';
      }
      
      components.add({
        'name': cleanName,
        'calories': totalCalories > 0 ? totalCalories : (totalMealCalories ?? 200),
        'isSelected': true,
      });
    }
    
    return components;
  }

  // Seçili öğünler için recipe ingredients'lerini yükle
  Future<void> _loadRecipeIngredientsForSelectedMeals() async {
    for (var mealType in _selectedMeals.keys) {
      final mealData = _selectedMeals[mealType];
      if (mealData == null) continue;
      
      final recipeId = mealData['recipeId'] as String?;
      
      // Eğer recipeId varsa ve components henüz yüklenmemişse
      if (recipeId != null && recipeId.isNotEmpty && (mealData['components'] == null || (mealData['components'] as List).isEmpty)) {
        try {
          final recipe = await _recipeService.getRecipe(recipeId);
          if (recipe != null && recipe.ingredients.isNotEmpty) {
            // Her ingredient için kalori hesapla (toplam kalori / ingredient sayısı)
            final ingredientCount = recipe.ingredients.length;
            int baseCalories = recipe.caloriesPerServing;
            if (baseCalories == 0) {
              // Tarif kalori bilgisi yoksa öğünün kendi kalorisine düş
              baseCalories = (mealData['calories'] is int)
                  ? mealData['calories'] as int
                  : int.tryParse('${mealData['calories']}') ?? 0;
            }
            final caloriesPerIngredient = ingredientCount > 0
                ? (baseCalories / ingredientCount).round()
                : 0;
            
            // Ingredients listesini components formatına çevir
            List<Map<String, dynamic>> components = recipe.ingredients.map((ingredient) {
              return {
                'name': ingredient,
                'calories': caloriesPerIngredient,
                'isSelected': true, // Varsayılan olarak seçili
              };
            }).toList();
            
            // Components'ı kaydet
            mealData['components'] = components;
          }
        } catch (e) {
          // Recipe bulunamazsa veya hata olursa description'dan parse et
          final mealDescription = mealData['description'] ?? '';
          final mealCalories = (mealData['calories'] is int)
              ? mealData['calories'] as int
              : int.tryParse('${mealData['calories']}') ?? 0;
          if (mealDescription.isNotEmpty) {
            final parsed = _parseMealComponents(mealDescription, totalMealCalories: mealCalories > 0 ? mealCalories : null);
            mealData['components'] = parsed;
          } else if (mealCalories > 0) {
            // Description boşsa ama kalori varsa, tek bileşen oluştur
            mealData['components'] = [
              {
                'name': mealType,
                'calories': mealCalories,
                'isSelected': true,
              }
            ];
          }
        }
      } else if (mealData['components'] == null || (mealData['components'] as List).isEmpty) {
        // RecipeId yoksa description'dan parse et
        final mealDescription = mealData['description'] ?? '';
        final mealCalories = (mealData['calories'] is int)
            ? mealData['calories'] as int
            : int.tryParse('${mealData['calories']}') ?? 0;
        if (mealDescription.isNotEmpty) {
          final parsed = _parseMealComponents(mealDescription, totalMealCalories: mealCalories > 0 ? mealCalories : null);
          mealData['components'] = parsed;
        } else if (mealCalories > 0) {
          // Description boşsa ama kalori varsa, tek bileşen oluştur
          mealData['components'] = [
            {
              'name': mealType,
              'calories': mealCalories,
              'isSelected': true,
            }
          ];
        }
      }
    }
  }

  // Bileşen seçim dialogu - "Yedim" butonuna basıldığında açılır
  void _showComponentSelectionDialog(String mealType, String mealDescription, int calories, String? recipeId) {
    // Öğün bileşenlerini parse et, calories'i de geç
    List<Map<String, dynamic>> mealComponents = _parseMealComponents(mealDescription, totalMealCalories: calories > 0 ? calories : null);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Seçilen bileşenlerin kalori toplamını hesapla
            int totalCalories = mealComponents
                .where((component) => component['isSelected'] == true)
                .fold(0, (sum, component) => sum + (component['calories'] as int));

            return AlertDialog(
              title: Text('$mealType - Yediğiniz Bileşenler'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Öğün başlığı
                    Text(
                      'Öğün:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mealDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Bileşenler başlığı
                    Row(
                      children: [
                        Text(
                          'Yediğiniz bileşenleri işaretleyin:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Toplam: $totalCalories kcal',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Bileşen listesi
                    ...mealComponents.map((component) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        value: component['isSelected'] as bool,
                        onChanged: (bool? value) {
                          setState(() {
                            component['isSelected'] = value ?? false;
                          });
                        },
                        title: Text(
                          component['name'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${component['calories']} kcal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        activeColor: Theme.of(context).colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Seçilen bileşenlerin kalori toplamını hesapla
                    int actualCalories = mealComponents
                        .where((component) => component['isSelected'] == true)
                        .fold(0, (sum, component) => sum + (component['calories'] as int));
                    
                    // Öğünü kaydet
                    await _saveMealAsEaten(mealType, mealDescription, actualCalories, recipeId);
                    
                    // Dialog'ları kapat ve ana dialog'u yenile
                    Navigator.of(context).pop(); // Component selection dialog
                    Navigator.of(context).pop(); // Selected meals dialog
                    _showSelectedMealsDialog(context); // Ana dialog'u yenile
                  },
                  child: Text('Kaydet ($totalCalories kcal)'),
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
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomePage(),
              _buildDietsPage(),
              _buildProfilePage(),
            ],
          ),
          // Kalori Asistanı Yuvarlak Buton - AppBar'ın üstünde sağ köşede
          Positioned(
            bottom: 10, // AppBar'ın üstünde
            right: 16,
            child: SafeArea(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.pushNamed(context, '/chatbot');
                    },
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      ),
    );
  }

  Widget _buildHomePage() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (user?.displayName != null)
                    Text(
                      user!.displayName!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xFF2E7D32),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notification_settings');
                  },
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Günlük Özet Kartı
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.today,
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
                                    'Bugünkü İlerlemen',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Hedeflerine ne kadar yaklaştın?',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernStatItem(
                                context,
                                'Kalori',
                                '${_consumedCalories}',
                                'kcal',
                                Icons.local_fire_department,
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildWaterTracker(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Öğün Takibi Kartı
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bugünkü Öğünlerin',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Hangi öğünleri planlıyorsun?',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      await _showSelectedMealsDialog(context);
                      // Dialog kapandıktan sonra kaloriyi güncelle
                      _updateConsumedCalories();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seçilen Öğünler',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tükettiğin öğünleri işaretle',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
    );
  }

  // Mevcut diyet kartı
  Widget _buildCurrentDietCard() {
    final dietMap = <String, Map<String, dynamic>>{
      'Keto': {
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'description': 'Düşük karbonhidrat, yüksek yağ',
      },
      'Aralıklı Oruç': {
        'icon': Icons.timer,
        'color': Colors.blue,
        'description': '16:8 saat yeme penceresi',
      },
      'Akdeniz': {
        'icon': Icons.restaurant,
        'color': Colors.red,
        'description': 'Zeytinyağı, balık, sebze',
      },
      'Su Diyeti': {
        'icon': Icons.water_drop,
        'color': Colors.cyan,
        'description': 'Suya dayalı detoks',
      },
      'Önerilen Diyet': {
        'icon': Icons.favorite,
        'color': Colors.green,
        'description': 'Size özel dengeli beslenme programı',
      },
    };

    final currentDiet = _selectedDietType ?? 'Seçilmedi';
    final selectedDiet = _selectedDietType ?? '';
    final dietInfo = dietMap[selectedDiet] ?? {
      'icon': Icons.help_outline,
      'color': Colors.grey,
      'description': 'Henüz bir diyet seçmediniz',
    };

    final dietColor = (dietInfo['color'] ?? Colors.grey) as Color;
    final dietIcon = (dietInfo['icon'] ?? Icons.help_outline) as IconData;
    final dietDescription = (dietInfo['description'] ?? 'Henüz bir diyet seçmediniz') as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dietColor.withOpacity(0.2),
            dietColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dietColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dietColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              dietIcon,
              color: dietColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Şu Anki Diyetiniz',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentDiet,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dietColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dietDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Diyet değiştirme fonksiyonu
  Future<void> _changeDiet(String dietName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore'u güncelle
      await FirebaseFirestore.instance
          .collection('user_infos')
          .doc(user.uid)
          .update({
        'selectedDietType': dietName,
      });

      // State'i güncelle
      setState(() {
        _selectedDietType = dietName;
      });

      // Seçilen öğünleri temizle (yeni diyete göre yeniden seçilsin)
      _selectedMeals.forEach((key, value) {
        _selectedMeals[key] = {
          'description': '',
          'calories': 0,
          'isEaten': false,
          'recipeId': null,
        };
      });

      // Sayfayı yenile
      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diyet "$dietName" olarak güncellendi! Artık bu diyete uygun öğünler gösterilecek.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diyet güncellenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDietsPage() {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: const AppDrawer(),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'Popüler Diyetler',
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
                        const Color(0xFF2E7D32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Plan Oluştur Banner
                  _buildPlanBanner(),
                  const SizedBox(height: 20),
                  
                  // Seçili Diyet Kartı
                  _buildCurrentDietCardModern(),
                  const SizedBox(height: 24),
                  
                  // Önerilen Diyetler Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.recommend_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Önerilen Diyetler',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Diyet Kartları
                  _buildModernDietCard(
                    name: 'Keto',
                    description: 'Düşük karbonhidrat, yüksek yağ içeren ketojenik diyet',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF7043),
                    duration: '4-8 hafta',
                    difficulty: 'Orta',
                    value: 'Keto',
                  ),
                  _buildModernDietCard(
                    name: 'Aralıklı Oruç',
                    description: 'Belirli zaman dilimlerinde yeme ve oruç tutma döngüsü',
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF42A5F5),
                    duration: 'Sürekli',
                    difficulty: 'Kolay',
                    value: 'Aralıklı Oruç',
                  ),
                  _buildModernDietCard(
                    name: 'Akdeniz',
                    description: 'Sağlıklı yağlar, taze meyve ve sebzeler içeren dengeli beslenme',
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFEF5350),
                    duration: 'Sürekli',
                    difficulty: 'Kolay',
                    value: 'Akdeniz',
                  ),
                  _buildModernDietCard(
                    name: 'Su Diyeti',
                    description: 'Belirli periyotlarda su tüketimi ile kilo verme',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF26C6DA),
                    duration: '1-3 gün',
                    difficulty: 'Zor',
                    value: 'Su Diyeti',
                  ),
                  _buildModernDietCard(
                    name: 'Önerilen Diyet',
                    description: 'Size özel hazırlanmış dengeli ve sağlıklı beslenme programı',
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFF66BB6A),
                    duration: 'Sürekli',
                    difficulty: 'Kolay',
                    value: 'Önerilen Diyet',
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('Error in _buildDietsPage: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Popüler Diyetler'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Bir hata oluştu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lütfen uygulamayı yeniden başlatın',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Güvenli mevcut diyet kartı
  Widget _buildCurrentDietCardSafe() {
    try {
      return _buildCurrentDietCard();
    } catch (e) {
      print('Error building current diet card: $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Şu Anki Diyetiniz',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedDietType ?? 'Seçilmedi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDietCategory(String title, List<Map<String, dynamic>> diets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...diets.map((diet) => _buildDietCard(
          diet['name'] as String,
          diet['description'] as String,
          diet['icon'] as IconData,
          diet['color'] as Color,
          diet['duration'] as String,
          diet['difficulty'] as String,
          diet['value'] as String? ?? diet['name'] as String,
        )).toList(),
      ],
    );
  }

  Widget _buildDietCard(
    String name,
    String description,
    IconData icon,
    Color color,
    String duration,
    String difficulty,
    String dietValue,
  ) {
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
      child: InkWell(
        onTap: () {
          _showDietInfoDialog(context, name);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(Icons.schedule, duration, Colors.grey[600]!),
                        const SizedBox(width: 8),
                        _buildInfoChip(Icons.stacked_bar_chart, difficulty, color),
                      ],
                    ),
                  ],
                ),
              ),
              // Seç butonu veya seçili rozeti
              Flexible(
                child: _selectedDietType == dietValue
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Seçili',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          _changeDiet(dietValue);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Seç',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Plan Banner
  Widget _buildPlanBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/plan'),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haftalık Plan Oluştur',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size özel haftalık diyet planınızı oluşturun',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Current Diet Card
  Widget _buildCurrentDietCardModern() {
    final dietInfo = _getDietInfo(_selectedDietType ?? '');
    final color = dietInfo['color'] as Color? ?? Colors.grey;
    final icon = dietInfo['icon'] as IconData? ?? Icons.restaurant_menu_rounded;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Şu Anki Diyetiniz',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDietType ?? 'Seçilmedi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Diet Card
  Widget _buildModernDietCard({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required String duration,
    required String difficulty,
    required String value,
  }) {
    final isSelected = _selectedDietType == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isSelected ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDietInfoDialog(context, name),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildModernChip(Icons.schedule_rounded, duration),
                          const SizedBox(width: 8),
                          _buildModernChip(
                            Icons.speed_rounded, 
                            difficulty,
                            color: difficulty == 'Kolay' 
                              ? Colors.green 
                              : difficulty == 'Orta' 
                                ? Colors.orange 
                                : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isSelected
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Seçili',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextButton(
                      onPressed: () => _changeDiet(value),
                      style: TextButton.styleFrom(
                        backgroundColor: color.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(48, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Seç',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernChip(IconData icon, String text, {Color? color}) {
    final chipColor = color ?? Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      key: _profileScaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          )
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                 // Ayarlar sayfasına git
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Header with Curve
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF2E7D32), // Daha koyu yeşil
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          // Main Content Layer
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 130),
            child: Column(
              children: [
                // Profile Card (Floating)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Image (Overlapping top)
                      Transform.translate(
                        offset: const Offset(0, -50),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: _isUploadingImage
                                    ? const CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.white,
                                        child: CircularProgressIndicator(),
                                      )
                                    : CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.grey[100],
                                        backgroundImage: user?.photoURL != null
                                            ? NetworkImage(user!.photoURL!)
                                            : null,
                                        child: user?.photoURL == null
                                            ? Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey[300],
                                              )
                                            : null,
                                      ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // User Info (shifted up because of image transform)
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Column(
                          children: [
                            Text(
                              user?.displayName ?? 'Kullanıcı',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Başlık
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.insights_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Kişisel Hedefler',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // İstatistik Kartları Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernProfileStatCard(
                              context,
                              'Günlük Kalori',
                              _dailyCalorieNeed != null ? '${_dailyCalorieNeed}' : '-',
                              'kcal',
                              Icons.local_fire_department_rounded,
                              const Color(0xFFFF7043), // Turuncu
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernProfileStatCard(
                              context,
                              'Günlük Su',
                              _waterNeeded != null ? '${_waterNeeded}' : '-',
                              'ml',
                              Icons.water_drop_rounded,
                              const Color(0xFF42A5F5), // Mavi
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildModernProfileStatCard(
                        context,
                        'Mevcut Hedef',
                        _goal ?? 'Belirlenmedi',
                        '',
                        Icons.track_changes_rounded,
                        const Color(0xFFAB47BC), // Mor
                        isFullWidth: true
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Settings & Actions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                       BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10)
                       )
                    ]
                  ),
                  child: Column(
                    children: [
                      _buildProfileMenuTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profil Detayları',
                        subtitle: 'Kişisel bilgilerinizi düzenleyin',
                        color: Colors.blueGrey,
                        onTap: () {
                           Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileDetailsScreen(),
                              ),
                            );
                        },
                      ),
                      _buildProfileMenuTile(
                        icon: Icons.settings_outlined,
                        title: 'Ayarlar',
                        subtitle: 'Uygulama tercihlerini değiştirin',
                        color: Colors.blueGrey,
                        onTap: () {},
                      ),
                       _buildProfileMenuTile(
                        icon: Icons.logout_rounded,
                        title: 'Çıkış Yap',
                        subtitle: 'Hesabınızdan güvenle çıkış yapın',
                        color: const Color(0xFFEF5350), // Yumuşak kırmızı
                        onTap: () async {
                           await authService.signOut();
                        },
                         isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Bottom navigation için boşluk
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileStatCard(BuildContext context, String title, String value, String unit, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.05), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    fontFamily: 'Poppins', 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: isLast 
              ? const BorderRadius.vertical(bottom: Radius.circular(24))
              : const BorderRadius.vertical(top: Radius.circular(24)), // Sadece örnek, aslında tam yuvarlak değil
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey[100], height: 1),
          ),
      ],
    );
  }

  Widget _buildWaterTracker(BuildContext context) {
    return StreamBuilder<int>(
      stream: _waterService.todayTotalMlStream(),
      builder: (context, snapshot) {
        final waterMl = snapshot.data ?? 0;
        final waterLiters = (waterMl / 1000);
        final targetLiters = _waterNeeded != null ? (_waterNeeded! / 1000) : 2.0;
        final progress = targetLiters > 0 ? (waterLiters / targetLiters).clamp(0.0, 1.0) : 0.0;

        return InkWell(
          onTap: () => _showWaterDialog(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.water_drop, color: Colors.blue, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  'Su',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: waterLiters.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${targetLiters.toStringAsFixed(1)} L',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatItem(BuildContext context, String title, String value, String unit, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isFullWidth ? Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ) : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _showShoppingListFromDrawer() async {
    try {
      // Haftalık planı çek
      final weeklyPlan = await _planService.getSavedWeeklyPlan();
      
      if (weeklyPlan == null || weeklyPlan.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Henüz bir haftalık plan bulunmuyor. Lütfen önce plan oluşturun.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Alışveriş listesini oluştur
      final shoppingList = _planService.generateShoppingList(weeklyPlan);
      final formattedList = _planService.formatShoppingList(shoppingList);

      if (!mounted) return;

      // Dialog göster
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Haftalık Alışveriş Listesi'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: shoppingList.isEmpty
                ? const Text('Alışveriş listesi boş.')
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Bu hafta ihtiyacınız olan malzemeler:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...shoppingList.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Toplam ${shoppingList.length} farklı malzeme',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alışveriş listesi hazır: $formattedList'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Tamam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alışveriş listesi oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMealItem(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    // Get the selected meal data for this meal type
    final mealData = _selectedMeals[title];
    final mealDescription = mealData?['description'] ?? '';
    final mealCalories = mealData?['calories'] ?? 0; // Default to 0 if no calories found
    final recipeId = mealData?['recipeId'];

    return InkWell(
      onTap: () {
        if (mealDescription.isNotEmpty) {
          if (recipeId != null && recipeId.toString().isNotEmpty) {
            // Tarif varsa tarif ekranını göster
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeScreen(
                  recipeId: recipeId.toString(),
                  mealName: mealDescription,
                  calories: mealCalories,
                ),
              ),
            );
          } else {
            // Tarif yoksa öğün detaylarını göster
            _showMealDetailsDialog(mealDescription, mealCalories);
          }
        } else if (onTap != null) {
          // Öğün seçilmemişse normal seçim işlemini yap
          onTap();
        }
      },
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
                    // Malzemeleri parse et ve göster
                    Builder(
                      builder: (context) {
                        List<Map<String, dynamic>> components = [];
                        if (mealData?['components'] != null && (mealData!['components'] as List).isNotEmpty) {
                          components = List<Map<String, dynamic>>.from(mealData['components'] as List);
                        } else {
                          components = _parseMealComponents(mealDescription);
                          if (mealData != null) {
                            mealData['components'] = components;
                          }
                        }
                        
                        if (components.isNotEmpty) {
                          // İlk 3 malzemeyi göster, kalanlar için "..."
                          final displayComponents = components.take(3).toList();
                          final remainingCount = components.length - displayComponents.length;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...displayComponents.map((component) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        component['name'] as String,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[700],
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                                      ' ${component['calories']} kcal',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              if (remainingCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    've $remainingCount malzeme daha...',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        } else {
                          // Malzeme parse edilemediyse description'ı göster
                          return Text(
                      mealDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                            maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                          );
                        }
                      },
                    ),
                    if (recipeId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tarif mevcut',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
            Icon(
              mealDescription.isNotEmpty && recipeId != null 
                ? Icons.restaurant_menu 
                : Icons.add,
              color: mealDescription.isNotEmpty && recipeId != null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            ),
          ],
        ),
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

  Widget _buildDietTypesCard(BuildContext context) {
    final dietTypes = [
      {'name': 'Keto', 'icon': Icons.local_fire_department, 'color': Colors.orange},
      {'name': 'Vegan', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Aralıklı Oruç', 'icon': Icons.timer, 'color': Colors.blue},
      {'name': 'Akdeniz', 'icon': Icons.restaurant, 'color': Colors.red},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popüler Diyetler',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hemen keşfet!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: dietTypes.map((diet) => Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showDietInfoDialog(context, diet['name'] as String);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (diet['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (diet['color'] as Color).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (diet['color'] as Color).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            diet['icon'] as IconData,
                            color: diet['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          diet['name'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: diet['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaterDialog(BuildContext context) {
    final TextEditingController customController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Su Ekle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Kendin Gir alanı
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40), // Yanlardan daha da daraltıldı
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0), // İç boşluk biraz azaltıldı
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_outlined, 
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor: Colors.blue,
                              selectionColor: Colors.blue.withOpacity(0.3),
                              selectionHandleColor: Colors.blue,
                            ),
                          ),
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            textAlignVertical: TextAlignVertical.center,
                            cursorColor: Colors.blue, // İmleç rengi mavi
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Miktar gir',
                              suffixText: 'ml',
                              suffixStyle: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none, // Odaklanınca border yok
                              enabledBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (value) {
                              final customMl = int.tryParse(value);
                              if (customMl != null && customMl > 0) {
                                _waterService.addWater(customMl);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$customMl ml su eklendi!'),
                                    backgroundColor: Colors.blue,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            final customMl = int.tryParse(customController.text);
                            if (customMl != null && customMl > 0) {
                              _waterService.addWater(customMl);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$customMl ml su eklendi!'),
                                  backgroundColor: Colors.blue,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: const Text(
                              'Ekle',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildWaterButton(250, context),
                  const SizedBox(width: 12),
                  _buildWaterButton(500, context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildWaterButton(750, context),
                  const SizedBox(width: 12),
                  _buildWaterButton(1000, context),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterButton(int ml, BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          try {
            await _waterService.addWater(ml);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${ml}ml su eklendi! 💧'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.water_drop,
                color: Colors.blue,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                '$ml ml',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDietInfoDialog(BuildContext context, String dietName) {
    final dietInfo = _getDietInfo(dietName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dietInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                dietInfo['icon'],
                color: dietInfo['color'],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              dietName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dietInfo['description'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Nasıl Yapılır:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...dietInfo['howTo'].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: dietInfo['color'],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDietInfo(String dietName) {
    switch (dietName) {
      case 'Keto':
        return {
          'icon': Icons.local_fire_department,
          'color': Colors.orange,
          'description': 'Keto diyeti, düşük karbonhidrat ve yüksek yağ içeren bir beslenme tarzıdır. Vücudun ketozise girmesini sağlar.',
          'howTo': [
            'Karbonhidrat alımını günde 20-50g ile sınırlandırın',
            'Sağlıklı yağları artırın (avokado, zeytinyağı, fındık)',
            'Protein alımını orta seviyede tutun',
            'Bol su için ve elektrolit takviyesi yapın',
          ],
        };
      case 'Vegan':
        return {
          'icon': Icons.eco,
          'color': Colors.green,
          'description': 'Vegan diyet, tüm hayvansal ürünlerden kaçınan etik ve sağlıklı bir yaşam tarzıdır.',
          'howTo': [
            'Tüm hayvansal ürünleri diyetinizden çıkarın',
            'Bitkisel protein kaynaklarını tercih edin (baklagiller, tofu, kinoa)',
            'B12 vitaminini takviye olarak alın',
            'Demir ve kalsiyum alımına dikkat edin',
          ],
        };
      case 'Aralıklı Oruç':
        return {
          'icon': Icons.timer,
          'color': Colors.blue,
          'description': 'Aralıklı oruç, belirli zaman dilimlerinde yeme ve oruç tutma döngüsü içeren bir beslenme metodudur.',
          'howTo': [
            '16:8 yöntemi: 16 saat oruç, 8 saat yeme penceresi',
            'Oruç penceresinde sadece su, çay ve kahve içebilirsiniz',
            'Yeme penceresinde dengeli ve besleyici öğünler yiyin',
            'Düzenli egzersiz ve uyku önemlidir',
          ],
        };
      case 'Akdeniz':
        return {
          'icon': Icons.restaurant,
          'color': Colors.red,
          'description': 'Akdeniz diyeti, sağlıklı yağlar, taze meyve ve sebzeler, balık ve tam tahıl içeren dengeli bir beslenme modelidir.',
          'howTo': [
            'Her gün bol meyve ve sebze tüketin',
            'Zeytinyağı başta olmak üzere sağlıklı yağları tercih edin',
            'Haftada 2-3 kez balık yiyin',
            'Tam tahıllı ürünleri ve kuruyemişleri diyetinize dahil edin',
          ],
        };
      case 'Su Diyeti':
        return {
          'icon': Icons.water_drop,
          'color': Colors.cyan,
          'description': 'Su diyeti, vücudun detoks yapmasını sağlayan, sadece su ve belirli sıvılar tüketilen kısa süreli bir diyet programıdır.',
          'howTo': [
            'Günde 2-3 litre su içmeye odaklanın',
            'Kahve, çay gibi kafeinli içecekleri sınırlandırın',
            'Meyve ve sebze suyu tüketebilirsiniz',
            'Maksimum 3 gün uygulayın ve doktor kontrolünde yapın',
          ],
        };
      case 'Vejetaryen':
        return {
          'icon': Icons.eco,
          'color': Colors.green,
          'description': 'Vejetaryen diyet, et ürünlerini tüketmeyen ancak süt ürünleri ve yumurta tüketen bir beslenme tarzıdır.',
          'howTo': [
            'Tüm et ürünlerini diyetinizden çıkarın',
            'Baklagiller, tofu ve süt ürünlerinden protein alın',
            'Yumurta ve süt ürünlerini dengeli tüketin',
            'Demir ve B12 vitaminini takip edin',
          ],
        };
      case 'Glutensiz':
        return {
          'icon': Icons.grain,
          'color': Colors.brown,
          'description': 'Glutensiz diyet, çölyak hastaları veya gluten hassasiyeti olan kişiler için önemli bir beslenme şeklidir.',
          'howTo': [
            'Buğday, arpa ve çavdar içeren tüm ürünleri kaçının',
            'Pirinç, mısır, patates gibi güvenli tahılları tercih edin',
            'Etiket okuma alışkanlığı kazanın',
            'Evde glutensiz yemekler pişirin',
          ],
        };
      default:
        return {
          'icon': Icons.info,
          'color': Colors.grey,
          'description': 'Bu diyet hakkında bilgi bulunmuyor.',
          'howTo': [],
        };
    }
  }

  Future<void> _showSelectedMealsDialog(BuildContext context) async {
    // Önce recipe'leri yükle (eğer varsa)
    await _loadRecipeIngredientsForSelectedMeals();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
        
        return AlertDialog(
          title: const Text('Seçilen Öğünler'),
          contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          content: SizedBox(
            width: dialogWidth,
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
                      // isEaten true olsa bile göster (kullanıcı yediğini görmek isteyebilir)
                      if (mealDescription.isEmpty) {
                        return const SizedBox.shrink(); // Hide if no meal is selected for this type
                      }

                      // Malzemeleri parse et veya cache'den al
                      List<Map<String, dynamic>> mealComponents;
                      if (mealData?['components'] != null && (mealData!['components'] as List).isNotEmpty) {
                        // Eğer components zaten varsa onu kullan
                        mealComponents = List<Map<String, dynamic>>.from(mealData['components'] as List);
                      } else {
                        // Yoksa description'dan parse et, mealCalories'i de geç
                        final calories = (mealData?['calories'] is int)
                            ? mealData!['calories'] as int
                            : int.tryParse('${mealData?['calories']}') ?? 0;
                        mealComponents = _parseMealComponents(mealDescription, totalMealCalories: calories > 0 ? calories : null);
                        // İlk kez parse ediliyorsa components'ı kaydet
                        if (mealData != null) {
                          mealData['components'] = mealComponents;
                        }
                      }
                      
                      // Eğer hala boşsa, mealCalories'i kullan
                      if (mealComponents.isEmpty && mealCalories > 0) {
                        mealComponents = [{
                          'name': mealDescription.isNotEmpty ? mealDescription : mealType,
                          'calories': mealCalories,
                          'isSelected': true,
                        }];
                        if (mealData != null) {
                          mealData['components'] = mealComponents;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: StatefulBuilder(
                          builder: (context, setStateLocal) {
                            // Seçilen bileşenlerin kalori toplamını hesapla
                            int totalCalories = mealComponents
                                .where((component) => component['isSelected'] == true)
                                .fold(0, (sum, component) => sum + (component['calories'] as int));

                            return ExpansionTile(
                              leading: (mealData?['recipeId'] != null && mealData?['recipeId'].toString().isNotEmpty == true)
                                  ? IconButton(
                                      icon: Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                                      onPressed: () {
                                        final recipeId = mealData?['recipeId'];
                                        if (recipeId != null && recipeId.toString().isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RecipeScreen(
                                                recipeId: recipeId.toString(),
                                                mealName: mealDescription,
                                                calories: mealCalories,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      tooltip: 'Tarifi Görüntüle',
                                    )
                                  : null,
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mealType,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '$totalCalories kcal',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              children: [
                                if (mealDescription.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Öğün: $mealDescription',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        if (mealCalories != totalCalories)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Orijinal kalori: $mealCalories kcal',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        const Divider(height: 24),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Malzemeler:',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (mealComponents.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'Bu öğün için malzeme bilgisi bulunmamaktadır.',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      else
                                        ...mealComponents.map((component) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: CheckboxListTile(
                                            value: component['isSelected'] as bool,
                                            onChanged: (bool? value) {
                                            setStateLocal(() {
                                              component['isSelected'] = value ?? false;
                                              // State'i güncelle
                                              if (mealData != null) {
                                                mealData['components'] = mealComponents;
                                              }
                                            });
                                            // Ana state'i de güncelle (dialog açıkken de güncellensin)
                                            if (mounted) {
                                              setState(() {
                                                _updateConsumedCalories();
                                              });
                                            }
                                            },
                                            title: Text(
                                              component['name'] as String,
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            subtitle: Text(
                                              '${component['calories']} kcal',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            activeColor: Theme.of(context).colorScheme.primary,
                                            contentPadding: EdgeInsets.zero,
                                            controlAffinity: ListTileControlAffinity.leading,
                                          ),
                                        )),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Toplam Kalori:',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '$totalCalories kcal',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              trailing: !isEaten
                                  ? ElevatedButton.icon(
                                      onPressed: () async {
                                        // Seçilen bileşenlerin kalori toplamını hesapla
                                        int actualCalories = mealComponents
                                            .where((component) => component['isSelected'] == true)
                                            .fold(0, (sum, component) => sum + (component['calories'] as int));
                                        
                                        // Öğünü kaydet
                                        await _saveMealAsEaten(mealType, mealDescription, actualCalories, mealData?['recipeId']);
                                        
                                        // Components'ı kaydet
                                        if (mealData != null) {
                                          mealData['components'] = mealComponents;
                                        }
                                        
                                        // Tüketilen kaloriyi güncelle
                                        _updateConsumedCalories();
                                        
                                        // Dialog'u yenile
                             Navigator.of(context).pop();
                             _showSelectedMealsDialog(context);
                                      },
                                      icon: const Icon(Icons.restaurant_menu, size: 16),
                                      label: const Text('Yedim'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(80, 32),
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.green),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Yedim',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            );
                          },
                        ),
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
                   Builder(
                     builder: (context) {
                       // Calculate total consumed calories from selected components of eaten meals
                       int totalConsumed = 0;
                       for (var mealData in _selectedMeals.values) {
                         if (mealData['isEaten'] == true) {
                           // Eğer components varsa, seçilen bileşenlerin kalorilerini topla
                           if (mealData['components'] != null && (mealData['components'] as List).isNotEmpty) {
                             final components = List<Map<String, dynamic>>.from(mealData['components'] as List);
                             final selectedComponentsCalories = components
                                 .where((component) => component['isSelected'] == true)
                                 .fold(0, (sum, component) => sum + (component['calories'] as int));
                             totalConsumed += selectedComponentsCalories;
                           } else {
                             // Components yoksa, öğünün toplam kalorisini kullan
                             totalConsumed += (mealData['calories'] ?? 0) as int;
                           }
                         }
                       }
                       return Text(
                         '$totalConsumed kcal', // Display total consumed calories
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                       color: Theme.of(context).colorScheme.primary,
                ),
                       );
                     },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Kapat'),
          ),
        ],
      );
      },
    ).then((_) {
      // Dialog kapandıktan sonra kaloriyi güncelle
      _updateConsumedCalories();
    });
  }
}