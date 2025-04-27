import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register with email and password
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password, String firstName, String lastName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': userCredential,
        'message': 'Kayıt başarılı!'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Kayıt başarısız!';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Şifre çok zayıf - en az 6 karakter olmalı';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'operation-not-allowed':
          message = 'E-posta/şifre girişi etkin değil';
          break;
        default:
          message = 'Bir hata oluştu: ${e.message}';
      }
      
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': message
      };
    } catch (e) {
      print('Unexpected Error: $e');
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata oluştu'
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return {
        'success': true,
        'user': userCredential,
        'message': 'Giriş başarılı!'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Giriş başarısız!';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Bu e-posta adresine ait hesap bulunamadı';
          break;
        case 'wrong-password':
          message = 'Yanlış şifre';
          break;
        case 'invalid-email':
          message = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          message = 'Bu hesap devre dışı bırakılmış';
          break;
        default:
          message = 'Bir hata oluştu: ${e.message}';
      }
      
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': message
      };
    } catch (e) {
      print('Unexpected Error: $e');
      return {
        'success': false,
        'message': 'Beklenmeyen bir hata oluştu'
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
} 