import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    
    await _plugin.initialize(settings);
    
    // Create notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const mealChannel = AndroidNotificationChannel(
      'meal_reminders',
      'Öğün Hatırlatıcıları',
      description: 'Öğün zamanı hatırlatıcıları',
      importance: Importance.high,
    );
    
    const waterChannel = AndroidNotificationChannel(
      'water_reminders',
      'Su Hatırlatıcıları',
      description: 'Su içme hatırlatıcıları',
      importance: Importance.defaultImportance,
    );
    
    const goalChannel = AndroidNotificationChannel(
      'goal_reminders',
      'Hedef Hatırlatıcıları',
      description: 'Günlük hedef hatırlatıcıları',
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mealChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(waterChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(goalChannel);
  }

  // Öğün hatırlatıcıları
  Future<void> scheduleMealReminders({
    required TimeOfDay breakfastTime,
    required TimeOfDay lunchTime,
    required TimeOfDay dinnerTime,
    required TimeOfDay snack1Time,
    required TimeOfDay snack2Time,
  }) async {
    // Kahvaltı
    await _scheduleDailyNotification(
      id: 1,
      title: 'Kahvaltı Zamanı! 🍳',
      body: 'Güne sağlıklı bir başlangıç yapın',
      time: breakfastTime,
      channelId: 'meal_reminders',
    );

    // Ara Öğün 1
    await _scheduleDailyNotification(
      id: 2,
      title: 'Ara Öğün Zamanı! 🍎',
      body: 'Hafif bir atıştırmalık alın',
      time: snack1Time,
      channelId: 'meal_reminders',
    );

    // Öğle Yemeği
    await _scheduleDailyNotification(
      id: 3,
      title: 'Öğle Yemeği Zamanı! 🥗',
      body: 'Besleyici bir öğle yemeği yiyin',
      time: lunchTime,
      channelId: 'meal_reminders',
    );

    // Ara Öğün 2
    await _scheduleDailyNotification(
      id: 4,
      title: 'Ara Öğün Zamanı! 🥜',
      body: 'Enerjinizi koruyun',
      time: snack2Time,
      channelId: 'meal_reminders',
    );

    // Akşam Yemeği
    await _scheduleDailyNotification(
      id: 5,
      title: 'Akşam Yemeği Zamanı! 🍽️',
      body: 'Günün son öğünü',
      time: dinnerTime,
      channelId: 'meal_reminders',
    );
  }

  // Su hatırlatıcıları
  Future<void> scheduleWaterReminders({
    required int intervalHours,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    int notificationId = 10;
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    final interval = intervalHours * 60;

    for (int minutes = start; minutes <= end; minutes += interval) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      
      await _scheduleDailyNotification(
        id: notificationId++,
        title: 'Su İçme Zamanı! 💧',
        body: 'Hidrasyonunuzu koruyun',
        time: TimeOfDay(hour: hour, minute: minute),
        channelId: 'water_reminders',
      );
    }
  }

  // Günlük hedef hatırlatıcıları
  Future<void> scheduleGoalReminders({
    required TimeOfDay morningTime,
    required TimeOfDay eveningTime,
  }) async {
    // Sabah motivasyon
    await _scheduleDailyNotification(
      id: 20,
      title: 'Günlük Hedefleriniz 📊',
      body: 'Bugünkü kalori ve su hedeflerinizi kontrol edin',
      time: morningTime,
      channelId: 'goal_reminders',
    );

    // Akşam değerlendirme
    await _scheduleDailyNotification(
      id: 21,
      title: 'Günlük Değerlendirme 📈',
      body: 'Bugünkü ilerlemenizi gözden geçirin',
      time: eveningTime,
      channelId: 'goal_reminders',
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required String channelId,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Tüm hatırlatıcıları iptal et
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // Belirli kategorideki hatırlatıcıları iptal et
  Future<void> cancelMealReminders() async {
    for (int i = 1; i <= 5; i++) {
      await _plugin.cancel(i);
    }
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 10; i <= 19; i++) {
      await _plugin.cancel(i);
    }
  }

  Future<void> cancelGoalReminders() async {
    await _plugin.cancel(20);
    await _plugin.cancel(21);
  }

  // Anlık bildirim gönder
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String channelId = 'goal_reminders',
  }) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}