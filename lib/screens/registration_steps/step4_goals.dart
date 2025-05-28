import 'package:flutter/material.dart';
import 'registration_step_base.dart';

class GoalsStep extends StatelessWidget {
  final String? selectedGoal;
  final Function(String) onGoalChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final Widget? footer;

  const GoalsStep({
    Key? key,
    required this.selectedGoal,
    required this.onGoalChanged,
    required this.onNext,
    required this.onBack,
    required this.formKey,
    this.footer,
  }) : super(key: key);

  final List<Map<String, dynamic>> _goals = const [
    {
      'title': 'Kilo vermek',
      'description': 'Sağlıklı bir şekilde kilo vermek istiyorum',
      'icon': Icons.trending_down,
      'color': Color(0xFFE57373), // Kırmızı tonu
    },
    {
      'title': 'Kilo korumak',
      'description': 'Mevcut kilomu korumak istiyorum',
      'icon': Icons.balance,
      'color': Color(0xFF81C784), // Yeşil tonu
    },
    {
      'title': 'Kilo almak',
      'description': 'Sağlıklı bir şekilde kilo almak istiyorum',
      'icon': Icons.trending_up,
      'color': Color(0xFF64B5F6), // Mavi tonu
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RegistrationStepBase(
      currentStep: 4,
      totalSteps: 4,
      onNext: () {
        if (selectedGoal != null) {
          onNext();
        }
      },
      onBack: onBack,
      stepTitle: 'Hedefler',
      formKey: formKey,
      isLastStep: true,
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hedefiniz Nedir?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Size özel bir program oluşturabilmemiz için hedefinizi seçin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ..._goals.map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => onGoalChanged(goal['title']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: selectedGoal == goal['title']
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            goal['color'].withOpacity(0.2),
                            goal['color'].withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: selectedGoal == goal['title']
                      ? null
                      : Colors.grey[50],
                  border: Border.all(
                    color: selectedGoal == goal['title']
                        ? goal['color']
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedGoal == goal['title']
                            ? goal['color']
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        goal['icon'],
                        color: selectedGoal == goal['title']
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
                            goal['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: selectedGoal == goal['title']
                                  ? goal['color']
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal['description'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedGoal == goal['title'])
                      Icon(
                        Icons.check_circle,
                        color: goal['color'],
                      ),
                  ],
                ),
              ),
            ),
          )).toList(),
          if (selectedGoal == null) ...[
            const SizedBox(height: 8),
            Text(
              'Lütfen hedefinizi seçin',
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