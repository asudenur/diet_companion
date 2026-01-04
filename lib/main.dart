import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'screens/calorie_calculator_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/food_database_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'services/notification_service.dart';
import 'scripts/diet_recipes_seeder.dart';
import 'scripts/meal_plan_templates_seeder.dart';
import 'screens/diet_preferences_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/plan_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/chatbot_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase yapılandırmasını yükle
  final String jsonString = await rootBundle.loadString('assets/firebase_config.json');
  final Map<String, dynamic> config = json.decode(jsonString);
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: config['apiKey'],
      appId: config['appId'],
      messagingSenderId: config['messagingSenderId'],
      projectId: config['projectId'],
      storageBucket: config['storageBucket'],
    ),
  );
  //await seedMealPlanTemplates();
  // Bildirim servisini başlat
  await NotificationService().init();
  
  // Diyet tariflerini ekle (sadece ilk çalıştırmada)
  //await seedDietRecipes(); // Bu satırı açarak tarifleri ekleyebilirsiniz
 
  await initializeDateFormatting('tr', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Diet Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
            primary: const Color(0xFF4CAF50),
            secondary: const Color(0xFF81C784),
            tertiary: const Color(0xFF009688),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            toolbarHeight: 60,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Colors.white,
            margin: const EdgeInsets.all(4),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIconColor: const Color(0xFF4CAF50),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 2,
              shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
                letterSpacing: -0.5,
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                letterSpacing: 0.15,
              ),
              labelLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
        home: const LoginScreen(),
        routes: {
          '/calorie_calculator': (context) => const CalorieCalculatorScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/foods': (context) => const FoodDatabaseScreen(),
          '/history': (context) => const HistoryScreen(),
          '/favorites': (context) => FavoritesScreen(),
          '/notification_settings': (context) => const NotificationSettingsScreen(),
          '/diet_preferences': (context) => const DietPreferencesScreen(),
          '/plan': (context) => const PlanScreen(),
          '/chatbot': (context) => const ChatbotScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            final args = settings.arguments as Map<String, dynamic>?;
            final tabIndex = args?['tabIndex'] ?? 0;
            return MaterialPageRoute(
              builder: (context) => HomeScreen(initialTabIndex: tabIndex),
            );
          }
          return null;
        },
      ),
    );
  }
}
