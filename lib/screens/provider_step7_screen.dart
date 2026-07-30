import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'doctor_dashboard_screen.dart';

class ProviderStep7Screen extends StatefulWidget {
  const ProviderStep7Screen({super.key});

  @override
  State<ProviderStep7Screen> createState() => _ProviderStep7ScreenState();
}

class _ProviderStep7ScreenState extends State<ProviderStep7Screen> {
  bool check1 = true;
  bool check2 = true;
  bool check3 = true;
  bool check4 = true;
  bool check5 = true;

  bool _isLoading = false;

  Future<void> _handleCompleteRegistration() async {
    if (!check1 || !check2 || !check3 || !check4 || !check5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept all consent checkboxes to complete registration.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session token missing. Please verify mobile OTP again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await DoctorAuthService.registerConsent(
      token: token,
      informationCorrect: check1,
      validAyushRegistration: check2,
      agreedTelemedicineGuidelines: check3,
      agreedTermsAndConditions: check4,
      digitalVerificationConsent: check5,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );

      AppState().login();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DoctorDashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildConsentItem(
    String title,
    String description,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
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
                      'Please review the following declarations carefully. Your digital signature and consent are required to finalize your medical profile.',
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
                      'Valid AYUSH Registration',
                      'I confirm that I possess valid AYUSH medical registration and authority to practice.',
                      check2,
                      (val) => setState(() => check2 = val ?? false),
                    ),
                    _buildConsentItem(
                      'Telemedicine Guidelines',
                      'I acknowledge and agree to the telemedicine protocols and clinical evaluations.',
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
                      'I consent to the use of digital verification methods to secure my health records and identity.',
                      check5,
                      (val) => setState(() => check5 = val ?? false),
                    ),

                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: _isLoading ? 'Submitting...' : 'Complete Registration',
                      icon: Icons.how_to_reg,
                      onPressed: _isLoading ? () {} : _handleCompleteRegistration,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Registration Summary
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
                      'Review your clinical profile readiness. All systems are ready for submission.',
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
                          _buildSummaryRow('Doctor Account', 'Active'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildNeedHelpCard(context),
              const SizedBox(height: 16),
              _buildMarketplaceBannerCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceBannerCard() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/clinical_marketplace.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/br1.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF144D3F).withValues(alpha: 0.1),
                      const Color(0xFF144D3F).withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Text(
                'Clinically Verified Marketplace',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedHelpCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4EBE5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF144D3F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our medical support team is available 24/7 for any registration queries.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFCCE8E1),
                backgroundImage: AssetImage('assets/d1.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dr. Sarah Mitchell',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'CLINICAL LEAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Connecting to Dr. Sarah Mitchell (Clinical Lead)...'),
                      backgroundColor: const Color(0xFF144D3F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF144D3F),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
