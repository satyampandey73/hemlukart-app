import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import '../widgets/success_popup.dart';

class ProviderStep2Screen extends StatelessWidget {
  const ProviderStep2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const StepIndicator(
                currentStep: 2,
                totalSteps: 7,
                title: 'Personal',
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
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide your legal details to ensure accurate prescription management and delivery.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CustomTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full legal name',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minimum 3 characters required.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Gender',
                      hintText: 'Select gender',
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Date of Birth',
                      hintText: 'mm/dd/yyyy',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Email Address',
                      hintText: 'name@example.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Residential Address (optional)',
                      hintText: 'Street name, building number, apartment...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '0 / 250',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'City',
                      hintText: 'Search city...',
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'State',
                      hintText: 'Search state...',
                      suffixIcon: Icon(
                        Icons.map_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'PIN Code',
                      hintText: '6-digit code',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Back',
                            isOutlined: true,
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            text: 'Save & Continue',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SuccessPopup(),
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
              const Text(
                '© 2024 Wellness Market. Secure and Encrypted Registration.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
