import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step5_screen.dart';

class ProviderStep4Screen extends StatefulWidget {
  const ProviderStep4Screen({super.key});

  @override
  State<ProviderStep4Screen> createState() => _ProviderStep4ScreenState();
}

class _ProviderStep4ScreenState extends State<ProviderStep4Screen> {
  final Map<String, bool> expertise = {
    'Diabetes': false,
    'Arthritis': false,
    'Skin': false,
    'Thyroid': false,
  };

  final Map<String, bool> languages = {
    'English': false,
    'Hindi': false,
    'Spanish': false,
    'French': false,
  };

  Widget _buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Text(title, style: const TextStyle(color: AppColors.textDark)),
      ],
    );
  }

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
                currentStep: 4,
                totalSteps: 7,
                title: 'Experience',
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
                      'Professional Profile & Payout',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help us understand your expertise and set up your payment details.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: const [
                        Icon(Icons.work_outline, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Experience & Expertise',
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
                      label: 'Total Experience (Years)',
                      hintText: 'e.g. 10',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Current Designation',
                      hintText: 'e.g. Senior Consultant',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Current Clinic/Hospital Name',
                      hintText: 'e.g. City Wellness Clinic',
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Areas of Expertise (Multi-select)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: expertise.keys.map((key) {
                        return _buildCheckbox(key, expertise[key]!, (val) {
                          setState(() => expertise[key] = val ?? false);
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Consultation Languages',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: languages.keys.map((key) {
                        return _buildCheckbox(key, languages[key]!, (val) {
                          setState(() => languages[key] = val ?? false);
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Icon(
                          Icons.account_balance_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bank & Payout Information',
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
                      label: 'Account Holder Name',
                      hintText: 'Full name as per bank records',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Bank Name',
                      hintText: 'e.g. National Health Bank',
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Account Number',
                      hintText: '9-18 digits',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Numbers only, 9-18 digits required.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'Confirm Account Number',
                      hintText: 'Re-enter account number',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'IFSC Code',
                      hintText: 'E.G. WELL0123456',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '11-character alpha-numeric code.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomTextField(
                      label: 'PAN Number',
                      hintText: 'E.G. ABCDE1234F',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '10-character alpha-numeric ID.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: 'Previous Step',
                            isOutlined: true,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            text:
                                'Complete', // Wait, the image says 'Complete Onboarding' for step 4? The image shows this on step 4. But there are 7 steps total. Let's just follow the button text from the image, but maybe in a real app it's "Continue". We'll use "Continue to Step 5" for logical flow.
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProviderStep5Screen(),
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
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Transfers',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your bank details are encrypted and stored following PCI-DSS compliance standards.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'A penny test transfer will be initiated to verify your account within 24 hours.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
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
