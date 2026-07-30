import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'dashboard_screen.dart';
import 'provider_step4_screen.dart';

const List<Map<String, String>> ayushSystemOptions = [
  {'value': 'Ayurveda (BAMS)', 'label': 'Ayurveda (BAMS)'},
  {'value': 'Homeopathy (BHMS)', 'label': 'Homeopathy (BHMS)'},
  {'value': 'Unani (BUMS)', 'label': 'Unani (BUMS)'},
  {'value': 'Siddha (BSMS)', 'label': 'Siddha (BSMS)'},
  {'value': 'Yoga & Naturopathy (BNYS)', 'label': 'Yoga & Naturopathy (BNYS)'},
];

const List<Map<String, String>> qualificationOptions = [
  {'value': 'BAMS', 'label': 'BAMS'},
  {'value': 'BHMS', 'label': 'BHMS'},
  {'value': 'BUMS', 'label': 'BUMS'},
  {'value': 'BSMS', 'label': 'BSMS'},
  {'value': 'BNYS', 'label': 'BNYS'},
  {'value': 'MD (Ayurveda)', 'label': 'MD (Ayurveda)'},
  {'value': 'MS (Ayurveda)', 'label': 'MS (Ayurveda)'},
];

const List<Map<String, String>> stateCouncilOptions = [
  {'value': 'Andhra Pradesh', 'label': 'Andhra Pradesh'},
  {'value': 'Arunachal Pradesh', 'label': 'Arunachal Pradesh'},
  {'value': 'Assam', 'label': 'Assam'},
  {'value': 'Bihar', 'label': 'Bihar'},
  {'value': 'Chhattisgarh', 'label': 'Chhattisgarh'},
  {'value': 'Goa', 'label': 'Goa'},
  {'value': 'Gujarat', 'label': 'Gujarat'},
  {'value': 'Haryana', 'label': 'Haryana'},
  {'value': 'Himachal Pradesh', 'label': 'Himachal Pradesh'},
  {'value': 'Jharkhand', 'label': 'Jharkhand'},
  {'value': 'Karnataka', 'label': 'Karnataka'},
  {'value': 'Kerala', 'label': 'Kerala'},
  {'value': 'Madhya Pradesh', 'label': 'Madhya Pradesh'},
  {'value': 'Maharashtra', 'label': 'Maharashtra'},
  {'value': 'Manipur', 'label': 'Manipur'},
  {'value': 'Meghalaya', 'label': 'Meghalaya'},
  {'value': 'Mizoram', 'label': 'Mizoram'},
  {'value': 'Nagaland', 'label': 'Nagaland'},
  {'value': 'Odisha', 'label': 'Odisha'},
  {'value': 'Punjab', 'label': 'Punjab'},
  {'value': 'Rajasthan', 'label': 'Rajasthan'},
  {'value': 'Sikkim', 'label': 'Sikkim'},
  {'value': 'Tamil Nadu', 'label': 'Tamil Nadu'},
  {'value': 'Telangana', 'label': 'Telangana'},
  {'value': 'Tripura', 'label': 'Tripura'},
  {'value': 'Uttar Pradesh', 'label': 'Uttar Pradesh'},
  {'value': 'Uttarakhand', 'label': 'Uttarakhand'},
  {'value': 'West Bengal', 'label': 'West Bengal'},
  {'value': 'Other', 'label': 'Other'},
];

class ProviderStep3Screen extends StatefulWidget {
  const ProviderStep3Screen({super.key});

  @override
  State<ProviderStep3Screen> createState() => _ProviderStep3ScreenState();
}

class _ProviderStep3ScreenState extends State<ProviderStep3Screen> {
  String _selectedAyushSystem = 'Ayurveda (BAMS)';
  String _selectedQualification = 'BAMS';
  String _selectedStateCouncil = 'Maharashtra';
  final TextEditingController _otherCouncilController = TextEditingController();

  final TextEditingController _gradUnivController = TextEditingController(
    text: 'Ayurvedic University',
  );
  final TextEditingController _gradYearController = TextEditingController(
    text: '2015',
  );
  final TextEditingController _regNumController = TextEditingController(
    text: 'REG123456',
  );

  PlatformFile? _registrationCertFile;

  final TextEditingController _specializationController = TextEditingController(
    text: 'Panchakarma',
  );
  final TextEditingController _highestUnivController = TextEditingController(
    text: 'Ayurvedic University',
  );
  final TextEditingController _highestYearController = TextEditingController(
    text: '2018',
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _otherCouncilController.dispose();
    _gradUnivController.dispose();
    _gradYearController.dispose();
    _regNumController.dispose();
    _specializationController.dispose();
    _highestUnivController.dispose();
    _highestYearController.dispose();
    super.dispose();
  }

  Future<void> _pickRegistrationCertificate() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _registrationCertFile = result.files.first;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking certificate file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleSaveProfessional() async {
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

    final response = await DoctorAuthService.registerProfessional(
      token: token,
      ayushSystem: _selectedAyushSystem,
      gradUniversity: _gradUnivController.text,
      gradYear: _gradYearController.text,
      registrationNumber: _regNumController.text,
      stateAyushCouncil: _selectedStateCouncil,
      otherCouncil: _selectedStateCouncil == 'Other' ? _otherCouncilController.text : '',
      highestDegree: _selectedQualification,
      specialization: _specializationController.text,
      highestUniversity: _highestUnivController.text,
      highestYear: _highestYearController.text,
      certFilePath: _registrationCertFile?.path,
      certFileBytes: _registrationCertFile?.bytes,
      certFileName: _registrationCertFile?.name,
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

      _showEligibilityDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _showEligibilityDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF67E8F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Purchase Eligibility Confirmed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                const Text(
                  'You have become eligible for purchases after validation. If you wish to provide online consultations and unlock professional features, please continue with the registration process.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Continue Registration',
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProviderStep4Screen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Go to Shop',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      AppState().login();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt['value']!,
              child: Text(
                opt['label']!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCertificateUploadArea() {
    final isSelected = _registrationCertFile != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registration Certificate (File Upload)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickRegistrationCertificate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: isSelected
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _registrationCertFile!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _formatFileSize(_registrationCertFile!.size),
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                  ),
                                ),
                                if (_registrationCertFile!.extension != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _registrationCertFile!.extension!.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() {
                            _registrationCertFile = null;
                          });
                        },
                        tooltip: 'Remove file',
                      ),
                    ],
                  )
                : Column(
                    children: const [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.textDark,
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Click to upload Registration Certificate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supported formats: PDF, JPG, PNG (Max size: 5MB)',
                        style: TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
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
                currentStep: 3,
                totalSteps: 7,
                title: 'Professional',
              ),
              const SizedBox(height: 32),
              const Text(
                'Professional Registration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verify your medical credentials to join the marketplace.',
                style: TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),
              // Card 1: AYUSH System Credentials
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
                      children: const [
                        Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AYUSH System Credentials',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDropdown(
                      label: 'AYUSH System',
                      value: _selectedAyushSystem,
                      options: ayushSystemOptions,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedAyushSystem = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'University Name (Graduation)',
                      hintText: 'Enter University',
                      controller: _gradUnivController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Year of Passing',
                      hintText: 'YYYY',
                      keyboardType: TextInputType.number,
                      controller: _gradYearController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Registration Number',
                      hintText: 'Alphanumeric Code',
                      controller: _regNumController,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'State AYUSH Council',
                      value: _selectedStateCouncil,
                      options: stateCouncilOptions,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStateCouncil = val);
                        }
                      },
                    ),
                    if (_selectedStateCouncil == 'Other') ...[
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Other Council Name',
                        hintText: 'Enter council name',
                        controller: _otherCouncilController,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildCertificateUploadArea(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Card 2: Highest Qualification
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
                      children: const [
                        Icon(Icons.school_outlined, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Highest Qualification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDropdown(
                      label: 'Highest Degree',
                      value: _selectedQualification,
                      options: qualificationOptions,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedQualification = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Specialization',
                      hintText: 'e.g. Panchakarma',
                      controller: _specializationController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'University/Institute',
                      hintText: 'Enter University',
                      controller: _highestUnivController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Year of Completion',
                      hintText: 'YYYY',
                      keyboardType: TextInputType.number,
                      controller: _highestYearController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                      text: _isLoading ? 'Saving...' : 'Continue to Step 4',
                      icon: Icons.arrow_forward,
                      onPressed: _isLoading ? () {} : _handleSaveProfessional,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
