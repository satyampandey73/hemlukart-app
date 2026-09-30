import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/partner_service.dart';

class PartnerHubDialog extends StatefulWidget {
  const PartnerHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PartnerHubDialog(),
    );
  }

  @override
  State<PartnerHubDialog> createState() => _PartnerHubDialogState();
}

class _PartnerHubDialogState extends State<PartnerHubDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _yourNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _selectedCompanyType;
  String? _selectedState;
  String? _selectedTimeSlot;

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  static const List<String> _companyTypes = [
    "Retail Pharmacy / Medical Store",
    "Pharmaceutical Distributor / Wholesaler",
    "Pharmaceutical Manufacturer / Brand",
    "Hospital / Clinic / Healthcare Centre",
    "Diagnostic Lab / Pathology Center",
    "Ayurvedic / Wellness Center",
    "Healthcare Startup / Corporate Partner",
    "Other",
  ];

  static const List<String> _indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",
  ];

  static const List<String> _timeSlots = [
    "Morning (09:00 AM - 12:00 PM)",
    "Afternoon (12:00 PM - 03:00 PM)",
    "Evening (03:00 PM - 06:00 PM)",
    "Late Evening (06:00 PM - 09:00 PM)",
    "Anytime / Flexible",
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _yourNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyType == null) {
      setState(() => _errorMessage = 'Please select a company type');
      return;
    }
    if (_selectedState == null) {
      setState(() => _errorMessage = 'Please select your state');
      return;
    }
    if (_selectedTimeSlot == null) {
      setState(() => _errorMessage = 'Please select a convenient time to contact');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await PartnerService.submitPartnerRequest(
      companyName: _companyNameController.text.trim(),
      companyType: _selectedCompanyType!,
      yourName: _yourNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      state: _selectedState!,
      city: _cityController.text.trim(),
      convenientTimeToContact: _selectedTimeSlot!,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (result['success'] == true) {
        _isSuccess = true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to submit request';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Title and Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Join Chikitsakart Partner's Hub",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
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

            // Company Name
            _buildFieldLabel('Company Name', isRequired: true),
            TextFormField(
              controller: _companyNameController,
              decoration: _inputDecoration(hintText: 'Your Company Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter company name' : null,
            ),
            const SizedBox(height: 14),

            // Company Type
            _buildFieldLabel('Company Type', isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: _selectedCompanyType,
              hint: const Text('Select Company Type', style: TextStyle(fontSize: 13, color: Colors.black38)),
              isExpanded: true,
              decoration: _inputDecoration(),
              items: _companyTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCompanyType = val),
              validator: (val) => val == null ? 'Please select company type' : null,
            ),
            const SizedBox(height: 14),

            // Your Name
            _buildFieldLabel('Your Name', isRequired: true),
            TextFormField(
              controller: _yourNameController,
              decoration: _inputDecoration(hintText: 'Your Full Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),

            // Email Address
            _buildFieldLabel('Email Address', isRequired: true),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(hintText: 'Enter your email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Phone Number
            _buildFieldLabel('Phone Number', isRequired: true),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _inputDecoration(hintText: 'Enter your mobile no.'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter mobile number';
                      if (v.trim().length != 10) return 'Must be 10 digits';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // State
            _buildFieldLabel('State', isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              hint: const Text('Select State', style: TextStyle(fontSize: 13, color: Colors.black38)),
              isExpanded: true,
              decoration: _inputDecoration(),
              items: _indianStates.map((st) {
                return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) => setState(() => _selectedState = val),
              validator: (val) => val == null ? 'Please select state' : null,
            ),
            const SizedBox(height: 14),

            // City
            _buildFieldLabel('City', isRequired: true),
            TextFormField(
              controller: _cityController,
              decoration: _inputDecoration(hintText: 'Enter your city'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your city' : null,
            ),
            const SizedBox(height: 14),

            // Convenient Time to Contact
            _buildFieldLabel('Convenient Time to Contact', isRequired: true),
            DropdownButtonFormField<String>(
              initialValue: _selectedTimeSlot,
              hint: const Text('Select Time Slot', style: TextStyle(fontSize: 13, color: Colors.black38)),
              isExpanded: true,
              decoration: _inputDecoration(),
              items: _timeSlots.map((ts) {
                return DropdownMenuItem(value: ts, child: Text(ts, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (val) => setState(() => _selectedTimeSlot = val),
              validator: (val) => val == null ? 'Please select time slot' : null,
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Partner Request',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Privacy note
            const Center(
              child: Text(
                'We respect your privacy. Your information will only be used to contact you regarding partnership.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Inquiry Received!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Thank you, ${_yourNameController.text.trim()}. Our business development team will contact you from ${_companyNameController.text.trim()} during your preferred time.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.4),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Time to Contact', _selectedTimeSlot ?? ''),
                const Divider(height: 14),
                _buildSummaryRow('Phone', '+91 ${_phoneController.text.trim()}'),
                const Divider(height: 14),
                _buildSummaryRow('Email', _emailController.text.trim()),
                const Divider(height: 14),
                _buildSummaryRow('Location', '${_cityController.text.trim()}, ${_selectedState ?? ''}'),
              ],
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
      ],
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
