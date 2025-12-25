import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_entry.dart';
import '../models/recipe.dart';

// Kalori aralıklarına göre haftalık plan şablonları
class MealPlanTemplates {
  // 1200-1400 kcal aralığı için planlar
  static List<Map<String, Map<String, String>>> getLowCaloriePlans() {
    return [
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '1 haşlanmış yumurta: 70 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 dilim beyaz peynir (20 g): 50 kcal\nDomates, salatalık: 20 kcal\n3 zeytin: 25 kcal',
          'calories': '235',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük elma: 60 kcal',
          'calories': '60',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 200 kcal\n3 YK bulgur pilavı: 80 kcal\nYoğurt (1 küçük kase): 50 kcal',
          'calories': '330',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '5 badem: 50 kcal',
          'calories': '50',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara tavuk göğsü (100 g): 180 kcal\nMevsim salata (az zeytinyağlı): 60 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '310',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Sebzeli omlet (1 yumurta + sebzeler): 150 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\nYeşil çay: 0 kcal',
          'calories': '220',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 50 kcal',
          'calories': '50',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Mercimek çorbası (1 kepçe): 120 kcal\nIzgara köfte (2 adet, 70 g): 150 kcal\nSalata: 60 kcal',
          'calories': '330',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 küçük muz: 80 kcal',
          'calories': '80',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli kinoa salatası (1 porsiyon): 280 kcal\nYoğurt (1 kase): 60 kcal',
          'calories': '340',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaf lapası (3 YK yulaf + 150 ml süt + tarçın): 250 kcal',
          'calories': '250',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '3 fındık: 40 kcal',
          'calories': '40',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Ton balıklı salata (1 light ton + sebzeler): 320 kcal',
          'calories': '320',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 dilim ananas: 50 kcal',
          'calories': '50',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Fırında sebzeli somon (100 g): 280 kcal\n2 YK karabuğday: 100 kcal\nYoğurt: 80 kcal',
          'calories': '460',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '1 haşlanmış yumurta: 70 kcal\n1 dilim peynir: 50 kcal\n1 dilim çavdar ekmeği: 70 kcal\nYeşillik: 20 kcal',
          'calories': '210',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 60 kcal',
          'calories': '60',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Tavuklu sebze sote: 250 kcal\n2 YK pirinç pilavı: 70 kcal\nYoğurt: 50 kcal',
          'calories': '370',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç leblebi: 80 kcal',
          'calories': '80',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Zeytinyağlı kabak yemeği: 200 kcal\nCacık: 100 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '370',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Smoothie (1 bardak süt + ½ muz + 2 YK yulaf): 250 kcal',
          'calories': '250',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem (8 adet): 80 kcal',
          'calories': '80',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Fırında köfte (2 adet): 180 kcal\nSebze garnitür: 80 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '330',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 70 kcal',
          'calories': '70',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli omlet: 250 kcal\nSalata: 60 kcal\n1 küçük yoğurt: 60 kcal',
          'calories': '370',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 50 kcal\n1 dilim tam buğday ekmek: 70 kcal\nSebzeler: 20 kcal',
          'calories': '280',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük armut: 70 kcal',
          'calories': '70',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Nohutlu sebze salatası (3 YK nohut + sebzeler): 350 kcal',
          'calories': '350',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '3 fındık: 40 kcal',
          'calories': '40',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Tavuklu karnabahar graten: 320 kcal\nSalata: 60 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '450',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaflı pancake (3 YK yulaf + 1 yumurta): 250 kcal\n1 tatlı kaşığı bal: 40 kcal',
          'calories': '290',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 50 kcal',
          'calories': '50',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı enginar: 200 kcal\n2 YK bulgur pilavı: 80 kcal\nYoğurt: 50 kcal',
          'calories': '330',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '2 yarım ceviz: 70 kcal',
          'calories': '70',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara balık (100 g): 250 kcal\nSalata: 60 kcal\n1 dilim tam tahıllı ekmek: 70 kcal',
          'calories': '380',
        },
      },
    ];
  }

  // 1400-1600 kcal aralığı için planlar (mevcut planlar)
  static List<Map<String, Map<String, String>>> getMediumLowCaloriePlans() {
    return [
  // Gün 1 - ~1450 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 dilim beyaz peynir (30 g): 80 kcal\nDomates, salatalık, yeşillik: 30 kcal\n4 zeytin: 30 kcal',
      'calories': '350',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 elma: 80 kcal',
      'calories': '80',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 250 kcal\n4 YK bulgur pilavı: 100 kcal\nYoğurt (1 küçük kase): 50 kcal',
      'calories': '400',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '10 badem: 100 kcal',
      'calories': '100',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Izgara tavuk göğsü (120 g): 220 kcal\nMevsim salata (1 tatlı kaşığı zeytinyağlı): 80 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
      'calories': '450',
    },
  },
  // Gün 2 - ~1430 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': '1 dilim tam tahıllı ekmek: 70 kcal\nSebzeli omlet (1 yumurta + sebzeler + 1 çay kaşığı zeytinyağı): 200 kcal\nYeşil çay: 0 kcal',
      'calories': '300',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 mandalina: 60 kcal',
      'calories': '60',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Mercimek çorbası (1 kepçe): 150 kcal\nIzgara köfte (3 adet, 100 g toplam): 220 kcal\nSalata: 80 kcal',
      'calories': '450',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '1 küçük muz: 100 kcal',
      'calories': '100',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Sebzeli kinoa salatası (1 porsiyon): 350 kcal\nYoğurt (1 kase): 70 kcal\n1 kare bitter çikolata (isteğe bağlı): 100 kcal',
      'calories': '520',
    },
  },
  // Gün 3 - ~1450 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': 'Yulaf lapası (4 YK yulaf + 200 ml süt + ½ muz + tarçın): 320 kcal',
      'calories': '320',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '5 fındık: 70 kcal',
      'calories': '70',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Ton balıklı salata (1 light ton + sebzeler + az zeytinyağı): 400 kcal',
      'calories': '400',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '1 dilim ananas: 60 kcal',
      'calories': '60',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Fırında sebzeli somon (120 g): 350 kcal\n3 YK karabuğday: 150 kcal\nYoğurt: 100 kcal',
      'calories': '600',
    },
  },
  // Gün 4 - ~1420 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': '1 haşlanmış yumurta: 70 kcal\n1 dilim peynir: 80 kcal\n1 dilim çavdar ekmeği: 70 kcal\nYeşillik + domates: 30 kcal\n3 zeytin: 50 kcal',
      'calories': '300',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 elma: 80 kcal',
      'calories': '80',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Tavuklu sebze sote: 300 kcal\n3 YK pirinç pilavı: 100 kcal\nYoğurt: 50 kcal',
      'calories': '450',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '1 avuç leblebi: 100 kcal',
      'calories': '100',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Zeytinyağlı kabak yemeği: 250 kcal\nCacık: 120 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 kare bitter çikolata: 50 kcal',
      'calories': '490',
    },
  },
  // Gün 5 - ~1470 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': 'Smoothie (1 bardak süt + ½ muz + 2 YK yulaf + 1 YK chia): 320 kcal',
      'calories': '320',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 avuç çiğ badem: 100 kcal',
      'calories': '100',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Fırında köfte (3 adet): 250 kcal\nSebze garnitür: 100 kcal\n1 dilim tam buğday ekmek: 70 kcal\nAyran: 30 kcal',
      'calories': '450',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '1 portakal: 80 kcal',
      'calories': '80',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Sebzeli omlet: 300 kcal\nSalata: 70 kcal\n1 küçük yoğurt: 80 kcal\n1 kare bitter çikolata: 70 kcal',
      'calories': '520',
    },
  },
  // Gün 6 - ~1440 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 80 kcal\n1 dilim tam buğday ekmek: 70 kcal\nSebzeler: 30 kcal',
      'calories': '320',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 küçük armut: 80 kcal',
      'calories': '80',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Nohutlu sebze salatası (4 YK nohut + sebzeler + az zeytinyağı): 420 kcal',
      'calories': '420',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '5 fındık: 70 kcal',
      'calories': '70',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Tavuklu karnabahar graten (yoğurtlu sosla): 400 kcal\nSalata: 80 kcal\n1 dilim tam buğday ekmek: 70 kcal',
      'calories': '550',
    },
  },
  // Gün 7 - ~1450 kcal
  {
    'Kahvaltı': {
      'name': 'Kahvaltı',
      'description': 'Yulaflı pancake (4 YK yulaf + 1 yumurta + ½ muz): 300 kcal\n1 tatlı kaşığı bal: 50 kcal',
      'calories': '350',
    },
    'Ara Öğün 1': {
      'name': 'Ara Öğün',
      'description': '1 mandalina: 60 kcal',
      'calories': '60',
    },
    'Öğle Yemeği': {
      'name': 'Öğle Yemeği',
      'description': 'Zeytinyağlı enginar: 250 kcal\n3 YK bulgur pilavı: 120 kcal\nYoğurt: 50 kcal',
      'calories': '420',
    },
    'Ara Öğün 2': {
      'name': 'Ara Öğün',
      'description': '3 yarım ceviz: 100 kcal',
      'calories': '100',
    },
    'Akşam Yemeği': {
      'name': 'Akşam Yemeği',
      'description': 'Izgara balık (120 g): 300 kcal\nSalata (zeytinyağlı): 80 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\n1 küçük yoğurt: 70 kcal',
      'calories': '520',
    },
  },
];
  }

  // 1600-1800 kcal aralığı için planlar
  static List<Map<String, Map<String, String>>> getMediumCaloriePlans() {
    return [
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n2 dilim tam buğday ekmek: 140 kcal\n1 dilim beyaz peynir (40 g): 100 kcal\nDomates, salatalık, yeşillik: 30 kcal\n5 zeytin: 40 kcal',
          'calories': '450',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n1 avuç badem (10 adet): 100 kcal',
          'calories': '180',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 250 kcal\n5 YK bulgur pilavı: 120 kcal\nYoğurt (1 küçük kase): 50 kcal',
          'calories': '420',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 küçük muz: 100 kcal',
          'calories': '100',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara tavuk göğsü (150 g): 280 kcal\nMevsim salata (zeytinyağlı): 100 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '530',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Sebzeli omlet (2 yumurta + sebzeler + zeytinyağı): 300 kcal\n2 dilim tam tahıllı ekmek: 140 kcal',
          'calories': '440',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal\n5 fındık: 70 kcal',
          'calories': '150',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Mercimek çorbası (1 kepçe): 150 kcal\nIzgara köfte (4 adet, 130 g): 280 kcal\nSalata: 80 kcal\n1 dilim ekmek: 70 kcal',
          'calories': '580',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem: 100 kcal',
          'calories': '100',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli kinoa salatası (1 porsiyon): 380 kcal\nYoğurt (1 kase): 70 kcal',
          'calories': '450',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaf lapası (5 YK yulaf + 200 ml süt + ½ muz + tarçın + 1 YK chia): 400 kcal',
          'calories': '400',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n3 yarım ceviz: 100 kcal',
          'calories': '180',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Ton balıklı salata (1 light ton + sebzeler + zeytinyağı): 450 kcal',
          'calories': '450',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 dilim ananas: 60 kcal\n1 avuç leblebi: 100 kcal',
          'calories': '160',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Fırında sebzeli somon (150 g): 420 kcal\n4 YK karabuğday: 200 kcal\nYoğurt: 100 kcal',
          'calories': '720',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 80 kcal\n2 dilim çavdar ekmeği: 140 kcal\nYeşillik + domates: 30 kcal\n5 zeytin: 50 kcal',
          'calories': '440',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal',
          'calories': '80',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Tavuklu sebze sote: 350 kcal\n4 YK pirinç pilavı: 140 kcal\nYoğurt: 50 kcal',
          'calories': '540',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç leblebi: 100 kcal\n1 küçük muz: 100 kcal',
          'calories': '200',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Zeytinyağlı kabak yemeği: 280 kcal\nCacık: 120 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '470',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Smoothie (1 bardak süt + 1 muz + 3 YK yulaf + 1 YK chia): 380 kcal',
          'calories': '380',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem (15 adet): 150 kcal',
          'calories': '150',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Fırında köfte (4 adet): 320 kcal\nSebze garnitür: 100 kcal\n1 dilim tam buğday ekmek: 70 kcal\nAyran: 30 kcal',
          'calories': '520',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal',
          'calories': '80',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli omlet (2 yumurta): 350 kcal\nSalata: 80 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '510',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 80 kcal\n2 dilim tam buğday ekmek: 140 kcal\nSebzeler: 30 kcal',
          'calories': '390',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük armut: 80 kcal\n5 fındık: 70 kcal',
          'calories': '150',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Nohutlu sebze salatası (5 YK nohut + sebzeler): 480 kcal',
          'calories': '480',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '5 fındık: 70 kcal\n1 mandalina: 60 kcal',
          'calories': '130',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Tavuklu karnabahar graten: 450 kcal\nSalata: 80 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '600',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaflı pancake (5 YK yulaf + 2 yumurta + ½ muz): 400 kcal\n1 tatlı kaşığı bal: 50 kcal',
          'calories': '450',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 60 kcal\n10 badem: 100 kcal',
          'calories': '160',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı enginar: 280 kcal\n4 YK bulgur pilavı: 160 kcal\nYoğurt: 50 kcal',
          'calories': '490',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '3 yarım ceviz: 100 kcal',
          'calories': '100',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara balık (150 g): 380 kcal\nSalata (zeytinyağlı): 100 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '630',
        },
      },
    ];
  }

  // 1800-2000 kcal aralığı için planlar
  static List<Map<String, Map<String, String>>> getMediumHighCaloriePlans() {
    return [
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n2 dilim tam buğday ekmek: 140 kcal\n1 dilim beyaz peynir (50 g): 120 kcal\nDomates, salatalık, yeşillik: 30 kcal\n6 zeytin: 50 kcal',
          'calories': '480',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n15 badem: 150 kcal',
          'calories': '230',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 280 kcal\n6 YK bulgur pilavı: 150 kcal\nYoğurt (1 küçük kase): 50 kcal',
          'calories': '480',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 küçük muz: 100 kcal\n1 avuç leblebi: 100 kcal',
          'calories': '200',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara tavuk göğsü (180 g): 340 kcal\nMevsim salata (zeytinyağlı): 120 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '610',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Sebzeli omlet (2 yumurta + sebzeler + zeytinyağı): 350 kcal\n2 dilim tam tahıllı ekmek: 140 kcal\n1 dilim peynir: 80 kcal',
          'calories': '570',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal',
          'calories': '250',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Mercimek çorbası (1 kepçe): 150 kcal\nIzgara köfte (5 adet, 160 g): 350 kcal\nSalata: 80 kcal\n1 dilim ekmek: 70 kcal',
          'calories': '650',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem: 100 kcal',
          'calories': '100',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli kinoa salatası (1 porsiyon): 420 kcal\nYoğurt (1 kase): 70 kcal',
          'calories': '490',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaf lapası (6 YK yulaf + 250 ml süt + 1 muz + tarçın + 1 YK chia): 520 kcal',
          'calories': '520',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n3 yarım ceviz: 100 kcal\n5 fındık: 70 kcal',
          'calories': '250',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Ton balıklı salata (1 light ton + sebzeler + zeytinyağı): 500 kcal',
          'calories': '500',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 dilim ananas: 60 kcal\n1 avuç leblebi: 100 kcal',
          'calories': '160',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Fırında sebzeli somon (180 g): 500 kcal\n5 YK karabuğday: 250 kcal\nYoğurt: 100 kcal',
          'calories': '850',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 100 kcal\n2 dilim çavdar ekmeği: 140 kcal\nYeşillik + domates: 30 kcal\n6 zeytin: 60 kcal',
          'calories': '470',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n1 küçük muz: 100 kcal',
          'calories': '180',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Tavuklu sebze sote: 400 kcal\n5 YK pirinç pilavı: 180 kcal\nYoğurt: 50 kcal',
          'calories': '630',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç leblebi: 100 kcal\n1 küçük muz: 100 kcal',
          'calories': '200',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Zeytinyağlı kabak yemeği: 320 kcal\nCacık: 140 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '530',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Smoothie (1 bardak süt + 1 muz + 4 YK yulaf + 1 YK chia): 450 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '520',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem (20 adet): 200 kcal',
          'calories': '200',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Fırında köfte (5 adet): 400 kcal\nSebze garnitür: 120 kcal\n1 dilim tam buğday ekmek: 70 kcal\nAyran: 30 kcal',
          'calories': '620',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal',
          'calories': '80',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli omlet (2 yumurta): 380 kcal\nSalata: 100 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '560',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 100 kcal\n2 dilim tam buğday ekmek: 140 kcal\nSebzeler: 30 kcal',
          'calories': '410',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük armut: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal',
          'calories': '250',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Nohutlu sebze salatası (6 YK nohut + sebzeler): 550 kcal',
          'calories': '550',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '5 fındık: 70 kcal\n1 mandalina: 60 kcal\n10 badem: 100 kcal',
          'calories': '230',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Tavuklu karnabahar graten: 520 kcal\nSalata: 100 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '690',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaflı pancake (6 YK yulaf + 2 yumurta + 1 muz): 500 kcal\n1 tatlı kaşığı bal: 50 kcal',
          'calories': '550',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 60 kcal\n15 badem: 150 kcal',
          'calories': '210',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı enginar: 320 kcal\n5 YK bulgur pilavı: 200 kcal\nYoğurt: 50 kcal',
          'calories': '570',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '3 yarım ceviz: 100 kcal\n1 küçük muz: 100 kcal',
          'calories': '200',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara balık (180 g): 450 kcal\nSalata (zeytinyağlı): 120 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '720',
        },
      },
    ];
  }

  // 2000-2200 kcal aralığı için planlar
  static List<Map<String, Map<String, String>>> getHighCaloriePlans() {
    return [
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n2 dilim tam buğday ekmek: 140 kcal\n1 dilim beyaz peynir (60 g): 150 kcal\nDomates, salatalık, yeşillik: 30 kcal\n7 zeytin: 60 kcal',
          'calories': '520',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n20 badem: 200 kcal',
          'calories': '280',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 300 kcal\n7 YK bulgur pilavı: 180 kcal\nYoğurt (1 küçük kase): 50 kcal',
          'calories': '530',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 küçük muz: 100 kcal\n1 avuç leblebi: 100 kcal\n3 yarım ceviz: 100 kcal',
          'calories': '300',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara tavuk göğsü (200 g): 380 kcal\nMevsim salata (zeytinyağlı): 140 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '670',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Sebzeli omlet (3 yumurta + sebzeler + zeytinyağı): 450 kcal\n2 dilim tam tahıllı ekmek: 140 kcal\n1 dilim peynir: 100 kcal',
          'calories': '690',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal\n10 badem: 100 kcal',
          'calories': '350',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Mercimek çorbası (1 kepçe): 150 kcal\nIzgara köfte (6 adet, 200 g): 440 kcal\nSalata: 80 kcal\n1 dilim ekmek: 70 kcal',
          'calories': '740',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem: 100 kcal',
          'calories': '100',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli kinoa salatası (1 porsiyon): 480 kcal\nYoğurt (1 kase): 70 kcal',
          'calories': '550',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaf lapası (7 YK yulaf + 250 ml süt + 1 muz + tarçın + 1 YK chia): 580 kcal',
          'calories': '580',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n3 yarım ceviz: 100 kcal\n5 fındık: 70 kcal\n10 badem: 100 kcal',
          'calories': '350',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Ton balıklı salata (1 light ton + sebzeler + zeytinyağı): 550 kcal',
          'calories': '550',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 dilim ananas: 60 kcal\n1 avuç leblebi: 100 kcal',
          'calories': '160',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Fırında sebzeli somon (200 g): 560 kcal\n6 YK karabuğday: 300 kcal\nYoğurt: 100 kcal',
          'calories': '960',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 120 kcal\n2 dilim çavdar ekmeği: 140 kcal\nYeşillik + domates: 30 kcal\n7 zeytin: 70 kcal',
          'calories': '500',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n1 küçük muz: 100 kcal',
          'calories': '180',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Tavuklu sebze sote: 450 kcal\n6 YK pirinç pilavı: 220 kcal\nYoğurt: 50 kcal',
          'calories': '720',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç leblebi: 100 kcal\n1 küçük muz: 100 kcal\n3 yarım ceviz: 100 kcal',
          'calories': '300',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Zeytinyağlı kabak yemeği: 360 kcal\nCacık: 160 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '590',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Smoothie (1 bardak süt + 1 muz + 5 YK yulaf + 1 YK chia): 520 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '590',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem (25 adet): 250 kcal',
          'calories': '250',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Fırında köfte (6 adet): 480 kcal\nSebze garnitür: 140 kcal\n1 dilim tam buğday ekmek: 70 kcal\nAyran: 30 kcal',
          'calories': '720',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal',
          'calories': '80',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli omlet (3 yumurta): 450 kcal\nSalata: 120 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '650',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 120 kcal\n2 dilim tam buğday ekmek: 140 kcal\nSebzeler: 30 kcal',
          'calories': '430',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük armut: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal\n10 badem: 100 kcal',
          'calories': '350',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Nohutlu sebze salatası (7 YK nohut + sebzeler): 620 kcal',
          'calories': '620',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '5 fındık: 70 kcal\n1 mandalina: 60 kcal\n15 badem: 150 kcal',
          'calories': '280',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Tavuklu karnabahar graten: 580 kcal\nSalata: 120 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '770',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaflı pancake (7 YK yulaf + 2 yumurta + 1 muz): 580 kcal\n1 tatlı kaşığı bal: 50 kcal',
          'calories': '630',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 60 kcal\n20 badem: 200 kcal',
          'calories': '260',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı enginar: 360 kcal\n6 YK bulgur pilavı: 240 kcal\nYoğurt: 50 kcal',
          'calories': '650',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '3 yarım ceviz: 100 kcal\n1 küçük muz: 100 kcal\n1 avuç leblebi: 100 kcal',
          'calories': '300',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara balık (200 g): 500 kcal\nSalata (zeytinyağlı): 140 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '790',
        },
      },
    ];
  }

  // 2200+ kcal aralığı için planlar
  static List<Map<String, Map<String, String>>> getVeryHighCaloriePlans() {
    return [
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n2 dilim tam buğday ekmek: 140 kcal\n1 dilim beyaz peynir (70 g): 180 kcal\nDomates, salatalık, yeşillik: 30 kcal\n8 zeytin: 70 kcal',
          'calories': '560',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n25 badem: 250 kcal',
          'calories': '330',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı taze fasulye (1 porsiyon): 320 kcal\n8 YK bulgur pilavı: 200 kcal\nYoğurt (1 küçük kase): 50 kcal',
          'calories': '570',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 küçük muz: 100 kcal\n1 avuç leblebi: 100 kcal\n3 yarım ceviz: 100 kcal\n10 badem: 100 kcal',
          'calories': '400',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara tavuk göğsü (220 g): 420 kcal\nMevsim salata (zeytinyağlı): 160 kcal\n1 dilim tam buğday ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '730',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Sebzeli omlet (3 yumurta + sebzeler + zeytinyağı): 500 kcal\n2 dilim tam tahıllı ekmek: 140 kcal\n1 dilim peynir: 120 kcal',
          'calories': '760',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal\n15 badem: 150 kcal',
          'calories': '400',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Mercimek çorbası (1 kepçe): 150 kcal\nIzgara köfte (7 adet, 230 g): 510 kcal\nSalata: 80 kcal\n1 dilim ekmek: 70 kcal',
          'calories': '810',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem: 100 kcal\n1 küçük muz: 100 kcal',
          'calories': '200',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli kinoa salatası (1 porsiyon): 540 kcal\nYoğurt (1 kase): 70 kcal',
          'calories': '610',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaf lapası (8 YK yulaf + 300 ml süt + 1 muz + tarçın + 1 YK chia): 650 kcal',
          'calories': '650',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n3 yarım ceviz: 100 kcal\n5 fındık: 70 kcal\n15 badem: 150 kcal',
          'calories': '400',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Ton balıklı salata (1 light ton + sebzeler + zeytinyağı): 600 kcal',
          'calories': '600',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 dilim ananas: 60 kcal\n1 avuç leblebi: 100 kcal\n1 küçük muz: 100 kcal',
          'calories': '260',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Fırında sebzeli somon (220 g): 620 kcal\n7 YK karabuğday: 350 kcal\nYoğurt: 100 kcal',
          'calories': '1070',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 140 kcal\n2 dilim çavdar ekmeği: 140 kcal\nYeşillik + domates: 30 kcal\n8 zeytin: 80 kcal',
          'calories': '530',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 elma: 80 kcal\n1 küçük muz: 100 kcal\n10 badem: 100 kcal',
          'calories': '280',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Tavuklu sebze sote: 500 kcal\n7 YK pirinç pilavı: 260 kcal\nYoğurt: 50 kcal',
          'calories': '810',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 avuç leblebi: 100 kcal\n1 küçük muz: 100 kcal\n3 yarım ceviz: 100 kcal\n10 badem: 100 kcal',
          'calories': '400',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Zeytinyağlı kabak yemeği: 400 kcal\nCacık: 180 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '650',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Smoothie (1 bardak süt + 1 muz + 6 YK yulaf + 1 YK chia): 580 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '650',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 avuç çiğ badem (30 adet): 300 kcal',
          'calories': '300',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Fırında köfte (7 adet): 560 kcal\nSebze garnitür: 160 kcal\n1 dilim tam buğday ekmek: 70 kcal\nAyran: 30 kcal',
          'calories': '820',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '1 portakal: 80 kcal\n1 küçük muz: 100 kcal',
          'calories': '180',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Sebzeli omlet (3 yumurta): 500 kcal\nSalata: 140 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '720',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': '2 haşlanmış yumurta: 140 kcal\n1 dilim peynir: 140 kcal\n2 dilim tam buğday ekmek: 140 kcal\nSebzeler: 30 kcal',
          'calories': '450',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 küçük armut: 80 kcal\n5 fındık: 70 kcal\n3 yarım ceviz: 100 kcal\n15 badem: 150 kcal',
          'calories': '400',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Nohutlu sebze salatası (8 YK nohut + sebzeler): 680 kcal',
          'calories': '680',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '5 fındık: 70 kcal\n1 mandalina: 60 kcal\n20 badem: 200 kcal',
          'calories': '330',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Tavuklu karnabahar graten: 640 kcal\nSalata: 140 kcal\n1 dilim tam buğday ekmek: 70 kcal',
          'calories': '850',
        },
      },
      {
        'Kahvaltı': {
          'name': 'Kahvaltı',
          'description': 'Yulaflı pancake (8 YK yulaf + 2 yumurta + 1 muz): 650 kcal\n1 tatlı kaşığı bal: 50 kcal',
          'calories': '700',
        },
        'Ara Öğün 1': {
          'name': 'Ara Öğün',
          'description': '1 mandalina: 60 kcal\n25 badem: 250 kcal',
          'calories': '310',
        },
        'Öğle Yemeği': {
          'name': 'Öğle Yemeği',
          'description': 'Zeytinyağlı enginar: 400 kcal\n7 YK bulgur pilavı: 280 kcal\nYoğurt: 50 kcal',
          'calories': '730',
        },
        'Ara Öğün 2': {
          'name': 'Ara Öğün',
          'description': '3 yarım ceviz: 100 kcal\n1 küçük muz: 100 kcal\n1 avuç leblebi: 100 kcal\n10 badem: 100 kcal',
          'calories': '400',
        },
        'Akşam Yemeği': {
          'name': 'Akşam Yemeği',
          'description': 'Izgara balık (220 g): 550 kcal\nSalata (zeytinyağlı): 160 kcal\n1 dilim tam tahıllı ekmek: 70 kcal\n1 küçük yoğurt: 80 kcal',
          'calories': '860',
        },
      },
    ];
  }

  // Kalori aralığına göre uygun planları döndür
  static List<Map<String, Map<String, String>>> getPlansForCalorieRange(int dailyCalories) {
    if (dailyCalories < 1400) {
      return getLowCaloriePlans();
    } else if (dailyCalories < 1600) {
      return getMediumLowCaloriePlans();
    } else if (dailyCalories < 1800) {
      return getMediumCaloriePlans();
    } else if (dailyCalories < 2000) {
      return getMediumHighCaloriePlans();
    } else if (dailyCalories < 2200) {
      return getHighCaloriePlans();
    } else {
      return getVeryHighCaloriePlans();
    }
  }
}

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Kural tabanlı helper metodlar
  int _goalCode(String? dietGoal) {
    if (dietGoal == null) return 1; // varsayılan: koru
    final g = dietGoal.toLowerCase();
    if (g.contains('kilo ver') || g.contains('zayıflama')) return 0;
    if (g.contains('kilo al')) return 2;
    return 1;
  }

  int _mealCode(String mealType) {
    if (mealType == 'Kahvaltı') return 0;
    if (mealType == 'Öğle Yemeği') return 1;
    if (mealType.contains('Akşam')) return 2;
    return 3; // Ara öğün/diğer
  }
  
  // Kural tabanlı kategori seçimi
  // 0: Protein, 1: Sebze/Hafif, 2: Karbonhidrat/Enerji, 3: Dengeli
  int _getMealCategory({
    required int age,
    required double weight,
    required int goalCode,
    required int mealCode,
  }) {
    // Kural tabanlı basit mantık:
    // - Kilo verme hedefli -> Sebze/Hafif (1) veya Dengeli (3)
    // - Kilo alma hedefli -> Karbonhidrat/Enerji (2) veya Dengeli (3)
    // - Kilo koruma -> Dengeli (3)
    // - Kahvaltı -> Dengeli (3)
    // - Öğle -> Dengeli (3) 
    // - Akşam -> Dengeli (3)
    
    // Şimdilik basit bir kural: hedef ve öğün tipine göre
    if (goalCode == 0) {
      // Kilo verme -> Sebze/Hafif
      return 1;
    } else if (goalCode == 2) {
      // Kilo alma -> Karbonhidrat/Enerji
      return 2;
    }
    // Varsayılan: Dengeli
    return 3;
  }

  List<Map<String, dynamic>> _filterByCategory(
    List<Map<String, dynamic>> candidates,
    int category,
  ) {
    // 0: Protein, 1: Sebze/Hafif, 2: Karbonhidrat/Enerji, 3: Dengeli
    if (category == 3) return candidates; // dengeli -> filtre yok

    bool match(Map<String, dynamic> c, List<String> needles) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final desc = (c['description'] ?? '').toString().toLowerCase();
      return needles.any((n) => name.contains(n) || desc.contains(n));
    }

    if (category == 0) {
      // protein
      return candidates
          .where((c) => match(c, [
                'tavuk',
                'et',
                'yumurta',
                'balık',
                'somon',
                'ton',
                'köfte',
                'peynir',
                'protein'
              ]))
          .toList();
    }
    if (category == 1) {
      // sebze / hafif
      return candidates
          .where((c) => match(c, [
                'sebze',
                'salata',
                'çorba',
                'zeytinyağlı',
                'avokado',
                'kabak',
                'enginar',
                'meyve',
                'hafif'
              ]))
          .toList();
    }
    // category == 2 -> karbonhidrat / enerji
    return candidates
        .where((c) => match(c, [
              'yulaf',
              'pankek',
              'ekmek',
              'pilav',
              'makarna',
              'tost',
            ]))
        .toList();
  }

  // Örnek menüyü Firebase'e tarif olarak kaydet ve recipeId döndür
  Future<String> _saveExampleMealAsRecipe(String mealName, String description, int calories, String mealType) async {
    try {
      // Category'yi düzelt
      final category = mealType.contains('Ara') ? 'Ara Öğün' : mealType;
      
      // Önce aynı isimde tarif var mı kontrol et
      final existingQuery = await _db.collection('recipes')
          .where('name', isEqualTo: mealName)
          .where('category', isEqualTo: category)
          .limit(1)
          .get();
      
      if (existingQuery.docs.isNotEmpty) {
        return existingQuery.docs.first.id; // Mevcut tarifin ID'sini döndür
      }

      // Description'dan malzemeleri parse et
      final ingredients = description.split('\n')
          .where((line) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) return false;
            // Sadece kalori olan satırları atla
            if (RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(trimmed)) return false;
            if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;
            return true;
          })
          .map((line) {
            // "Malzeme: kalori kcal" formatından sadece malzeme adını al
            String ingredient = line.split(':').first.trim();
            // Kalori bilgisini temizle
            ingredient = ingredient.replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '').trim();
            return ingredient;
          })
          .where((ing) => ing.isNotEmpty && !RegExp(r'^\d+$').hasMatch(ing))
          .toList();

      // Eğer ingredients boşsa, description'ı kullan
      if (ingredients.isEmpty) {
        ingredients.add(mealName);
      }

      // Recipe oluştur
      final recipe = Recipe(
        id: '', // Firebase otomatik ID oluşturacak
        name: mealName,
        description: description,
        ingredients: ingredients,
        instructions: ['Tarif detayları için malzemeler listesine bakın.'],
        prepTime: 10,
        cookTime: 20,
        servings: 1,
        calories: calories,
        protein: (calories * 0.15 / 4).roundToDouble(), // Yaklaşık %15 protein
        carbs: (calories * 0.50 / 4).roundToDouble(), // Yaklaşık %50 karbonhidrat
        fat: (calories * 0.35 / 9).roundToDouble(), // Yaklaşık %35 yağ
        tags: [],
        difficulty: 'Kolay',
        imageUrl: '',
        category: category,
      );

      // Firebase'e kaydet
      final docRef = await _db.collection('recipes').add(recipe.toMap());
      return docRef.id;
    } catch (e) {
      print('Tarif kaydedilemedi: $e');
      return ''; // Hata durumunda boş string döndür
    }
  }

  Future<Map<String, dynamic>> _getUserInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final doc = await _db.collection('user_infos').doc(uid).get();
    return doc.data() ?? {};
  }

  /// recipes koleksiyonundan diyet türüne uygun öğün bul
  Future<List<Map<String, dynamic>>> _getRecipesForType(String mealType, String? dietType) async {
    List<Map<String, dynamic>> all = [];
    try {
      final q = await _db.collection('recipes')
          .where('mealType', isEqualTo: mealType)
          .limit(100)
          .get();
      all = q.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      final q2 = await _db.collection('recipes').limit(200).get();
      all = q2.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }

    if (all.isEmpty) {
      final q2 = await _db.collection('recipes').limit(200).get();
      all = q2.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }

    final lower = mealType.toLowerCase();
    final filteredByMeal = all.where((e) {
      final cat = e['category']?.toString().toLowerCase() ?? '';
      final name = e['name']?.toString().toLowerCase() ?? '';
      final tags = (e['tags'] as List?)?.map((x) => x.toString().toLowerCase()).toList() ?? [];
      return cat.contains(lower) || name.contains(lower) || tags.any((t) => t.contains(lower));
    }).toList();

    final base = filteredByMeal.isEmpty ? all : filteredByMeal;
    if (dietType == null || dietType.isEmpty) return all;
    final dtLower = dietType.toLowerCase();
    if (dtLower.contains('önerilen') || dtLower.contains('recommended')) return base;

    final filtered = base.where((e) {
      final tags = (e['tags'] as List?)?.map((x) => x.toString().toLowerCase()).toList() ?? [];
      final key = dietType.toString().toLowerCase();
      return tags.any((t) => t.contains(key));
    }).toList();

    return filtered.isEmpty ? base : filtered;
  }

  /// Firestore’daki özel listelerden (Kahvaltı, Öğle Yemeği vb.) öğünleri çek
  Future<List<Map<String, dynamic>>> _getCustomMeals(String mealType) async {
    final collectionName =
        mealType.toLowerCase().contains('ara') ? 'Ara Öğün' : mealType;

    try {
      final snapshot = await _db.collection(collectionName).get();
      final List<Map<String, dynamic>> options = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.isEmpty) continue;

        for (final entry in data.entries) {
          final value = entry.value;
          if (value is! String) continue;

          final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (cleaned.isEmpty) continue;

          final components = _splitCustomMeal(cleaned);

          options.add({
            'id': '${collectionName}_${doc.id}_${entry.key}',
            'name': components.isNotEmpty ? components.first : cleaned,
            'description': cleaned,
            'customComponents': components,
            'source': 'custom',
          });
        }
      }

      return options;
    } catch (e, s) {
      print('⚠️ Firestore özel liste hatası ($collectionName): $e');
      print(s);
      return [];
    }
  }

  /// Metinleri (örneğin "Tavuk haşlama (80g): ≈ 120 kcal") parçalara ayırır
  List<String> _splitCustomMeal(String text) {
    String normalized = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('≈', '')
        .replaceAll('~', '')
        .trim();

    // Sadece kalori değerlerini temizle (örn: "120 kcal", "80-100 kcal")
    normalized = normalized.replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '');
    normalized = normalized.replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '');
    normalized = normalized.replaceAll(RegExp(r'^\d+$'), ''); // Sadece sayı olan satırları temizle
    
    // ":" veya ";" gibi ayraçlara göre parçala
    final parts = normalized
        .split(RegExp(r'[:;•\-]'))
        .map((e) => e.trim())
        .where((e) {
          // Boş, sadece sayı, veya sadece kalori içeren parçaları filtrele
          if (e.isEmpty) return false;
          if (RegExp(r'^\d+$').hasMatch(e)) return false; // Sadece sayı
          if (RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(e)) return false; // Sadece kalori
          if (RegExp(r'^\d+\s*-\s*\d+\s*kcal$', caseSensitive: false).hasMatch(e)) return false; // Kalori aralığı
          return true;
        })
        .toList();

    return parts.isEmpty ? [text] : parts;
  }

  Future<List<Map<String, dynamic>>> _buildCandidatePool(String mealType, String? dietType) async {
    final recipes = await _getRecipesForType(mealType, dietType);
    final custom = await _getCustomMeals(mealType);
    if (custom.isEmpty) return recipes;
    return [...recipes, ...custom];
  }

  /// Firebase'den kalori aralığına göre plan şablonlarını çek
  Future<List<Map<String, Map<String, String>>>> _getPlansFromFirebase(int dailyCalories) async {
    try {
      // Kalori aralığını belirle
      String calorieRange;
      if (dailyCalories < 1400) {
        calorieRange = '1200-1400';
      } else if (dailyCalories < 1600) {
        calorieRange = '1400-1600';
      } else if (dailyCalories < 1800) {
        calorieRange = '1600-1800';
      } else if (dailyCalories < 2000) {
        calorieRange = '1800-2000';
      } else if (dailyCalories < 2200) {
        calorieRange = '2000-2200';
      } else {
        calorieRange = '2200+';
      }

      // Firebase'den plan şablonlarını çek
      // Not: orderBy kullanmadan çek, sonra memory'de sırala (index gerektirmez)
      final snapshot = await _db
          .collection('meal_plan_templates')
          .where('calorieRange', isEqualTo: calorieRange)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ Firebase\'de $calorieRange kalori aralığı için plan bulunamadı, kod içindeki planlar kullanılacak');
        // Fallback: Kod içindeki planları kullan
        return MealPlanTemplates.getPlansForCalorieRange(dailyCalories);
      }

      // Firebase'den gelen planları parse et ve dayIndex'e göre sırala
      final List<Map<String, dynamic>> plansWithIndex = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dayIndex = (data['dayIndex'] as num?)?.toInt() ?? 0;
        plansWithIndex.add({
          'dayIndex': dayIndex,
          'data': data,
        });
      }
      
      // dayIndex'e göre sırala
      plansWithIndex.sort((a, b) => (a['dayIndex'] as int).compareTo(b['dayIndex'] as int));
      
      // Planları parse et
      final List<Map<String, Map<String, String>>> plans = [];
      for (final item in plansWithIndex) {
        final data = item['data'] as Map<String, dynamic>;
        final meals = data['meals'] as Map<String, dynamic>? ?? {};
        
        final dayPlan = <String, Map<String, String>>{};
        for (final entry in meals.entries) {
          final mealData = entry.value as Map<String, dynamic>;
          dayPlan[entry.key] = {
            'name': mealData['name']?.toString() ?? entry.key,
            'description': mealData['description']?.toString() ?? '',
            'calories': mealData['calories']?.toString() ?? '0',
          };
        }
        plans.add(dayPlan);
      }

      return plans;
    } catch (e) {
      print('⚠️ Firebase\'den plan çekilemedi: $e, kod içindeki planlar kullanılacak');
      // Fallback: Kod içindeki planları kullan
      return MealPlanTemplates.getPlansForCalorieRange(dailyCalories);
    }
  }

  /// Firebase'den kullanıcının mevcut planını çek
  Future<List<MealEntry>?> getSavedWeeklyPlan() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Index gerektiren query yerine daha basit bir yaklaşım kullanalım
      // Tüm kullanıcı planlarını çek, sonra tarih filtresini uygula
      final snapshot = await _db
          .collection('meal_entries')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return null;

      // Tarih filtresini memory'de uygula
      final entries = snapshot.docs
          .map((doc) {
            try {
              return MealEntry.fromMap(doc.id, doc.data());
            } catch (e) {
              return null;
            }
          })
          .where((entry) => entry != null)
          .cast<MealEntry>()
          .where((entry) {
            final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
            return entryDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                   entryDate.isBefore(endOfWeek);
          })
          .toList();

      return entries.isEmpty ? null : entries;
    } catch (e) {
      print('Plan çekilemedi: $e');
      return null;
    }
  }

  /// Planı Firebase'e kaydet
  Future<void> saveWeeklyPlanToFirebase(List<MealEntry> plan) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Önce mevcut haftalık planı sil (index gerektirmeyen yöntem)
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Tüm kullanıcı planlarını çek
      final existingSnapshot = await _db
          .collection('meal_entries')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _db.batch();
      
      // Haftalık aralıktaki planları sil
      for (final doc in existingSnapshot.docs) {
        try {
          final data = doc.data();
          final date = data['date'];
          if (date != null) {
            DateTime entryDate;
            if (date is Timestamp) {
              entryDate = date.toDate();
            } else if (date is DateTime) {
              entryDate = date;
            } else {
              continue;
            }
            
            final entryDateOnly = DateTime(entryDate.year, entryDate.month, entryDate.day);
            if (entryDateOnly.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                entryDateOnly.isBefore(endOfWeek)) {
              batch.delete(doc.reference);
            }
          }
        } catch (e) {
          print('Plan silinirken hata: $e');
        }
      }

      // Yeni planı ekle
      for (final entry in plan) {
        final docRef = _db.collection('meal_entries').doc();
        final data = entry.toMap();
        data['date'] = Timestamp.fromDate(entry.date);
        if (entry.eatenAt != null) {
          data['eatenAt'] = Timestamp.fromDate(entry.eatenAt!);
        }
        batch.set(docRef, data);
      }

      await batch.commit();
    } catch (e) {
      print('Plan Firebase\'e kaydedilemedi: $e');
      rethrow;
    }
  }

  /// Haftalık plan üret (bugünden başlar, 7 gün)
  Future<List<MealEntry>> generateWeeklyPlan() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final info = await _getUserInfo();
    final dietType = info['selectedDietType']?.toString();
    final age = (info['age'] as num?)?.toInt() ?? 25;
    final weight = (info['weight'] as num?)?.toDouble() ?? 70.0;
    final goalCode = _goalCode(dietType);
    
    // Kullanıcı kalorisini Firebase'den oku (kayıt sırasında hesaplanmış olmalı)
    int dailyCalorieNeed = (info['dailyCalorieNeed'] as num?)?.toInt() ?? 
                          (info['calculatedCalories'] as num?)?.toInt() ?? 0;
    
    // Eğer kalori yoksa varsayılan değer kullan
    if (dailyCalorieNeed == 0) {
      print('⚠️ Kullanıcı kalori bilgisi bulunamadı, varsayılan 1500 kcal kullanılıyor');
      dailyCalorieNeed = 1500;
    }

    final mealTypes = ['Kahvaltı', 'Öğle Yemeği', 'Akşam Yemeği', 'Ara Öğün 1', 'Ara Öğün 2'];
    final now = DateTime.now();

    final List<MealEntry> plan = [];
    
    // Firebase'den kullanıcının kalori ihtiyacına göre uygun plan şablonlarını al
    final weeklyMealPlans = await _getPlansFromFirebase(dailyCalorieNeed);
    bool useTemplatePlans = weeklyMealPlans.isNotEmpty;
    
    final breakfast = await _buildCandidatePool('Kahvaltı', dietType);
    final lunch = await _buildCandidatePool('Öğle Yemeği', dietType);
    final dinner = await _buildCandidatePool('Akşam Yemeği', dietType);
    final snacks = await _buildCandidatePool('Ara Öğün', dietType);

    List<Map<String, dynamic>> all = [];
    if (breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty && snacks.isEmpty) {
      final q = await _db.collection('recipes').limit(100).get();
      all = q.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    }

    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final originalPools = {
      'Kahvaltı': breakfast,
      'Öğle Yemeği': lunch,
      'Akşam Yemeği': dinner,
      'Ara Öğün': snacks,
    };
    final workingPools = {
      for (final entry in originalPools.entries)
        entry.key: List<Map<String, dynamic>>.from(entry.value)
    };

    int _readInt(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        final v = src[k];
        if (v == null) continue;
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final p = int.tryParse(v);
          if (p != null) return p;
          final d = double.tryParse(v);
          if (d != null) return d.toInt();
        }
      }
      return 0;
    }

    double _readDouble(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        final v = src[k];
        if (v == null) continue;
        if (v is double) return v;
        if (v is num) return v.toDouble();
        if (v is String) {
          final d = double.tryParse(v);
          if (d != null) return d;
        }
      }
      return 0.0;
    }

    String _readString(Map<String, dynamic> src, List<String> keys, String fallback) {
      for (final k in keys) {
        final v = src[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return fallback;
    }

    for (int d = 0; d < 7; d++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: d));
      
      // Şablon planları kullan
      if (useTemplatePlans && d < weeklyMealPlans.length) {
        final dayPlan = weeklyMealPlans[d];
        for (final mt in mealTypes) {
          String? mealKey;
          if (mt == 'Ara Öğün 1') {
            mealKey = 'Ara Öğün 1';
          } else if (mt == 'Ara Öğün 2') {
            mealKey = 'Ara Öğün 2';
          } else {
            mealKey = mt;
          }
          
          final mealData = dayPlan[mealKey];
          
          if (mealData != null) {
            final mealCalories = int.tryParse(mealData['calories'] ?? '0') ?? 0;
            final mealName = mealData['name'] ?? mt;
            final mealDescription = mealData['description'] ?? '';
            
            // Örnek menüyü Firebase'e tarif olarak kaydet
            final recipeId = await _saveExampleMealAsRecipe(mealName, mealDescription, mealCalories, mt);
            
            plan.add(MealEntry(
              id: '',
              userId: user.uid,
              date: day,
              mealType: mt,
              foodName: mealName,
              calories: mealCalories,
              protein: 0,
              carbs: 0,
              fat: 0,
              isEaten: false,
              recipeId: recipeId,
              description: mealDescription.isNotEmpty ? mealDescription : mealName, // Description boşsa mealName kullan
            ));
          }
        }
        continue;
      }
      
      // Normal plan oluşturma (örnek menüler yoksa veya kalori aralığı uygun değilse)
      for (final mt in mealTypes) {
        final poolKey = mt.contains('Ara') ? 'Ara Öğün' : mt;
        var candidates = workingPools[poolKey] ?? [];
        if (candidates.isEmpty) {
          candidates = List<Map<String, dynamic>>.from(originalPools[poolKey] ?? []);
          workingPools[poolKey] = candidates;
        }
        if (candidates.isEmpty) candidates = all;
        if (candidates.isEmpty) continue;

        // Kural tabanlı kategori seçimi
        final mealCode = _mealCode(mt);
        final recommendedCat = _getMealCategory(
          age: age,
          weight: weight,
          goalCode: goalCode,
          mealCode: mealCode,
        );

        var filtered = _filterByCategory(candidates, recommendedCat);
        if (filtered.isEmpty) filtered = candidates; // fallback

        final pickIndex = random.nextInt(filtered.length);
        final pick = Map<String, dynamic>.from(filtered.removeAt(pickIndex));
        final calories = _readInt(pick, ['caloriesPerServing', 'calories', 'kcal']);
        final protein = _readDouble(pick, ['proteinPerServing', 'protein']);
        final carbs = _readDouble(pick, ['carbsPerServing', 'carbs']);
        final fat = _readDouble(pick, ['fatPerServing', 'fat']);
        final chosenCalories = calories == 0
            ? (mt.contains('Ara') ? 200 : (mt == 'Kahvaltı' ? 350 : 500))
            : calories;

        String description = _readString(pick, ['description'], '');
        String foodName = _readString(pick, ['name', 'title'], mt);

        // Eğer foodName sadece sayı veya geçersizse, mealType kullan
        if (RegExp(r'^\d+$').hasMatch(foodName.trim()) || 
            foodName.trim().isEmpty ||
            foodName.contains('diğerleri')) {
          foodName = mt;
        }

        final customComponents = (pick['customComponents'] as List?)?.map((e) => e.toString()).toList() ?? [];
        if (customComponents.isNotEmpty) {
          // Geçerli malzemeleri filtrele (sadece sayı olanları çıkar)
          final validComponents = customComponents.where((c) {
            final cleaned = c.trim();
            if (cleaned.isEmpty) return false;
            if (RegExp(r'^\d+$').hasMatch(cleaned)) return false; // Sadece sayı
            if (RegExp(r'^\d+\s*kcal$', caseSensitive: false).hasMatch(cleaned)) return false; // Sadece kalori
            return true;
          }).toList();

          if (validComponents.isNotEmpty) {
            final perItem = max(1, (chosenCalories / validComponents.length).round());
            description = validComponents.map((c) {
              // Malzeme adını temizle (kalori bilgisini çıkar)
              String cleanName = c.replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '');
              cleanName = cleanName.replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '');
              cleanName = cleanName.replaceAll(RegExp(r'≈|~|:'), '').trim();
              return '$cleanName: $perItem kcal';
            }).join('\n');
            
            // İlk geçerli malzemeden anlamlı bir isim oluştur
            if (validComponents.length > 1) {
              String firstComponent = validComponents.first
                  .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
                  .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
                  .replaceAll(RegExp(r'≈|~|:'), '')
                  .trim();
              if (firstComponent.isNotEmpty && !RegExp(r'^\d+$').hasMatch(firstComponent)) {
                foodName = firstComponent.length > 30 
                    ? '${firstComponent.substring(0, 30)}...' 
                    : firstComponent;
              }
            } else if (validComponents.length == 1) {
              String singleComponent = validComponents.first
                  .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
                  .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
                  .replaceAll(RegExp(r'≈|~|:'), '')
                  .trim();
              if (singleComponent.isNotEmpty && !RegExp(r'^\d+$').hasMatch(singleComponent)) {
                foodName = singleComponent.length > 40 
                    ? '${singleComponent.substring(0, 40)}...' 
                    : singleComponent;
              }
            }
          }
        }

        // RecipeId'yi al, eğer yoksa ve description varsa tarif oluştur
        String recipeId = _readString(pick, ['id'], '');
        if (recipeId.isEmpty && description.isNotEmpty) {
          // Description'dan tarif oluştur
          recipeId = await _saveExampleMealAsRecipe(foodName, description, chosenCalories, mt);
        }
        
        plan.add(MealEntry(
          id: '',
          userId: user.uid,
          date: day,
          mealType: mt,
          foodName: foodName,
          calories: chosenCalories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          isEaten: false,
          recipeId: recipeId,
          description: description.isNotEmpty ? description : foodName, // Description boşsa foodName kullan
        ));
      }
    }
    return plan;
  }

  Future<void> savePlan(List<MealEntry> entries) async {
    // saveWeeklyPlanToFirebase fonksiyonunu kullan
    await saveWeeklyPlanToFirebase(entries);
  }

  /// Haftalık plan için alışveriş listesi oluştur
  /// MealEntry listesinden malzemeleri çıkarıp gruplar ve miktarları toplar
  Map<String, int> generateShoppingList(List<MealEntry> weeklyPlan) {
    final Map<String, int> shoppingList = {};
    
    for (final entry in weeklyPlan) {
      final description = entry.description;
      if (description.isEmpty) continue;
      
      // Description'dan satırları ayır
      final lines = description.split('\n');
      
      for (final line in lines) {
        final cleaned = line.trim();
        if (cleaned.isEmpty) continue;
        
        // Malzeme adını ve miktarını parse et
        final ingredient = _parseIngredient(cleaned);
        if (ingredient == null) continue;
        
        final name = ingredient['name'] as String;
        final quantity = ingredient['quantity'] as int;
        
        // Benzer malzemeleri normalize et (örn: "Yumurta" ve "Haşlanmış Yumurta" -> "Yumurta")
        final normalizedName = _normalizeIngredientName(name);
        
        // Listeye ekle veya miktarı artır
        shoppingList[normalizedName] = (shoppingList[normalizedName] ?? 0) + quantity;
      }
    }
    
    return shoppingList;
  }

  /// Tek bir satırdan malzeme adı ve miktarını parse eder
  /// Örnek: "2 haşlanmış yumurta: 70 kcal" -> {"name": "Haşlanmış Yumurta", "quantity": 2}
  Map<String, dynamic>? _parseIngredient(String line) {
    // Kalori bilgisini temizle
    String cleaned = line
        .replaceAll(RegExp(r'\d+\s*-\s*\d+\s*kcal', caseSensitive: false), '')
        .replaceAll(RegExp(r'\d+\s*kcal', caseSensitive: false), '')
        .replaceAll(RegExp(r'≈|~'), '')
        .trim();
    
    // ":" veya "(" ile ayrılmış kısımları al
    if (cleaned.contains(':')) {
      cleaned = cleaned.split(':').first.trim();
    }
    if (cleaned.contains('(')) {
      cleaned = cleaned.split('(').first.trim();
    }
    
    if (cleaned.isEmpty) return null;
    
    // Sayıyı bul (başta veya içinde)
    int quantity = 1;
    String name = cleaned;
    
    // Başta sayı var mı? (örn: "2 haşlanmış yumurta")
    final leadingNumberMatch = RegExp(r'^(\d+)\s+').firstMatch(cleaned);
    if (leadingNumberMatch != null) {
      quantity = int.tryParse(leadingNumberMatch.group(1) ?? '1') ?? 1;
      name = cleaned.substring(leadingNumberMatch.end).trim();
    } else {
      // İçinde sayı var mı? (örn: "1 dilim ekmek")
      final numberMatch = RegExp(r'\b(\d+)\b').firstMatch(cleaned);
      if (numberMatch != null) {
        quantity = int.tryParse(numberMatch.group(1) ?? '1') ?? 1;
        // Sayıyı çıkar
        name = cleaned.replaceAll(RegExp(r'\b\d+\b'), '').trim();
      }
    }
    
    // Birimleri temizle (dilim, adet, g, kg, ml, vb.)
    name = name
        .replaceAll(RegExp(r'\b\d+\s*(dilim|adet|g|kg|ml|l|YK|yk|çay kaşığı|tatlı kaşığı|kepçe|porsiyon|küçük|orta|büyük|yarım|çeyrek)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Baş harfi büyük yap
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }
    
    if (name.isEmpty) return null;
    
    return {'name': name, 'quantity': quantity};
  }

  /// Malzeme adlarını normalize eder (benzer malzemeleri birleştirir)
  String _normalizeIngredientName(String name) {
    final lower = name.toLowerCase();
    
    // Yumurta çeşitleri
    if (lower.contains('yumurta')) return 'Yumurta';
    
    // Tavuk çeşitleri
    if (lower.contains('tavuk')) return 'Tavuk';
    
    // Balık çeşitleri
    if (lower.contains('balık') || lower.contains('somon') || lower.contains('ton')) {
      return 'Balık';
    }
    
    // Et çeşitleri
    if (lower.contains('köfte') || lower.contains('et')) return 'Et';
    
    // Peynir çeşitleri
    if (lower.contains('peynir')) return 'Peynir';
    
    // Ekmek çeşitleri
    if (lower.contains('ekmek')) {
      if (lower.contains('tam buğday') || lower.contains('tam tahıllı')) {
        return 'Tam Buğday Ekmek';
      } else if (lower.contains('çavdar')) {
        return 'Çavdar Ekmek';
      }
      return 'Ekmek';
    }
    
    // Sebze çeşitleri
    if (lower.contains('domates')) return 'Domates';
    if (lower.contains('salatalık')) return 'Salatalık';
    if (lower.contains('kabak')) return 'Kabak';
    if (lower.contains('enginar')) return 'Enginar';
    if (lower.contains('fasulye')) return 'Taze Fasulye';
    if (lower.contains('karnabahar')) return 'Karnabahar';
    
    // Meyve çeşitleri
    if (lower.contains('elma')) return 'Elma';
    if (lower.contains('muz')) return 'Muz';
    if (lower.contains('portakal')) return 'Portakal';
    if (lower.contains('mandalina')) return 'Mandalina';
    if (lower.contains('armut')) return 'Armut';
    if (lower.contains('ananas')) return 'Ananas';
    
    // Kuruyemiş çeşitleri
    if (lower.contains('badem')) return 'Badem';
    if (lower.contains('fındık')) return 'Fındık';
    if (lower.contains('ceviz')) return 'Ceviz';
    if (lower.contains('zeytin')) return 'Zeytin';
    if (lower.contains('leblebi')) return 'Leblebi';
    
    // Tahıl çeşitleri
    if (lower.contains('yulaf')) return 'Yulaf';
    if (lower.contains('bulgur')) return 'Bulgur';
    if (lower.contains('pirinç')) return 'Pirinç';
    if (lower.contains('kinoa')) return 'Kinoa';
    if (lower.contains('karabuğday')) return 'Karabuğday';
    
    // Baklagiller
    if (lower.contains('nohut')) return 'Nohut';
    if (lower.contains('mercimek')) return 'Mercimek';
    
    // Süt ürünleri
    if (lower.contains('yoğurt')) return 'Yoğurt';
    if (lower.contains('süt')) return 'Süt';
    if (lower.contains('ayran')) return 'Ayran';
    if (lower.contains('cacık')) return 'Cacık';
    
    // Diğer
    if (lower.contains('zeytinyağı')) return 'Zeytinyağı';
    if (lower.contains('yeşillik') || lower.contains('salata')) return 'Yeşillik';
    
    // Normalize edilemeyen malzemeler için orijinal adı döndür
    return name;
  }

  /// Alışveriş listesini formatlanmış string olarak döndürür
  /// Örnek: "3x Yumurta, 2x Tavuk, 1x Tam Buğday Ekmek..."
  String formatShoppingList(Map<String, int> shoppingList) {
    if (shoppingList.isEmpty) {
      return 'Alışveriş listesi boş';
    }
    
    final items = shoppingList.entries
        .map((entry) => '${entry.value}x ${entry.key}')
        .toList();
    
    return items.join(', ');
  }
}