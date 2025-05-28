import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'registration_steps/step1_basic_info.dart';
import 'registration_steps/step2_physical_info.dart';
import 'registration_steps/step3_activity_level.dart';
import 'registration_steps/step4_goals.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _basicInfoFormKey = GlobalKey<FormState>();
  final _physicalInfoFormKey = GlobalKey<FormState>();
  final _activityFormKey = GlobalKey<FormState>();
  final _goalsFormKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender;
  String? _activityLevel;
  String? _goal;
  int _currentStep = 1;
  bool _isLoading = false;

  // Function to calculate Basal Metabolic Rate (BMR)
  double _calculateBMR() {
    final weight = double.parse(_weightController.text);
    final height = double.parse(_heightController.text);
    final age = int.parse(_ageController.text);
    final gender = _gender!;

    if (gender == 'Erkek') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else { // Kadın
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  // Function to calculate daily calorie need based on BMR and activity level
  int _calculateDailyCalorieNeed() {
    final bmr = _calculateBMR();
    double activityFactor;
    switch (_activityLevel) {
      case 'Çok az hareketli':
        activityFactor = 1.2;
        break;
      case 'Hafif aktif':
        activityFactor = 1.375;
        break;
      case 'Orta aktif':
        activityFactor = 1.55;
        break;
      case 'Çok aktif':
        activityFactor = 1.725;
        break;
      default:
        activityFactor = 1.2; // Default to sedentary if activity level is not set
    }
    return (bmr * activityFactor).round();
  }

  // Function to calculate daily water needed based on weight
  int _calculateWaterNeeded() {
    final weight = double.parse(_weightController.text);
    return (weight * 30).round(); // 30 ml per kg of body weight
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.registerWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      {
        'height': double.parse(_heightController.text),
        'weight': double.parse(_weightController.text),
        'age': int.parse(_ageController.text),
        'gender': _gender!,
        'activityLevel': _activityLevel!,
        'goal': _goal!,
        'dailyCalorieNeed': _calculateDailyCalorieNeed(),
        'waterNeeded': _calculateWaterNeeded(),
      },
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return BasicInfoStep(
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          onNext: () => setState(() => _currentStep = 2),
          formKey: _basicInfoFormKey,
        );
      case 2:
        return PhysicalInfoStep(
          heightController: _heightController,
          weightController: _weightController,
          ageController: _ageController,
          selectedGender: _gender,
          onGenderChanged: (gender) => setState(() => _gender = gender),
          onNext: () => setState(() => _currentStep = 3),
          onBack: () => setState(() => _currentStep = 1),
          formKey: _physicalInfoFormKey,
        );
      case 3:
        return ActivityLevelStep(
          selectedActivityLevel: _activityLevel,
          onActivityLevelChanged: (level) => setState(() {
            _activityLevel = level;
            print('Activity Level Selected: $_activityLevel');
          }),
          onNext: () => setState(() => _currentStep = 4),
          onBack: () => setState(() => _currentStep = 2),
          formKey: _activityFormKey,
        );
      case 4:
        return GoalsStep(
          selectedGoal: _goal,
          onGoalChanged: (goal) => setState(() => _goal = goal),
          onNext: _register,
          onBack: () => setState(() => _currentStep = 3),
          formKey: _goalsFormKey,
          footer: TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            child: Text(
              'Hesabınız var mı? Giriş yapın',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _buildCurrentStep(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 