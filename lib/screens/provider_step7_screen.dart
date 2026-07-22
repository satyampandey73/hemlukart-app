import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'dashboard_screen.dart';

class ProviderStep7Screen extends StatefulWidget {
  const ProviderStep7Screen({super.key});

  @override
  State<ProviderStep7Screen> createState() => _ProviderStep7ScreenState();
}

class _ProviderStep7ScreenState extends State<ProviderStep7Screen> {
  bool check1 = false;
  bool check2 = false;
  bool check3 = false;
  bool check4 = false;
  bool check5 = false;

  Widget _buildConsentItem(String title, String description, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
          Row(
            children: [
              Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(width: 4),
              const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 16),
            ],
          ),
        ],
      ),
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
                currentStep: 7,
                totalSteps: 7,
                title: 'Consent',
              ),
              const SizedBox(height: 32),
              
              // Main Form
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
                      'Final Legal Consent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please review the following declarations carefully. Your digital signature and consent are required to finalize your medical profile and access pharmaceutical services.',
                      style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    _buildConsentItem(
                      'Information Correct',
                      'I hereby certify that all information provided during this registration process is accurate, complete, and true to the best of my knowledge.',
                      check1,
                      (val) => setState(() => check1 = val ?? false),
                    ),
                    _buildConsentItem(
                      'Valid Registration',
                      'I confirm that I am of legal age and possess the necessary authority to register for healthcare services on this platform.',
                      check2,
                      (val) => setState(() => check2 = val ?? false),
                    ),
                    _buildConsentItem(
                      'Telemedicine Guidelines',
                      'I acknowledge and agree to the telemedicine protocols, understanding that digital consultations are subject to clinical evaluation and state regulations.',
                      check3,
                      (val) => setState(() => check3 = val ?? false),
                    ),
                    _buildConsentItem(
                      'Terms & Conditions',
                      'I have read, understood, and agree to the comprehensive Terms of Service and Privacy Policy.',
                      check4,
                      (val) => setState(() => check4 = val ?? false),
                    ),
                    _buildConsentItem(
                      'Digital Verification Consent',
                      'I consent to the use of digital verification methods to secure my health records and identity for future pharmaceutical transactions.',
                      check5,
                      (val) => setState(() => check5 = val ?? false),
                    ),

                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Complete Registration',
                      icon: Icons.how_to_reg,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration completed successfully!')),
                        );
                        AppState().login();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Side Panel Equivalent (Registration Summary)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Color(0xFF5EEAD4), shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('Registration Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    const Text(
                      'Review your clinical profile readiness. All systems are green for final approval.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          _buildSummaryRow('Profile Integrity', '100%'),
                          const Divider(height: 1, color: Colors.white),
                          _buildSummaryRow('Documents Verified', 'Yes'),
                          const Divider(height: 1, color: Colors.white),
                          _buildSummaryRow('Pharmacy Account', 'Active'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Need Help section
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
                    const Text('Need Help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Our medical support team is available 24/7 for any registration queries.',
                      style: TextStyle(fontSize: 14, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white), // Placeholder for avatar
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Dr. Sarah Mitchell', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            Text('CLINICAL LEAD', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.message, color: AppColors.primary),
                      ],
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
