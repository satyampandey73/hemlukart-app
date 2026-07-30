import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step3_screen.dart';

class ProviderStep2Screen extends StatefulWidget {
  const ProviderStep2Screen({super.key});

  @override
  State<ProviderStep2Screen> createState() => _ProviderStep2ScreenState();
}

class _ProviderStep2ScreenState extends State<ProviderStep2Screen> {
  final TextEditingController _fullNameController = TextEditingController(text: 'Dr. John Doe');
  String _selectedGender = 'male';
  final TextEditingController _dobController = TextEditingController(text: '1990-05-15');
  final TextEditingController _emailController = TextEditingController(text: 'john@example.com');
  final TextEditingController _addressController = TextEditingController(text: '123 Medical Street');
  final TextEditingController _cityController = TextEditingController(text: 'Mumbai');
  final TextEditingController _stateController = TextEditingController(text: 'Maharashtra');
  final TextEditingController _pinCodeController = TextEditingController(text: '400001');

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate =
        DateTime.tryParse(_dobController.text) ?? DateTime(1990, 5, 15);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _handleSavePersonal() async {
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

    final response = await DoctorAuthService.registerPersonal(
      token: token,
      fullName: _fullNameController.text,
      gender: _selectedGender,
      dateOfBirth: _dobController.text,
      email: _emailController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      pinCode: _pinCodeController.text,
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
        MaterialPageRoute(builder: (_) => const ProviderStep3Screen()),
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
                    CustomTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full legal name',
                      controller: _fullNameController,
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
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedGender = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Date of Birth',
                      hintText: 'Select Date of Birth',
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.textLight),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      controller: _dobController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Email Address',
                      hintText: 'john@example.com',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Residential Address',
                      hintText: 'Street name, building number, apartment...',
                      maxLines: 3,
                      controller: _addressController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'City',
                      hintText: 'Enter city',
                      controller: _cityController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'State',
                      hintText: 'Enter state',
                      controller: _stateController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'PIN Code',
                      hintText: '6-digit code',
                      keyboardType: TextInputType.number,
                      controller: _pinCodeController,
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
                            text: _isLoading ? 'Saving...' : 'Save & Continue',
                            onPressed: _isLoading ? () {} : _handleSavePersonal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '© 2026 Wellness Market. Secure and Encrypted Registration.',
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
