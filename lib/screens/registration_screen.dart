import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'patient_registration_screen.dart';
import 'provider_step1_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final bool initialIsPatient;
  const RegistrationScreen({super.key, this.initialIsPatient = true});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late bool isPatient;

  @override
  void initState() {
    super.initState();
    isPatient = widget.initialIsPatient;
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
              // const SizedBox(height: 40),
              const Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please fill in the details to register.',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
              const SizedBox(height: 32),
              // Custom Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isPatient = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isPatient
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(7),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              color: isPatient
                                  ? Colors.white
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isPatient = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !isPatient
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(7),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Healthcare Provider',
                            style: TextStyle(
                              color: !isPatient
                                  ? Colors.white
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Body
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: isPatient
                    ? const PatientRegistrationForm()
                    : const ProviderStep1Form(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
