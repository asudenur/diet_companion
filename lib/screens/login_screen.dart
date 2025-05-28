import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              // Light green gradient based on the image
              Colors.lightGreen.shade100,
              Colors.lightGreen.shade50,
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0], // Adjust stops for gradient distribution
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.green.shade600, // Adjust color to match image
                  ),
                  const SizedBox(height: 24),
                  // Uygulama Adı
                  Text(
                    'Diyet Yoldaşı',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.green.shade600, // Adjust color to match image
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Alt Başlık
                  Text(
                    'Sağlıklı yaşam için yanınızdayız',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.green.shade400, // Adjust color to match image
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Email Alanı
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'E-posta adresinizi girin',
                      prefixIcon: const Icon(Icons.email_outlined),
                      // Apply design from image
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade200,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade200,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Şifre Alanı
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: 'Şifrenizi girin',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                       // Apply design from image
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade200,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade200,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.green.shade400,
                          width: 1.5,
                        ),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Giriş Yap Butonu
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600, // Green background
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0), // Rounded corners
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.arrow_forward, color: Colors.white), // Right arrow icon
                    label: Text(
                      _isLoading ? 'Giriş yapılıyor...' : 'Giriş Yap',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kayıt Ol Linki
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.person_add_alt_1_outlined, color: Colors.green.shade600), // Person icon and green color
                    label: Text(
                      'Hesabınız yok mu? Kayıt olun',
                      style: TextStyle(color: Colors.green.shade600), // Green color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 