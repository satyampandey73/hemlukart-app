import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step5_screen.dart';

const List<Map<String, String>> areasOfExpertiseOptions = [
  {'value': 'Diabetes', 'label': 'Diabetes'},
  {'value': 'Arthritis', 'label': 'Arthritis'},
  {'value': 'Skin', 'label': 'Skin Diseases'},
  {'value': 'Thyroid', 'label': 'Thyroid Disorders'},
  {'value': 'Digestive Issues', 'label': 'Digestive Issues'},
  {'value': 'Respiratory Problems', 'label': 'Respiratory Problems'},
  {'value': "Women's Health", 'label': "Women's Health"},
  {'value': 'Mental Wellness', 'label': 'Mental Wellness'},
  {'value': 'Pain Management', 'label': 'Pain Management'},
  {'value': 'Weight Management', 'label': 'Weight Management'},
];

const List<Map<String, String>> consultationLanguagesOptions = [
  {'value': 'English', 'label': 'English'},
  {'value': 'Hindi', 'label': 'Hindi'},
  {'value': 'Spanish', 'label': 'Spanish'},
  {'value': 'French', 'label': 'French'},
  {'value': 'Marathi', 'label': 'Marathi'},
  {'value': 'Tamil', 'label': 'Tamil'},
  {'value': 'Telugu', 'label': 'Telugu'},
  {'value': 'Bengali', 'label': 'Bengali'},
  {'value': 'Gujarati', 'label': 'Gujarati'},
  {'value': 'Kannada', 'label': 'Kannada'},
];

class ProviderStep4Screen extends StatefulWidget {
  const ProviderStep4Screen({super.key});

  @override
  State<ProviderStep4Screen> createState() => _ProviderStep4ScreenState();
}

class _ProviderStep4ScreenState extends State<ProviderStep4Screen> {
  final Map<String, bool> expertise = {
    for (var item in areasOfExpertiseOptions) item['value']!: false,
  };

  final Map<String, bool> languages = {
    for (var item in consultationLanguagesOptions) item['value']!: false,
  };

  final TextEditingController _accountHolderController = TextEditingController(
    text: 'Dr. John Doe',
  );
  final TextEditingController _bankNameController = TextEditingController(
    text: 'HDFC Bank',
  );
  final TextEditingController _accountNumberController = TextEditingController(
    text: '123456789012',
  );
  final TextEditingController _ifscCodeController = TextEditingController(
    text: 'HDFC0001234',
  );
  final TextEditingController _panNumberController = TextEditingController(
    text: 'ABCDE1234F',
  );

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default initial selections
    expertise['Diabetes'] = true;
    expertise['Arthritis'] = true;
    expertise['Skin'] = true;

    languages['English'] = true;
    languages['Hindi'] = true;
    languages['Marathi'] = true;
  }

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSaveExpertiseAndBank() async {
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

    final selectedExpertise = areasOfExpertiseOptions
        .where((opt) => expertise[opt['value']] == true)
        .map((opt) => opt['value']!)
        .toList();

    final selectedLanguages = consultationLanguagesOptions
        .where((opt) => languages[opt['value']] == true)
        .map((opt) => opt['value']!)
        .toList();

    // Call Expertise API
    final expertiseRes = await DoctorAuthService.registerExpertise(
      token: token,
      areasOfExpertise: selectedExpertise.isEmpty ? ['Diabetes'] : selectedExpertise,
      consultationLanguages: selectedLanguages.isEmpty ? ['English'] : selectedLanguages,
    );

    if (!expertiseRes.success) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(expertiseRes.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Call Bank Details API
    final bankRes = await DoctorAuthService.registerBank(
      token: token,
      accountHolderName: _accountHolderController.text,
      bankName: _bankNameController.text,
      accountNumber: _accountNumberController.text,
      ifscCode: _ifscCodeController.text,
      panNumber: _panNumberController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (bankRes.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bankRes.message),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderStep5Screen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bankRes.message),
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
                currentStep: 4,
                totalSteps: 7,
                title: 'Expertise & Bank',
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
                      'Expertise & Payout Information',
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
                          'Expertise & Languages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                      spacing: 12,
                      runSpacing: 4,
                      children: areasOfExpertiseOptions.map((item) {
                        final val = item['value']!;
                        final label = item['label']!;
                        return _buildCheckbox(label, expertise[val] ?? false, (isChecked) {
                          setState(() => expertise[val] = isChecked ?? false);
                        });
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
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
                      spacing: 12,
                      runSpacing: 4,
                      children: consultationLanguagesOptions.map((item) {
                        final val = item['value']!;
                        final label = item['label']!;
                        return _buildCheckbox(label, languages[val] ?? false, (isChecked) {
                          setState(() => languages[val] = isChecked ?? false);
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
                    CustomTextField(
                      label: 'Account Holder Name',
                      hintText: 'Full name as per bank records',
                      controller: _accountHolderController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Bank Name',
                      hintText: 'e.g. HDFC Bank',
                      controller: _bankNameController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Account Number',
                      hintText: '123456789012',
                      keyboardType: TextInputType.number,
                      controller: _accountNumberController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'IFSC Code',
                      hintText: 'HDFC0001234',
                      controller: _ifscCodeController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'PAN Number',
                      hintText: 'ABCDE1234F',
                      controller: _panNumberController,
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
                            text: _isLoading ? 'Saving...' : 'Continue',
                            onPressed: _isLoading
                                ? () {}
                                : _handleSaveExpertiseAndBank,
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
