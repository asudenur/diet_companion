import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class KaloriChatbotService {
  // API base URL - platform'a göre otomatik seçilir
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }
    
    if (Platform.isAndroid) {
      // Android emülatör için özel IP
      // Gerçek cihaz için bilgisayarınızın IP adresini kullanın
      // IP adresinizi öğrenmek için: ipconfig (Windows) veya ifconfig (Mac/Linux)
      return 'http://10.0.2.2:5000'; // Android emülatör için
      // Gerçek Android cihaz için: 'http://172.20.10.6:5000' gibi bilgisayarınızın IP'sini kullanın
    } else if (Platform.isIOS) {
      return 'http://localhost:5000'; // iOS simülatör için
      // Gerçek iOS cihaz için: 'http://172.20.10.6:5000' gibi bilgisayarınızın IP'sini kullanın
    }
    
    return 'http://localhost:5000'; // Varsayılan
  }

  /// API sağlık kontrolü
  Future<bool> checkHealth() async {
    try {
      print('🔍 API bağlantısı deneniyor: $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API bağlantısı başarılı!');
        return data['model_loaded'] == true;
      }
      print('❌ API yanıt kodu: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Health check error: $e');
      print('   Denenen URL: $baseUrl');
      print('   Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Other"}');
      return false;
    }
  }

  /// Kullanıcı girdisinden kalori tahmini yapar
  Future<KaloriPredictionResponse> predictCalories(String userInput) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'input': userInput}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KaloriPredictionResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        return KaloriPredictionResponse(
          success: false,
          message: errorData['error'] ?? 'Bir hata oluştu',
          details: [],
          totalCalories: 0,
        );
      }
    } catch (e) {
      return KaloriPredictionResponse(
        success: false,
        message: 'API\'ye bağlanılamadı. Lütfen API\'nin çalıştığından emin olun.',
        details: [],
        totalCalories: 0,
      );
    }
  }

  /// Mevcut besin listesini getirir
  Future<List<FoodItem>> getFoods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/foods'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final foods = data['foods'] as List;
          return foods.map((f) => FoodItem.fromJson(f)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Get foods error: $e');
      return [];
    }
  }
}

class KaloriPredictionResponse {
  final bool success;
  final String? input;
  final String message;
  final List<FoodDetail> details;
  final double totalCalories;

  KaloriPredictionResponse({
    required this.success,
    this.input,
    required this.message,
    required this.details,
    required this.totalCalories,
  });

  factory KaloriPredictionResponse.fromJson(Map<String, dynamic> json) {
    return KaloriPredictionResponse(
      success: json['success'] ?? false,
      input: json['input'],
      message: json['message'] ?? '',
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => FoodDetail.fromJson(d))
              .toList() ??
          [],
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
    );
  }
}

class FoodDetail {
  final String food;
  final int amount;
  final String method;
  final double calories;

  FoodDetail({
    required this.food,
    required this.amount,
    required this.method,
    required this.calories,
  });

  factory FoodDetail.fromJson(Map<String, dynamic> json) {
    return FoodDetail(
      food: json['food'] ?? '',
      amount: json['amount'] ?? 0,
      method: json['method'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
    );
  }
}

class FoodItem {
  final String name;
  final int unitGr;

  FoodItem({
    required this.name,
    required this.unitGr,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      unitGr: json['unit_gr'] ?? 0,
    );
  }
}

