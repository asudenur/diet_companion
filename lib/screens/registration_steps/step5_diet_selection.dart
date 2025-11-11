import 'package:flutter/material.dart';
import 'registration_step_base.dart';

class DietSelectionStep extends StatelessWidget {
  final String? selectedDiet;
  final Function(String) onDietChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final Widget? footer;

  const DietSelectionStep({
    Key? key,
    required this.selectedDiet,
    required this.onDietChanged,
    required this.onNext,
    required this.onBack,
    required this.formKey,
    this.footer,
  }) : super(key: key);

  final List<Map<String, dynamic>> _diets = const [
    {
      'title': 'Keto',
      'description': 'Düşük karbonhidrat, yüksek yağ içeren ketojenik diyet',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFFF9800),
      'value': 'Keto',
    },
    {
      'title': 'Aralıklı Oruç',
      'description': 'Belirli zaman dilimlerinde yeme ve oruç tutma döngüsü',
      'icon': Icons.timer,
      'color': Color(0xFF2196F3),
      'value': 'Aralıklı Oruç',
    },
    {
      'title': 'Akdeniz',
      'description': 'Sağlıklı yağlar, taze meyve ve sebzeler içeren dengeli beslenme',
      'icon': Icons.restaurant,
      'color': Color(0xFFE91E63),
      'value': 'Akdeniz',
    },
    {
      'title': 'Su Diyeti',
      'description': 'Belirli periyotlarda su tüketimi ile kilo verme',
      'icon': Icons.water_drop,
      'color': Color(0xFF00BCD4),
      'value': 'Su Diyeti',
    },
    {
      'title': 'Önerdiğimiz Diyet Listesi',
      'description': 'Size özel hazırlanmış dengeli ve sağlıklı beslenme programı',
      'icon': Icons.favorite,
      'color': Color(0xFF4CAF50),
      'value': 'Önerilen Diyet',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return RegistrationStepBase(
      currentStep: 5,
      totalSteps: 5,
      onNext: () {
        if (selectedDiet != null) {
          onNext();
        }
      },
      onBack: onBack,
      stepTitle: 'Diyet Seçimi',
      formKey: formKey,
      isLastStep: true,
      footer: footer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hangi Diyeti Takip Etmek İstiyorsunuz?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Seçtiğiniz diyete göre size özel öğünler hazırlanacak.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ..._diets.map((diet) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => onDietChanged(diet['value']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: selectedDiet == diet['value']
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            diet['color'].withOpacity(0.2),
                            diet['color'].withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: selectedDiet == diet['value']
                      ? null
                      : Colors.grey[50],
                  border: Border.all(
                    color: selectedDiet == diet['value']
                        ? diet['color']
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedDiet == diet['value']
                            ? diet['color']
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        diet['icon'],
                        color: selectedDiet == diet['value']
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
                            diet['title'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: selectedDiet == diet['value']
                                  ? diet['color']
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diet['description'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedDiet == diet['value'])
                      Icon(
                        Icons.check_circle,
                        color: diet['color'],
                      ),
                  ],
                ),
              ),
            ),
          )).toList(),
          if (selectedDiet == null) ...[
            const SizedBox(height: 8),
            Text(
              'Lütfen bir diyet seçin',
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


