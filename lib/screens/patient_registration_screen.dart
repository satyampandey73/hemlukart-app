import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/success_popup.dart';
import 'dashboard_screen.dart';

class PatientRegistrationForm extends StatelessWidget {
  const PatientRegistrationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomTextField(
          label: 'Full Name',
          hintText: 'e.g. John Doe',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        const CustomTextField(
          label: 'Email Address',
          hintText: 'john@example.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        const CustomTextField(
          label: 'Whats App',
          hintText: 'Enter WhatsApp Number',
          prefixIcon: Icons.chat_bubble_outline,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        const CustomTextField(
          label: 'Mobile Number',
          hintText: '+1 (555) 000-0000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Send OTP',
          icon: Icons.arrow_forward,
          onPressed: () {
            AppState().login();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardScreen(initialTab: 0),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: Text.rich(
            TextSpan(
              text: 'By clicking "Send OTP", you agree to our ',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' and\n'),
                TextSpan(
                  text: 'Privacy Policy.',
                  style: TextStyle(
                    color: AppColors.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
