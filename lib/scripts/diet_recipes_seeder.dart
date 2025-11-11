import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

// Bu script Firebase'e diyet yemekleri ve tariflerini eklemek için kullanılır
// main.dart'ta çalıştırılabilir

class DietRecipesSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Diyet yemekleri ve tariflerini Firebase'e ekle
  Future<void> seedDietRecipes() async {
    try {
      print('Diyet yemekleri ve tarifleri ekleniyor...');

      // Kahvaltı tarifleri
      await _addBreakfastRecipes();
      
      // Öğle yemeği tarifleri
      await _addLunchRecipes();
      
      // Akşam yemeği tarifleri
      await _addDinnerRecipes();
      
      // Ara öğün tarifleri
      await _addSnackRecipes();

      print('Tüm diyet yemekleri ve tarifleri başarıyla eklendi!');
    } catch (e) {
      print('Hata: $e');
    }
  }

  Future<void> _addBreakfastRecipes() async {
    final breakfastRecipes = [
      {
        'name': 'Yulaf Ezmesi',
        'description': 'Süt ile hazırlanmış sağlıklı yulaf ezmesi, muz ve bal ile',
        'ingredients': [
          '3/4 bardak yulaf ezmesi',
          '1 bardak süt',
          '1/2 küçük muz',
          '1 tatlı kaşığı bal',
          'İsteğe bağlı: tarçın, chia tohumu'
        ],
        'instructions': [
          'Yulaf ezmesini süt ile bir tencerede karıştırın',
          'Orta ateşte kıvam alana kadar pişirin (yaklaşık 5 dakika)',
          'Kaseye alın, üzerine dilimlenmiş muz ve bal ekleyin',
          'İsteğe bağlı olarak tarçın veya chia tohumu serpin'
        ],
        'prepTime': 5,
        'cookTime': 5,
        'servings': 1,
        'calories': 250,
        'protein': 10.0,
        'carbs': 40.0,
        'fat': 7.0,
        'tags': ['vegan-friendly', 'glutensiz', 'kahvaltı'],
        'difficulty': 'Kolay',
        'category': 'Kahvaltı',
        'imageUrl': ''
      },
      {
        'name': 'Avokado Tost',
        'description': 'Tam buğday ekmeği üzerinde avokado ezmesi ve domates',
        'ingredients': [
          '1 dilim tam buğday ekmeği',
          '1/3 avokado',
          'Bir tutam roka',
          'Birkaç dilim domates',
          'Tuz, karabiber'
        ],
        'instructions': [
          'Tam buğday ekmeğini tost makinesinde veya tavada hafifçe kızartın',
          'Avokadoyu ezin ve ekmeğin üzerine sürün',
          'Üzerine roka ve domates dilimlerini yerleştirin',
          'Tuz ve karabiber serpip servis yapın'
        ],
        'prepTime': 5,
        'cookTime': 2,
        'servings': 1,
        'calories': 200,
        'protein': 7.0,
        'carbs': 25.0,
        'fat': 10.0,
        'tags': ['vegan', 'vejetaryen', 'kahvaltı'],
        'difficulty': 'Kolay',
        'category': 'Kahvaltı',
        'imageUrl': ''
      },
      {
        'name': 'Tam Buğday Pankek',
        'description': 'Sağlıklı tam buğday unlu pankek, reçel ve taze meyve ile',
        'ingredients': [
          '1 adet tam buğday unlu pankek',
          '1 tatlı kaşığı reçel',
          'Birkaç dilim taze meyve',
          'İsteğe bağlı: 1 küçük bardak süt'
        ],
        'instructions': [
          'Pankeki ısıtın',
          'Üzerine reçel ve taze meyveleri ekleyin',
          'Yanında bir bardak süt ile servis yapın'
        ],
        'prepTime': 2,
        'cookTime': 3,
        'servings': 1,
        'calories': 280,
        'protein': 8.0,
        'carbs': 45.0,
        'fat': 9.0,
        'tags': ['vejetaryen', 'kahvaltı'],
        'difficulty': 'Kolay',
        'category': 'Kahvaltı',
        'imageUrl': ''
      },
      {
        'name': 'Haşlanmış Yumurta ve Peynir',
        'description': 'Haşlanmış yumurta, az tuzlu beyaz peynir, domates ve salatalık ile sağlıklı kahvaltı',
        'ingredients': [
          '1 adet haşlanmış yumurta',
          '2 dilim az tuzlu beyaz peynir',
          'Domates',
          'Salatalık',
          '1 dilim tam buğday ekmeği',
          '1 bardak şekersiz çay'
        ],
        'instructions': [
          'Yumurtayı haşlayın',
          'Peynir, domates ve salatalığı dilimleyin',
          'Tam buğday ekmeği ve çay ile servis yapın'
        ],
        'prepTime': 5,
        'cookTime': 10,
        'servings': 1,
        'calories': 270,
        'protein': 18.0,
        'carbs': 20.0,
        'fat': 12.0,
        'tags': ['protein', 'kahvaltı'],
        'difficulty': 'Kolay',
        'category': 'Kahvaltı',
        'imageUrl': ''
      },
      {
        'name': 'Zeytinli Kahvaltı',
        'description': 'Haşlanmış yumurta, zeytin, beyaz peynir, domates ve salatalık ile kahvaltı',
        'ingredients': [
          '1 adet haşlanmış yumurta',
          '5-6 adet zeytin',
          '1 dilim beyaz peynir',
          'Domates',
          'Salatalık',
          '1 dilim tam buğday ekmeği',
          '1 bardak şekersiz çay'
        ],
        'instructions': [
          'Yumurtayı haşlayın',
          'Zeytin, peynir, domates ve salatalığı hazırlayın',
          'Tam buğday ekmeği ve çay ile servis yapın'
        ],
        'prepTime': 5,
        'cookTime': 10,
        'servings': 1,
        'calories': 280,
        'protein': 15.0,
        'carbs': 22.0,
        'fat': 15.0,
        'tags': ['protein', 'kahvaltı'],
        'difficulty': 'Kolay',
        'category': 'Kahvaltı',
        'imageUrl': ''
      },
    ];

    for (var recipe in breakfastRecipes) {
      await _firestore.collection('recipes').add(recipe);
    }
    print('Kahvaltı tarifleri eklendi');
  }

  Future<void> _addLunchRecipes() async {
    final lunchRecipes = [
      {
        'name': 'Kinoa Salatası',
        'description': 'Protein ve lif açısından zengin, taze sebzelerle hazırlanmış kinoa salatası',
        'ingredients': [
          '1/2 bardak kinoa',
          '1 bardak su',
          '1/2 salatalık (küp doğranmış)',
          '1/2 kırmızı biber (küp doğranmış)',
          'Birkaç yaprak taze nane',
          'Birkaç yaprak taze maydanoz',
          '2 yemek kaşığı nar ekşisi veya limon suyu',
          '1 yemek kaşığı zeytinyağı',
          'Tuz, karabiber'
        ],
        'instructions': [
          'Kinoayı yıkayın ve 1 bardak su ile haşlayın (yaklaşık 15 dakika)',
          'Haşlanmış kinoayı soğumaya bırakın',
          'Tüm sebzeleri doğrayın ve kinoaya ekleyin',
          'Nar ekşisi (veya limon suyu), zeytinyağı, tuz ve karabiber ile karıştırıp servis yapın'
        ],
        'prepTime': 15,
        'cookTime': 15,
        'servings': 2,
        'calories': 300,
        'protein': 12.0,
        'carbs': 45.0,
        'fat': 10.0,
        'tags': ['vegan', 'glutensiz', 'öğle yemeği'],
        'difficulty': 'Orta',
        'category': 'Öğle Yemeği',
        'imageUrl': ''
      },
      {
        'name': 'Izgara Somon',
        'description': 'Sebzelerle servis edilen ızgara somon',
        'ingredients': [
          '200g somon fileto',
          '1 kabak',
          '1 patlıcan',
          '1 kırmızı biber',
          '2 yemek kaşığı zeytinyağı',
          'Tuz, karabiber',
          'Kekik',
          'Limon'
        ],
        'instructions': [
          'Somonu tuz, karabiber ve kekikle marine edin',
          'Sebzeleri dilimleyin',
          'Sebzeleri zeytinyağıyla karıştırın',
          'Izgarada somon ve sebzeleri pişirin',
          'Limon suyuyla servis edin'
        ],
        'prepTime': 15,
        'cookTime': 20,
        'servings': 1,
        'calories': 450,
        'protein': 35.0,
        'carbs': 15.0,
        'fat': 25.0,
        'tags': ['protein', 'omega-3', 'düşük karbonhidrat'],
        'difficulty': 'Orta',
        'category': 'Öğle Yemeği',
        'imageUrl': ''
      },
      {
        'name': 'Izgara Tavuk',
        'description': 'Baharatlı ızgara tavuk göğsü ve sebzeler',
        'ingredients': [
          '200g tavuk göğsü',
          '1 brokoli',
          '1 havuç',
          '2 yemek kaşığı zeytinyağı',
          'Tuz, karabiber',
          'Sarımsak',
          'Kekik',
          'Biberiye'
        ],
        'instructions': [
          'Tavuk göğsünü baharatlarla marine edin',
          'Sebzeleri hazırlayın',
          'Tavuk göğsünü ızgarada pişirin',
          'Sebzeleri buharda pişirin',
          'Sıcak servis edin'
        ],
        'prepTime': 20,
        'cookTime': 25,
        'servings': 1,
        'calories': 400,
        'protein': 40.0,
        'carbs': 20.0,
        'fat': 15.0,
        'tags': ['protein', 'düşük karbonhidrat'],
        'difficulty': 'Orta',
        'category': 'Öğle Yemeği',
        'imageUrl': ''
      },
    ];

    for (var recipe in lunchRecipes) {
      await _firestore.collection('recipes').add(recipe);
    }
    print('Öğle yemeği tarifleri eklendi');
  }

  Future<void> _addDinnerRecipes() async {
    final dinnerRecipes = [
      {
        'name': 'Fırında Köfte',
        'description': 'Fırında pişirilmiş, hafif ve lezzetli köfteler',
        'ingredients': [
          '200g az yağlı kıyma',
          '1 adet soğan (rendelenmiş)',
          '1 dilim bayat ekmek içi (sütle ıslatılmış)',
          '1 yumurta',
          'Maydanoz (doğranmış)',
          'Tuz, karabiber, kimyon, pul biber'
        ],
        'instructions': [
          'Tüm malzemeyi bir kapta iyice yoğurun',
          'Ceviz büyüklüğünde parçalar alıp yuvarlayın',
          'Yağlı kağıt serilmiş fırın tepsisine dizin',
          'Önceden ısıtılmış 180 derece fırında 20-25 dakika pişirin'
        ],
        'prepTime': 15,
        'cookTime': 25,
        'servings': 2,
        'calories': 280,
        'protein': 25.0,
        'carbs': 15.0,
        'fat': 12.0,
        'tags': ['protein', 'akşam yemeği'],
        'difficulty': 'Orta',
        'category': 'Akşam Yemeği',
        'imageUrl': ''
      },
      {
        'name': 'Izgara Balık',
        'description': 'Çeşitli balık türleri ile ızgara balık',
        'ingredients': [
          '200g balık fileto (levrek, çupra, palamut)',
          '1 limon',
          '2 yemek kaşığı zeytinyağı',
          'Tuz, karabiber',
          'Kekik',
          'Sarımsak'
        ],
        'instructions': [
          'Balığı tuz, karabiber ve kekikle marine edin',
          'Zeytinyağı ve sarımsakla karıştırın',
          'Izgarada pişirin',
          'Limon suyuyla servis edin'
        ],
        'prepTime': 10,
        'cookTime': 15,
        'servings': 1,
        'calories': 350,
        'protein': 30.0,
        'carbs': 5.0,
        'fat': 20.0,
        'tags': ['protein', 'omega-3', 'düşük karbonhidrat'],
        'difficulty': 'Orta',
        'category': 'Akşam Yemeği',
        'imageUrl': ''
      },
    ];

    for (var recipe in dinnerRecipes) {
      await _firestore.collection('recipes').add(recipe);
    }
    print('Akşam yemeği tarifleri eklendi');
  }

  Future<void> _addSnackRecipes() async {
    final snackRecipes = [
      {
        'name': 'Elma ve Badem',
        'description': 'Sağlıklı ara öğün',
        'ingredients': [
          '1 elma',
          '10 adet badem',
          '1 çay kaşığı tarçın'
        ],
        'instructions': [
          'Elmayı dilimleyin',
          'Bademleri hazırlayın',
          'Tarçınla süsleyin'
        ],
        'prepTime': 5,
        'cookTime': 0,
        'servings': 1,
        'calories': 150,
        'protein': 5.0,
        'carbs': 20.0,
        'fat': 8.0,
        'tags': ['protein', 'lif', 'antioksidan'],
        'difficulty': 'Kolay',
        'category': 'Ara Öğün',
        'imageUrl': ''
      },
      {
        'name': 'Ton Balıklı Salata',
        'description': 'Protein açısından zengin ton balıklı salata',
        'ingredients': [
          '1 küçük konserve ton balığı (80-100g)',
          '1 ince dilim tam buğday ekmeği',
          '1 domates',
          '1 salatalık',
          '1/2 limon',
          '1 yemek kaşığı zeytinyağı',
          'Tuz, karabiber',
          'Maydanoz'
        ],
        'instructions': [
          'Ton balığını süzün',
          'Domates ve salatalığı küp küp doğrayın',
          'Tam buğday ekmeğini küp küp kesin',
          'Tüm malzemeleri karıştırın',
          'Zeytinyağı, limon suyu, tuz ve karabiberle soslayın',
          'Maydanozla süsleyin'
        ],
        'prepTime': 10,
        'cookTime': 0,
        'servings': 1,
        'calories': 210,
        'protein': 25.0,
        'carbs': 15.0,
        'fat': 8.0,
        'tags': ['protein', 'omega-3', 'düşük karbonhidrat'],
        'difficulty': 'Kolay',
        'category': 'Ara Öğün',
        'imageUrl': ''
      },
      {
        'name': 'Yoğurt ve Meyve',
        'description': 'Protein açısından zengin ara öğün',
        'ingredients': [
          '1 kase yoğurt',
          '1/2 muz',
          '1 yemek kaşığı ceviz',
          '1 çay kaşığı bal'
        ],
        'instructions': [
          'Yoğurdu kaseye koyun',
          'Muzu dilimleyin',
          'Ceviz ve bal ekleyin',
          'Karıştırın'
        ],
        'prepTime': 5,
        'cookTime': 0,
        'servings': 1,
        'calories': 200,
        'protein': 12.0,
        'carbs': 25.0,
        'fat': 8.0,
        'tags': ['protein', 'kalsiyum'],
        'difficulty': 'Kolay',
        'category': 'Ara Öğün',
        'imageUrl': ''
      }
    ];

    for (var recipe in snackRecipes) {
      await _firestore.collection('recipes').add(recipe);
    }
    print('Ara öğün tarifleri eklendi');
  }
}

// Bu fonksiyon main.dart'ta çağrılabilir
Future<void> seedDietRecipes() async {
  final seeder = DietRecipesSeeder();
  await seeder.seedDietRecipes();
}