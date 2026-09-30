import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/contact_service.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _whoAreYou = 'Customer';
  bool _isSending = false;
  String? _successMessage;
  String? _errorMessage;

  static const List<String> _whoAreYouOptions = [
    'Customer',
    'Patient',
    'Doctor',
    'Partner',
    'Other',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await ContactService.submitContactForm(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      whoAreYou: _whoAreYou,
      message: _messageController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
      if (result['success'] == true) {
        _successMessage = result['message'] ?? "Thank you for contacting us! We'll get back to you soon.";
        _nameController.clear();
        _emailController.clear();
        _mobileController.clear();
        _messageController.clear();
        _whoAreYou = 'Customer';
        _formKey.currentState?.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Message sent successfully! We will get back to you soon.'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        _errorMessage = result['message'] ?? 'Failed to send message. Please try again.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_errorMessage!),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        260, // Scroll right to the form message area
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'customercare@chikitsakart.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copied to clipboard: customercare@chikitsakart.com'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Subtitle
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Have questions, feedback, or need medical assistance? Our dedicated support team and health concierge are here to help you 24/7.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Get in Touch Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5F7), // Light teal card matching web
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7EBF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Have questions about our services? Our health concierge team is here to help you 24/7',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A6B74),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email inquiry card
                  InkWell(
                    onTap: _copyEmail,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Email Inquiry',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'customercare@chikitsakart.com',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_successMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Name
                    _buildFieldLabel('Name', isRequired: true),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(hintText: 'John Doe'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    _buildFieldLabel('Email Address', isRequired: true),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(hintText: 'john@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number
                    _buildFieldLabel('Mobile Number', isRequired: true),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _inputDecoration(hintText: 'Enter 10-digit mobile number'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                        if (v.trim().length != 10) return 'Must be 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Who Are You?
                    _buildFieldLabel('Who Are You?', isRequired: true),
                    DropdownButtonFormField<String>(
                      initialValue: _whoAreYou,
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: _whoAreYouOptions.map((opt) {
                        return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _whoAreYou = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Message
                    _buildFieldLabel('Message', isRequired: true),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: _inputDecoration(hintText: 'How can we help you today?'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter your message' : null,
                    ),
                    const SizedBox(height: 20),

                    // Send Message Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _handleSendMessage,
                        icon: _isSending
                            ? const SizedBox.shrink()
                            : const Icon(Icons.send_rounded, size: 18),
                        label: _isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Send Message',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
