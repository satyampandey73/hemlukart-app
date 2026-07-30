import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step6_screen.dart';

class ProviderStep5Screen extends StatefulWidget {
  const ProviderStep5Screen({super.key});

  @override
  State<ProviderStep5Screen> createState() => _ProviderStep5ScreenState();
}

class _ProviderStep5ScreenState extends State<ProviderStep5Screen> {
  final Map<String, PlatformFile?> _selectedFiles = {};
  bool _isLoading = false;

  final TextEditingController _aadhaarNumberController = TextEditingController(
    text: '123456789012',
  );
  final TextEditingController _panCardNumberController = TextEditingController(
    text: 'ABCDE1234F',
  );
  final TextEditingController _medicalRegistrationNumberController = TextEditingController(
    text: 'MCI123456789',
  );
  final TextEditingController _degreeUniversityNumberController = TextEditingController(
    text: 'UNI12345',
  );

  @override
  void dispose() {
    _aadhaarNumberController.dispose();
    _panCardNumberController.dispose();
    _medicalRegistrationNumberController.dispose();
    _degreeUniversityNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(
    String key, {
    List<String>? allowedExtensions,
    bool imageOnly = false,
  }) async {
    try {
      FilePickerResult? result;
      if (imageOnly) {
        result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
      } else if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
          allowMultiple: false,
          withData: true,
        );
      } else {
        result = await FilePicker.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFiles[key] = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeDocument(String key) {
    setState(() {
      _selectedFiles.remove(key);
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleUploadDocuments() async {
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

    final Map<String, String> filePaths = {};
    final Map<String, List<int>> fileBytesMap = {};
    final Map<String, String> fileNamesMap = {};

    _selectedFiles.forEach((key, platformFile) {
      if (platformFile != null) {
        if (platformFile.path != null && platformFile.path!.isNotEmpty) {
          filePaths[key] = platformFile.path!;
        }
        if (platformFile.bytes != null && platformFile.bytes!.isNotEmpty) {
          fileBytesMap[key] = platformFile.bytes!;
        }
        fileNamesMap[key] = platformFile.name;
      }
    });

    final response = await DoctorAuthService.registerDocuments(
      token: token,
      aadhaarNumber: _aadhaarNumberController.text,
      panCardNumber: _panCardNumberController.text,
      medicalRegistrationNumber: _medicalRegistrationNumberController.text,
      degreeUniversityNumber: _degreeUniversityNumberController.text,
      filePaths: filePaths.isNotEmpty ? filePaths : null,
      fileBytesMap: fileBytesMap.isNotEmpty ? fileBytesMap : null,
      fileNamesMap: fileNamesMap.isNotEmpty ? fileNamesMap : null,
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
        MaterialPageRoute(builder: (_) => const ProviderStep6Screen()),
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

  Widget _buildUploadArea(
    String key,
    String title,
    String subtitle,
    IconData icon, {
    List<String>? allowedExtensions,
    bool imageOnly = false,
  }) {
    final selectedFile = _selectedFiles[key];
    final isSelected = selectedFile != null;

    return GestureDetector(
      onTap: () => _pickDocument(
        key,
        allowedExtensions: allowedExtensions,
        imageOnly: imageOnly,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
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
                          selectedFile.name,
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
                              _formatFileSize(selectedFile.size),
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                            if (selectedFile.extension != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  selectedFile.extension!.toUpperCase(),
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
                    icon: const Icon(
                      Icons.close,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _removeDocument(key),
                    tooltip: 'Remove file',
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: AppColors.textDark, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCardHeader(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
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
                currentStep: 5,
                totalSteps: 7,
                title: 'Documents',
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Professional Credentialing',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Please upload high-quality scans of your documents to verify your medical practice and complete your registration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.portrait,
                      'Profile Photo',
                      'Max size: 2MB • JPG/PNG',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(
                      'profilePhoto',
                      'Click to select profile photo',
                      'Ensure clear visibility of face',
                      Icons.cloud_upload_outlined,
                      imageOnly: true,
                    ),
                  ],
                ),
              ),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.school_outlined,
                      'Degree Certificates',
                      'Max size: 5MB • PDF/JPG/PNG',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Degree University / Serial Number',
                      hintText: 'UNI12345',
                      controller: _degreeUniversityNumberController,
                    ),
                    const SizedBox(height: 12),
                    _buildUploadArea(
                      'degreeCertificates',
                      'Upload degree certificate',
                      'MBBS/BAMS/BHMS or higher',
                      Icons.description_outlined,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    ),
                  ],
                ),
              ),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.verified_user_outlined,
                      'Medical Registration',
                      'Max size: 5MB • PDF/JPG/PNG',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Medical Registration Number',
                      hintText: 'MCI123456789',
                      controller: _medicalRegistrationNumberController,
                    ),
                    const SizedBox(height: 12),
                    _buildUploadArea(
                      'registrationCertificate',
                      'Upload Council Certificate',
                      'Must be currently valid',
                      Icons.assignment_turned_in_outlined,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    ),
                  ],
                ),
              ),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.contact_mail_outlined,
                      'Aadhaar Card Verification',
                      'Max size: 5MB each • UIDAI certified',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Aadhaar Number',
                      hintText: '123456789012',
                      keyboardType: TextInputType.number,
                      controller: _aadhaarNumberController,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildUploadArea(
                          'aadhaarFront',
                          'Front Side',
                          'Photo & Name',
                          Icons.credit_card,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        ),

                        const SizedBox(height: 6),

                        _buildUploadArea(
                          'aadhaarBack',
                          'Back Side',
                          'Address details',
                          Icons.credit_card,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.branding_watermark_outlined,
                      'PAN Card',
                      'Max size: 3MB • JPG/PNG/PDF',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'PAN Card Number',
                      hintText: 'ABCDE1234F',
                      controller: _panCardNumberController,
                    ),
                    const SizedBox(height: 12),
                    _buildUploadArea(
                      'panCard',
                      'Upload PAN Scan',
                      'Personal or Practice PAN',
                      Icons.picture_in_picture,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    ),
                  ],
                ),
              ),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(
                      Icons.account_balance_wallet_outlined,
                      'Cancelled Cheque / Passbook',
                      'Max size: 5MB • Required for payout verification',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(
                      'cancelledCheque',
                      'Upload Cheque Scan',
                      'Name and IFSC must be legible',
                      Icons.money,
                      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Previous',
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: _isLoading ? 'Uploading...' : 'Upload & Continue',
                      icon: Icons.arrow_forward,
                      onPressed: _isLoading ? () {} : _handleUploadDocuments,
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

