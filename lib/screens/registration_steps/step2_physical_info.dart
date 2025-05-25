import 'package:flutter/material.dart';
import 'registration_step_base.dart';

class PhysicalInfoStep extends StatefulWidget {
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController ageController;
  final Function(String) onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final GlobalKey<FormState> formKey;
  final String? selectedGender;

  const PhysicalInfoStep({
    Key? key,
    required this.heightController,
    required this.weightController,
    required this.ageController,
    required this.onGenderChanged,
    required this.onNext,
    required this.onBack,
    required this.formKey,
    this.selectedGender,
  }) : super(key: key);

  @override
  State<PhysicalInfoStep> createState() => _PhysicalInfoStepState();
}

class _PhysicalInfoStepState extends State<PhysicalInfoStep> {
  @override
  Widget build(BuildContext context) {
    return RegistrationStepBase(
      currentStep: 2,
      totalSteps: 4,
      onNext: () {
        if (widget.formKey.currentState!.validate() && widget.selectedGender != null) {
          widget.onNext();
        }
      },
      onBack: widget.onBack,
      stepTitle: 'Fiziksel Bilgiler',
      formKey: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fiziksel Bilgileriniz',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Size özel bir program oluşturabilmemiz için fiziksel bilgilerinizi girin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onGenderChanged('Kadın'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.selectedGender == 'Kadın'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.female,
                            color: widget.selectedGender == 'Kadın' ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kadın',
                            style: TextStyle(
                              color: widget.selectedGender == 'Kadın' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onGenderChanged('Erkek'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: widget.selectedGender == 'Erkek'
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.male,
                            color: widget.selectedGender == 'Erkek' ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erkek',
                            style: TextStyle(
                              color: widget.selectedGender == 'Erkek' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.selectedGender == null) ...[
            const SizedBox(height: 8),
            Text(
              'Lütfen cinsiyet seçin',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: widget.ageController,
            decoration: const InputDecoration(
              labelText: 'Yaş',
              hintText: 'Yaşınızı girin',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen yaşınızı girin';
              }
              final age = int.tryParse(value);
              if (age == null || age < 12 || age > 100) {
                return 'Geçerli bir yaş girin (12-100)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.heightController,
            decoration: const InputDecoration(
              labelText: 'Boy (cm)',
              hintText: 'Boyunuzu girin',
              prefixIcon: Icon(Icons.height_outlined),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen boyunuzu girin';
              }
              final height = double.tryParse(value);
              if (height == null || height < 120 || height > 220) {
                return 'Geçerli bir boy girin (120-220 cm)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.weightController,
            decoration: const InputDecoration(
              labelText: 'Kilo (kg)',
              hintText: 'Kilonuzu girin',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen kilonuzu girin';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 300) {
                return 'Geçerli bir kilo girin (30-300 kg)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
} 