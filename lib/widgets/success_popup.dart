import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../widgets/primary_button.dart';
import '../screens/dashboard_screen.dart';
import '../screens/provider_step3_screen.dart';

class SuccessPopup extends StatelessWidget {
  const SuccessPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5), // Light green circle
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: AppColors.secondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Purchase Eligibility Confirmed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You have become eligible for purchases after validation. If you wish to provide online consultations and unlock professional features, please continue with the registration process.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Continue Registration',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProviderStep3Screen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              text: 'Go to Shop',
              isOutlined: true,
              onPressed: () {
                AppState().login();
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DashboardScreen(initialTab: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
