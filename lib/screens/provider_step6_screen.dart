import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step7_screen.dart';

class ProviderStep6Screen extends StatefulWidget {
  const ProviderStep6Screen({super.key});

  @override
  State<ProviderStep6Screen> createState() => _ProviderStep6ScreenState();
}

class _ProviderStep6ScreenState extends State<ProviderStep6Screen> {
  final TextEditingController _aboutController = TextEditingController(
    text:
        'Dr. John Doe is a board-certified Ayurvedic practitioner with over 15 years of experience in treating chronic diseases.',
  );
  final TextEditingController _philosophyController = TextEditingController(
    text:
        'I believe in holistic patient care that prioritizes empathetic listening.',
  );
  final TextEditingController _achievementsController = TextEditingController(
    text: 'Winner of Best Ayurvedic Practitioner Award 2020',
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _aboutController.dispose();
    _philosophyController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session token missing. Please verify mobile OTP again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await DoctorAuthService.registerAbout(
      token: token,
      about: _aboutController.text,
      consultationPhilosophy: _philosophyController.text,
      achievements: _achievementsController.text,
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
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderStep7Screen()),
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

                    const Text(
                      'About Doctor *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '',
                      hintText:
                          'E.g. Dr. John Doe is a board-certified practitioner with extensive experience...',
                      maxLines: 4,
                      controller: _aboutController,
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Consultation Philosophy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '',
                      hintText:
                          'E.g. I believe in holistic patient care that prioritizes empathetic listening...',
                      maxLines: 3,
                      controller: _philosophyController,
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Achievements & Awards',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: '',
                      hintText:
                          'List any medical awards, publications, or significant clinical milestones...',
                      maxLines: 3,
                      controller: _achievementsController,
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
                            text: _isLoading ? 'Saving...' : 'Save',
                            icon: Icons.check_circle_outline,
                            onPressed: _isLoading ? () {} : _handleSaveProfile,
                          ),
                        ),
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
