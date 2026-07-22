import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'provider_step2_screen.dart';

class ProviderStep1Form extends StatelessWidget {
  const ProviderStep1Form({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 1 OF 7',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Mobile Verification',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 4,
                  width: constraints.maxWidth * (1 / 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Verify your mobile number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a secure OTP to verify your account and provide order updates.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),
        const CustomTextField(
          label: 'Mobile Number',
          hintText: '+91 Enter 10 digits',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Send OTP',
          icon: Icons.arrow_forward,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderStep2Screen()),
            );
          },
        ),
        const SizedBox(height: 32),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              style: const TextStyle(color: AppColors.textLight, fontSize: 14),
              children: [
                TextSpan(
                  text: 'Log in',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
