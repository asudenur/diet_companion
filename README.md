# Diet Companion

Kişiselleştirilmiş diyet planlama uygulaması. Her kullanıcı için cinsiyet, boy, kilo, aktivite seviyesi ve hedeflerine göre özelleştirilmiş haftalık diyet planları oluşturur.

## Özellikler

- 🔐 Kullanıcı kaydı ve girişi
- 📊 Otomatik kalori hesaplama (BMR + TDEE)
- 🍽️ Kişiselleştirilmiş haftalık diyet planları
- 📱 Firebase entegrasyonu
- 🎯 Farklı kalori aralıkları için plan şablonları (1200-2200+ kcal)
- 📝 Yemek takibi ve geçmiş
- 🔔 Bildirimler

## Firebase Kurulumu

### 1. Plan Şablonlarını Firebase'e Yükleme

Plan şablonlarını Firebase'e yüklemek için:

1. `lib/main.dart` dosyasını açın
2. Aşağıdaki import'u ekleyin:
   ```dart
   import 'scripts/meal_plan_templates_seeder.dart';
   ```

3. `main()` fonksiyonunda Firebase initialize'dan sonra şunu ekleyin:
   ```dart
   // Plan şablonlarını Firebase'e yükle (sadece ilk çalıştırmada)
   await seedMealPlanTemplates();
   ```

4. Uygulamayı bir kez çalıştırın
5. Planlar yüklendikten sonra bu satırı yorum satırı yapın veya silin

**Not:** Plan şablonları Firebase'de `meal_plan_templates` koleksiyonunda saklanır. Her plan şablonu şu yapıda olmalıdır:

```json
{
  "calorieRange": "1400-1600",
  "dayIndex": 0,
  "meals": {
    "Kahvaltı": {
      "name": "Kahvaltı",
      "description": "...",
      "calories": "350"
    },
    "Ara Öğün 1": {...},
    "Öğle Yemeği": {...},
    "Ara Öğün 2": {...},
    "Akşam Yemeği": {...}
  },
  "createdAt": "timestamp"
}
```

### 2. Firebase Firestore Index (Opsiyonel)

Plan şablonlarını `calorieRange` ve `dayIndex` ile sıralı çekmek için index oluşturmanız gerekmez çünkü kod içinde sıralama yapılıyor. Ancak performans için isteğe bağlı olarak şu index'i oluşturabilirsiniz:

- **Collection:** `meal_plan_templates`
- **Fields:**
  - `calorieRange` (Ascending)
  - `dayIndex` (Ascending)

## Kullanıcı Kalori Hesaplama

Kullanıcı kayıt olduğunda kalori ihtiyacı otomatik olarak hesaplanır ve Firebase'de `user_infos` koleksiyonunda `dailyCalorieNeed` alanına kaydedilir. Plan oluşturulurken bu değer kullanılır, tekrar hesaplama yapılmaz.

## Plan Oluşturma

1. Kullanıcı kayıt olur ve bilgileri girer
2. Sistem kalori ihtiyacını hesaplar ve Firebase'e kaydeder
3. Kullanıcı plan oluştur butonuna basar
4. Sistem kullanıcının kalori ihtiyacına göre uygun plan şablonunu Firebase'den çeker
5. Plan oluşturulur ve Firebase'de `meal_entries` koleksiyonuna kaydedilir

## Kalori Aralıkları

- **1200-1400 kcal:** Düşük kalori (kilo verme)
- **1400-1600 kcal:** Orta-düşük kalori
- **1600-1800 kcal:** Orta kalori
- **1800-2000 kcal:** Orta-yüksek kalori
- **2000-2200 kcal:** Yüksek kalori
- **2200+ kcal:** Çok yüksek kalori (kilo alma/aktif yaşam)

## Geliştirme

### Yeni Plan Şablonu Ekleme

1. `lib/services/plan_service.dart` dosyasındaki `MealPlanTemplates` sınıfına yeni plan şablonları ekleyin
2. `seedMealPlanTemplates()` fonksiyonunu çalıştırın
3. Planlar Firebase'e yüklenecektir

### Plan Şablonunu Güncelleme

Firebase Console'dan `meal_plan_templates` koleksiyonunu düzenleyebilir veya script'i tekrar çalıştırabilirsiniz.

## Teknik Detaylar

- **Kalori Hesaplama:** Mifflin-St Jeor formülü (BMR) + Aktivite çarpanı (TDEE)
- **Veritabanı:** Cloud Firestore
- **Plan Saklama:** `meal_entries` koleksiyonu
- **Plan Şablonları:** `meal_plan_templates` koleksiyonu

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
