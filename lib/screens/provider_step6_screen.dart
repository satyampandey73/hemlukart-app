import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step7_screen.dart';

class ProviderStep6Screen extends StatelessWidget {
  const ProviderStep6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const StepIndicator(
                currentStep: 6,
                totalSteps: 7,
                title: 'Professional Profile',
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Professional Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Icon(
                          Icons.business_center,
                          color: AppColors.border.withValues(alpha: 0.5),
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tell your future patients about your clinical experience and healthcare philosophy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text.rich(
                          TextSpan(
                            text: 'About Doctor ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '0 / 1000 chars',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const CustomTextField(
                      label: '',
                      hintText:
                          'E.g. Dr. Jane Smith is a board-certified Cardiologist with over 15 years of experience in preventative heart care...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.textLight,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Focus on your specialization, education, and patient care history.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Consultation Philosophy ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '0 / 500 chars',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const CustomTextField(
                      label: '',
                      hintText:
                          'E.g. I believe in holistic patient care that prioritizes empathetic listening and shared decision-making...',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Achievements & Awards ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '0 / 500 chars',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const CustomTextField(
                      label: '',
                      hintText:
                          'List any medical awards, publications, or significant clinical milestones...',
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Previous',
                            isOutlined: true,
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: PrimaryButton(
                            text: 'Save',
                            icon: Icons.check_circle_outline,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProviderStep7Screen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Your professional profile helps patients understand your expertise and care approach. A detailed profile increases booking rates by 40%.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
