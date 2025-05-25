import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoModel {
  final String uid;
  final double height; // boy (cm)
  final double weight; // kilo (kg)
  final String gender; // cinsiyet
  final int age; // yaş
  final String activityLevel; // hareket durumu
  final double calculatedCalories; // hesaplanan kalori

  UserInfoModel({
    required this.uid,
    required this.height,
    required this.weight,
    required this.gender,
    required this.age,
    required this.activityLevel,
    required this.calculatedCalories,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'height': height,
      'weight': weight,
      'gender': gender,
      'age': age,
      'activityLevel': activityLevel,
      'calculatedCalories': calculatedCalories,
    };
  }

  factory UserInfoModel.fromMap(Map<String, dynamic> map) {
    return UserInfoModel(
      uid: map['uid'],
      height: map['height'],
      weight: map['weight'],
      gender: map['gender'],
      age: map['age'],
      activityLevel: map['activityLevel'],
      calculatedCalories: map['calculatedCalories'],
    );
  }
} 