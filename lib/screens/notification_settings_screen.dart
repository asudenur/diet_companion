import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  // Öğün saatleri
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _snack1Time = const TimeOfDay(hour: 10, minute: 30);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _snack2Time = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  
  // Su hatırlatıcıları
  TimeOfDay _waterStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _waterEndTime = const TimeOfDay(hour: 22, minute: 0);
  int _waterIntervalHours = 2;
  
  // Hedef hatırlatıcıları
  TimeOfDay _morningGoalTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _eveningGoalTime = const TimeOfDay(hour: 21, minute: 0);
  
  // Açık/kapalı durumları
  bool _mealRemindersEnabled = true;
  bool _waterRemindersEnabled = true;
  bool _goalRemindersEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Bildirim Ayarları'),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: _saveSettings,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Öğün Hatırlatıcıları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Öğün Hatırlatıcıları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _mealRemindersEnabled,
                          onChanged: (value) => setState(() => _mealRemindersEnabled = value),
                        ),
                      ],
                    ),
                    if (_mealRemindersEnabled) ...[
                      const SizedBox(height: 16),
                      _buildTimePicker('Kahvaltı', _breakfastTime, (time) => setState(() => _breakfastTime = time)),
                      _buildTimePicker('Ara Öğün 1', _snack1Time, (time) => setState(() => _snack1Time = time)),
                      _buildTimePicker('Öğle Yemeği', _lunchTime, (time) => setState(() => _lunchTime = time)),
                      _buildTimePicker('Ara Öğün 2', _snack2Time, (time) => setState(() => _snack2Time = time)),
                      _buildTimePicker('Akşam Yemeği', _dinnerTime, (time) => setState(() => _dinnerTime = time)),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Su Hatırlatıcıları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Su Hatırlatıcıları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _waterRemindersEnabled,
                          onChanged: (value) => setState(() => _waterRemindersEnabled = value),
                        ),
                      ],
                    ),
                    if (_waterRemindersEnabled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePicker('Başlangıç', _waterStartTime, (time) => setState(() => _waterStartTime = time)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimePicker('Bitiş', _waterEndTime, (time) => setState(() => _waterEndTime = time)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Hatırlatma Aralığı:'),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: _waterIntervalHours,
                            items: [1, 2, 3, 4].map((hour) => DropdownMenuItem(
                              value: hour,
                              child: Text('$hour saat'),
                            )).toList(),
                            onChanged: (value) => setState(() => _waterIntervalHours = value ?? 2),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Hedef Hatırlatıcıları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.track_changes, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Hedef Hatırlatıcıları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: _goalRemindersEnabled,
                          onChanged: (value) => setState(() => _goalRemindersEnabled = value),
                        ),
                      ],
                    ),
                    if (_goalRemindersEnabled) ...[
                      const SizedBox(height: 16),
                      _buildTimePicker('Sabah Motivasyon', _morningGoalTime, (time) => setState(() => _morningGoalTime = time)),
                      _buildTimePicker('Akşam Değerlendirme', _eveningGoalTime, (time) => setState(() => _eveningGoalTime = time)),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Butonları
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test Bildirimleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _notificationService.showInstantNotification(
                              title: 'Test Bildirimi',
                              body: 'Bu bir test bildirimidir',
                            ),
                            icon: const Icon(Icons.notifications),
                            label: const Text('Test Gönder'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _cancelAllNotifications,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Tümünü İptal'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
        );
        if (picked != null) {
          onChanged(TimeOfDay(hour: picked.hour, minute: picked.minute));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
            const Icon(Icons.access_time),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    // Önce tüm hatırlatıcıları iptal et
    await _notificationService.cancelAllNotifications();
    
    // Yeni ayarları uygula
    if (_mealRemindersEnabled) {
      await _notificationService.scheduleMealReminders(
        breakfastTime: _breakfastTime,
        lunchTime: _lunchTime,
        dinnerTime: _dinnerTime,
        snack1Time: _snack1Time,
        snack2Time: _snack2Time,
      );
    }
    
    if (_waterRemindersEnabled) {
      await _notificationService.scheduleWaterReminders(
        intervalHours: _waterIntervalHours,
        startTime: _waterStartTime,
        endTime: _waterEndTime,
      );
    }
    
    if (_goalRemindersEnabled) {
      await _notificationService.scheduleGoalReminders(
        morningTime: _morningGoalTime,
        eveningTime: _eveningGoalTime,
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirim ayarları kaydedildi')),
      );
    }
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler iptal edildi')),
      );
    }
  }
}
