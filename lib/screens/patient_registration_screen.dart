import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'dashboard_screen.dart';

class PatientRegistrationForm extends StatefulWidget {
  const PatientRegistrationForm({super.key});

  @override
  State<PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends State<PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  String? _serverOtpMessage;
  String? _receivedOtp;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSendingOtp = true;
    });

    final response = await AuthService.sendOtp(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      mobile: _mobileController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSendingOtp = false;
    });

    if (response.success) {
      setState(() {
        _otpSent = true;
        _serverOtpMessage = response.message;
        _receivedOtp = response.otp;
        if (response.otp != null && response.otp!.isNotEmpty) {
          _otpController.text = response.otp!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otpText = _otpController.text.trim();
    if (otpText.isEmpty || otpText.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 4-digit OTP'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    final response = await AuthService.verifyOtpRegister(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      mobile: _mobileController.text.trim(),
      otp: otpText,
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (response.success && response.user != null) {
      if (response.token != null) {
        await AppState().setSession(
          token: response.token!,
          user: response.user!,
        );
      } else {
        AppState().login();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(initialTab: 0),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Full Name',
            hintText: 'e.g. John Doe',
            prefixIcon: Icons.person_outline,
            controller: _fullNameController,
            readOnly: _otpSent,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Email Address',
            hintText: 'john@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            readOnly: _otpSent,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'WhatsApp Number',
            hintText: '9876149210',
            prefixIcon: Icons.chat_bubble_outline,
            keyboardType: TextInputType.phone,
            controller: _whatsappController,
            readOnly: _otpSent,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your WhatsApp number';
              }
              if (val.trim().length < 10) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Mobile Number',
            hintText: '9873543010',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            controller: _mobileController,
            readOnly: _otpSent,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your mobile number';
              }
              if (val.trim().length < 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          if (_otpSent) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _serverOtpMessage ?? 'OTP sent to ${_mobileController.text}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_receivedOtp != null && _receivedOtp!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Text(
                        'Demo OTP Code: $_receivedOtp',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Verification OTP Code',
              hintText: 'Enter 4-digit OTP',
              prefixIcon: Icons.lock_clock_outlined,
              keyboardType: TextInputType.number,
              controller: _otpController,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: _isVerifyingOtp ? 'Verifying OTP...' : 'Verify OTP & Register',
              icon: Icons.check_circle_outline,
              onPressed: _isVerifyingOtp ? () {} : _handleVerifyOtp,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSendingOtp || _isVerifyingOtp
                    ? null
                    : () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        });
                      },
                child: const Text(
                  'Change Details / Resend OTP',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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

          const SizedBox(height: 24),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'By clicking "${_otpSent ? 'Verify OTP & Register' : 'Send OTP'}", you agree to our ',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and\n'),
                  TextSpan(
                    text: 'Privacy Policy.',
                    style: TextStyle(
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
