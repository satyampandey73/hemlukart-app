import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/step_indicator.dart';
import 'provider_step6_screen.dart';

class ProviderStep5Screen extends StatelessWidget {
  const ProviderStep5Screen({super.key});

  Widget _buildUploadArea(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textDark, size: 28),
          const SizedBox(height: 12),
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
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
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
                      'Click to upload photo',
                      'Ensure clear visibility of face',
                      Icons.cloud_upload_outlined,
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
                      'Max size: 5MB • PDF/JPG',
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: '',
                      hintText: 'Enter University number',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(
                      'Upload all degrees',
                      'MBBS/BAMS/BHMS or higher',
                      Icons.description_outlined,
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
                      'Max size: 5MB • PDF/JPG',
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: '',
                      hintText: 'Enter Medical Registration number',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(
                      'Upload MCI/State Council Cert',
                      'Must be currently valid',
                      Icons.assignment_turned_in_outlined,
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
                      'Max size: 5MB each • Must be 12-digit UIDAI certified',
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: '',
                      hintText: 'Enter Aadhaar Card number manually',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildUploadArea(
                            'Front Side',
                            'Photo & Name visible',
                            Icons.credit_card,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildUploadArea(
                            'Back Side',
                            'Address details visible',
                            Icons.credit_card,
                          ),
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
                      'Max size: 3MB • JPG/PDF',
                    ),
                    const SizedBox(height: 16),
                    const CustomTextField(
                      label: '',
                      hintText: 'Enter PAN Card number manually',
                    ),
                    const SizedBox(height: 16),
                    _buildUploadArea(
                      'Upload PAN Scan',
                      'Personal or Practice PAN',
                      Icons.picture_in_picture,
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
                      'Upload Cheque Scan',
                      'Name and IFSC must be legible',
                      Icons.money,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All documents are processed through secured clinical-grade encryption.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
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
                      text: 'Complete',
                      icon: Icons.arrow_forward,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProviderStep6Screen(),
                          ),
                        );
                      },
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
