import 'package:flutter/material.dart';

class RegistrationStepBase extends StatelessWidget {
  final Widget child;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String stepTitle;
  final bool isLastStep;
  final GlobalKey<FormState>? formKey;
  final Widget? footer;

  const RegistrationStepBase({
    Key? key,
    required this.child,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    this.onBack,
    required this.stepTitle,
    this.isLastStep = false,
    this.formKey,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (onBack != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: onBack,
                          ),
                        Expanded(
                          child: Text(
                            stepTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: onBack != null ? TextAlign.start : TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: (currentStep - 1) / totalSteps,
                        end: currentStep / totalSteps,
                      ),
                      builder: (context, value, _) => Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adım $currentStep/$totalSteps',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        child,
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onNext,
                            child: Text(isLastStep ? 'Kaydı Tamamla' : 'Devam Et'),
                          ),
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: 16),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 