import 'package:flutter/material.dart';
import 'registration_step_base.dart';

class ActivityLevelStep extends StatelessWidget {
  final String? selectedActivityLevel;
  final Function(String) onActivityLevelChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;

  const ActivityLevelStep({
    Key? key,
    required this.selectedActivityLevel,
    required this.onActivityLevelChanged,
    required this.onNext,
    required this.onBack,
    required this.formKey,
  }) : super(key: key);

  final List<Map<String, dynamic>> _activityLevels = const [
    {
      'title': 'Çok az hareketli',
      'description': 'Gün boyu oturuyorsanız veya çok az hareket ediyorsanız',
      'icon': Icons.weekend_outlined,
    },
    {
      'title': 'Hafif aktif',
      'description': 'Hafif yürüyüş, günlük hareket ya da haftada 1–3 gün antrenman yapıyorsanız',
      'icon': Icons.directions_walk_outlined,
    },
    {
      'title': 'Orta aktif',
      'description': 'Haftada 3–5 gün antrenman yapıyorsanız',
      'icon': Icons.directions_run_outlined,
    },
    {
      'title': 'Çok aktif',
      'description': 'Ağır egzersiz yapıyor veya fiziksel bir işte çalışıyorsanız',
      'icon': Icons.fitness_center_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RegistrationStepBase(
      currentStep: 3,
      totalSteps: 4,
      onNext: () {
        if (selectedActivityLevel != null) {
          onNext();
        }
      },
      onBack: onBack,
      stepTitle: 'Aktivite Seviyesi',
      formKey: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ne Kadar Aktifsiniz?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Size uygun kalori hedefi belirleyebilmemiz için aktivite seviyenizi seçin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ..._activityLevels.map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => onActivityLevelChanged(level['title']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: selectedActivityLevel == level['title']
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey[50],
                  border: Border.all(
                    color: selectedActivityLevel == level['title']
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedActivityLevel == level['title']
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        level['icon'],
                        color: selectedActivityLevel == level['title']
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: selectedActivityLevel == level['title']
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level['description'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedActivityLevel == level['title'])
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          )).toList(),
          if (selectedActivityLevel == null) ...[
            const SizedBox(height: 8),
            Text(
              'Lütfen aktivite seviyenizi seçin',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 