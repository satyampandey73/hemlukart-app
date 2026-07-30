import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'provider_step2_screen.dart';

class ProviderStep1Form extends StatefulWidget {
  const ProviderStep1Form({super.key});

  @override
  State<ProviderStep1Form> createState() => _ProviderStep1FormState();
}

class _ProviderStep1FormState extends State<ProviderStep1Form> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  String? _serverMessage;
  String? _receivedOtp;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || mobile.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    final response = await DoctorAuthService.sendOtp(mobile: mobile);

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    if (response.success) {
      setState(() {
        _otpSent = true;
        _serverMessage = response.message;
        _receivedOtp = response.otp;
        if (response.otp != null && response.otp!.isNotEmpty) {
          _otpController.text = response.otp!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green.shade700,
        ),
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

  Future<void> _handleVerifyOtp() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final response = await DoctorAuthService.verifyOtp(
      mobile: mobile,
      otp: otp,
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (response.success && response.token != null) {
      await AppState().setDoctorToken(response.token!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProviderStep2Screen()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'STEP 1 OF 7',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Mobile Verification',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 4,
                  width: constraints.maxWidth * (1 / 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Verify your mobile number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a secure OTP to verify your account and process your doctor registration.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Mobile Number',
          hintText: '+91 Enter 10 digits',
          keyboardType: TextInputType.phone,
          controller: _mobileController,
          readOnly: _otpSent,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
        ),
        const SizedBox(height: 16),
        if (_otpSent) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _serverMessage ?? 'OTP Sent successfully',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (_receivedOtp != null && _receivedOtp!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'OTP Code: $_receivedOtp',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Enter OTP Code',
            hintText: 'Enter 6-digit OTP',
            keyboardType: TextInputType.number,
            controller: _otpController,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: _isVerifyingOtp ? 'Verifying OTP...' : 'Verify OTP & Continue',
            icon: Icons.arrow_forward,
            onPressed: _isVerifyingOtp ? () {} : _handleVerifyOtp,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _otpController.clear();
                });
              },
              child: const Text(
                'Change Mobile Number',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ),
        ] else ...[
          PrimaryButton(
            text: _isSendingOtp ? 'Sending OTP...' : 'Send OTP',
            icon: Icons.arrow_forward,
            onPressed: _isSendingOtp ? () {} : _handleSendOtp,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
