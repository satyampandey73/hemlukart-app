import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step4_screen.dart';

class ProviderStep3Screen extends StatelessWidget {
  const ProviderStep3Screen({super.key});

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
                currentStep: 3,
                totalSteps: 7,
                title: 'Professional',
              ),
              const SizedBox(height: 32),
              const Text(
                'Professional Registration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify your medical credentials to join the marketplace.',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              // Card 1: AYUSH System Credentials
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
                      children: const [
                        Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AYUSH System Credentials',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const CustomTextField(
                      label: 'AYUSH System',
                      hintText: 'Select System',
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'University Name',
                      hintText: 'Enter University',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Year of Passing',
                      hintText: 'YYYY',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Registration Number',
                      hintText: 'Alphanumeric Code',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'State AYUSH Council',
                      hintText: 'Select State Council',
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Other',
                      hintText: 'Enter Your State Council',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Registration Certificate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ), // Should be dashed, keeping solid for simplicity
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.upload_file_outlined,
                            color: AppColors.textLight,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click to upload or drag & drop',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'PDF, JPG, or PNG (Max 5MB)',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(
                          Icons.verified,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Digital signatures are preferred',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Card 2: Highest Qualification
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
                      children: const [
                        Icon(Icons.school_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Highest Qualification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const CustomTextField(
                      label: 'Qualification Type',
                      hintText: 'Select Qualification',
                      suffixIcon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Specialization',
                      hintText: 'e.g. Kayachikitsa',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'University/Institute',
                      hintText: 'Enter University',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Year of Completion',
                      hintText: 'YYYY',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0), // Light slate
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.textDark,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Providing highest qualifications allows you to unlock specialized consulting tiers and pharmaceutical prescription rights within the Wellness Market platform.',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                  // TextButton(
                  //   onPressed: () {},
                  //   child: const Text(
                  //     'Save Draft',
                  //     style: TextStyle(color: AppColors.textLight),
                  //   ),
                  // ),
                  // const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: 'Continue to Step 4',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProviderStep4Screen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
