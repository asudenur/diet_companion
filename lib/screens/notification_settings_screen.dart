import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_navigation.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isSaving = false;
  
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
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bildirim Ayarları',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white, size: 20),
                label: Text(
                  _isSaving ? 'Kaydediliyor...' : 'Kaydet',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF2E7D32),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  
                  // Öğün Hatırlatıcıları
                  _buildModernCard(
                    icon: Icons.restaurant_rounded,
                    iconColor: const Color(0xFFFF7043),
                    title: 'Öğün Hatırlatıcıları',
                    enabled: _mealRemindersEnabled,
                    onToggle: (value) => setState(() => _mealRemindersEnabled = value),
                    children: _mealRemindersEnabled ? [
                      _buildModernTimePicker('Kahvaltı', Icons.free_breakfast, _breakfastTime, (time) => setState(() => _breakfastTime = time)),
                      _buildModernTimePicker('Ara Öğün 1', Icons.apple, _snack1Time, (time) => setState(() => _snack1Time = time)),
                      _buildModernTimePicker('Öğle Yemeği', Icons.lunch_dining, _lunchTime, (time) => setState(() => _lunchTime = time)),
                      _buildModernTimePicker('Ara Öğün 2', Icons.cookie, _snack2Time, (time) => setState(() => _snack2Time = time)),
                      _buildModernTimePicker('Akşam Yemeği', Icons.dinner_dining, _dinnerTime, (time) => setState(() => _dinnerTime = time)),
                    ] : [],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Su Hatırlatıcıları
                  _buildModernCard(
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF42A5F5),
                    title: 'Su Hatırlatıcıları',
                    enabled: _waterRemindersEnabled,
                    onToggle: (value) => setState(() => _waterRemindersEnabled = value),
                    children: _waterRemindersEnabled ? [
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTimePicker('Başlangıç', Icons.schedule, _waterStartTime, (time) => setState(() => _waterStartTime = time)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildModernTimePicker('Bitiş', Icons.schedule, _waterEndTime, (time) => setState(() => _waterEndTime = time)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildIntervalSelector(),
                    ] : [],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Hedef Hatırlatıcıları
                  _buildModernCard(
                    icon: Icons.track_changes_rounded,
                    iconColor: const Color(0xFFAB47BC),
                    title: 'Hedef Hatırlatıcıları',
                    enabled: _goalRemindersEnabled,
                    onToggle: (value) => setState(() => _goalRemindersEnabled = value),
                    children: _goalRemindersEnabled ? [
                      _buildModernTimePicker('Sabah Motivasyon', Icons.wb_sunny, _morningGoalTime, (time) => setState(() => _morningGoalTime = time)),
                      _buildModernTimePicker('Akşam Değerlendirme', Icons.nightlight_round, _eveningGoalTime, (time) => setState(() => _eveningGoalTime = time)),
                    ] : [],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Test Butonları
                  _buildTestCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool enabled,
    required Function(bool) onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: enabled,
                    onChanged: onToggle,
                    activeColor: iconColor,
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTimePicker(String label, IconData icon, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            onChanged(picked);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.timelapse, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hatırlatma Aralığı',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: _waterIntervalHours,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
              items: [1, 2, 3, 4].map((hour) => DropdownMenuItem(
                value: hour,
                child: Text(
                  '$hour saat',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )).toList(),
              onChanged: (value) => setState(() => _waterIntervalHours = value ?? 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.science_outlined, color: Colors.grey[600], size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Test Bildirimleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.notifications_active,
                    label: 'Test Gönder',
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => _testNotification(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.notifications_off,
                    label: 'Tümünü İptal',
                    color: Colors.red,
                    onPressed: _cancelAllNotifications,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testNotification() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Web tarayıcısında bildirimler sınırlı çalışır'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    try {
      await _notificationService.showInstantNotification(
        title: 'Test Bildirimi 🔔',
        body: 'Bu bir test bildirimidir',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test bildirimi gönderildi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ayarlar kaydedildi! (Web\'de bildirimler sınırlı çalışır)'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
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
          SnackBar(
            content: const Text('Bildirim ayarları kaydedildi! ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _cancelAllNotifications() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Web\'de bildirim iptali desteklenmiyor'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    try {
      await _notificationService.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tüm bildirimler iptal edildi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
