import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/clinic_model.dart';
import '../services/clinic_service.dart';

class DoctorMyClinicsScreen extends StatefulWidget {
  const DoctorMyClinicsScreen({super.key});

  @override
  State<DoctorMyClinicsScreen> createState() => _DoctorMyClinicsScreenState();
}

class _DoctorMyClinicsScreenState extends State<DoctorMyClinicsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ApiClinic> _clinics = [];

  @override
  void initState() {
    super.initState();
    _fetchMyClinics();
  }

  Future<void> _fetchMyClinics() async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Doctor session not found. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ClinicService.getMyClinics(token: token);
      if (!mounted) return;

      if (res.success) {
        setState(() {
          _clinics = res.clinics;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = res.message.isNotEmpty
              ? res.message
              : 'Failed to load your clinics.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error fetching clinics: $e';
      });
    }
  }

  Future<void> _deleteClinic(ApiClinic clinic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Delete Clinic', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${clinic.clinicName}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = AppState().doctorToken;
    if (token == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final res = await ClinicService.deleteClinic(
      token: token,
      clinicId: clinic.id,
    );

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF059669),
          content: Text('Clinic deleted successfully.'),
        ),
      );
      _fetchMyClinics();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Failed to delete clinic.'),
        ),
      );
    }
  }

  void _showClinicFormModal({ApiClinic? existingClinic}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClinicFormModal(
        existingClinic: existingClinic,
        onSuccess: () {
          _fetchMyClinics();
        },
      ),
    );
  }

  void _showAddDoctorModal(ApiClinic clinic) {
    showDialog(
      context: context,
      builder: (ctx) => _AddDoctorToClinicDialog(
        clinic: clinic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Clinics & Facilities',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Manage practice locations & staff',
              style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Clinics',
            onPressed: _fetchMyClinics,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClinicFormModal(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
          'Register Clinic',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading your clinics...',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 56, color: Color(0xFFDC2626)),
                        const SizedBox(height: 16),
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 14)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchMyClinics,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                          label: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _clinics.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_hospital_outlined,
                                size: 52,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Clinics Registered Yet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Register your clinics, AYUSH centers, or consultation rooms to link schedules and receive in-person appointments.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showClinicFormModal(),
                              icon: const Icon(Icons.add_rounded,
                                  color: Colors.white),
                              label: const Text('Register New Clinic',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMyClinics,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                        itemCount: _clinics.length,
                        itemBuilder: (context, index) {
                          final clinic = _clinics[index];
                          return _buildClinicCard(clinic);
                        },
                      ),
                    ),
    );
  }

  Widget _buildClinicCard(ApiClinic clinic) {
    final hasImages = clinic.images != null && clinic.images!.isNotEmpty;
    final firstImage = hasImages ? clinic.images!.first : null;
    final isActive = clinic.isActive ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner / image + Status
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: (firstImage != null && firstImage.startsWith('http'))
                      ? DecorationImage(
                          image: NetworkImage(firstImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (firstImage == null || !firstImage.startsWith('http'))
                    ? Center(
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 48,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF059669)
                        : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Clinic Main Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.clinicName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (clinic.registrationNo != null &&
                              clinic.registrationNo!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reg: ${clinic.registrationNo}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address
                if (clinic.address != null && clinic.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFFEA580C)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${clinic.address}${clinic.city != null ? ', ${clinic.city}' : ''}${clinic.state != null ? ', ${clinic.state}' : ''}${clinic.pincode != null ? ' - ${clinic.pincode}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Phone & Email
                Row(
                  children: [
                    if (clinic.phone != null && clinic.phone!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                clinic.phone!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (clinic.email != null && clinic.email!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 14, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                clinic.email!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (clinic.about != null && clinic.about!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      clinic.about!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
                  ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),

                // Action Buttons: Edit, Add Doctor, Delete
                Row(
                  children: [
                    // Edit Clinic
                    OutlinedButton.icon(
                      onPressed: () => _showClinicFormModal(existingClinic: clinic),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add Doctor
                    OutlinedButton.icon(
                      onPressed: () => _showAddDoctorModal(clinic),
                      icon: const Icon(Icons.person_add_outlined, size: 15),
                      label: const Text('Add Doctor',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Spacer(),
                    // Delete Clinic
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: Color(0xFFDC2626)),
                      tooltip: 'Delete Clinic',
                      onPressed: () => _deleteClinic(clinic),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet for Registering or Updating a Clinic
class _ClinicFormModal extends StatefulWidget {
  final ApiClinic? existingClinic;
  final VoidCallback onSuccess;

  const _ClinicFormModal({
    this.existingClinic,
    required this.onSuccess,
  });

  @override
  State<_ClinicFormModal> createState() => _ClinicFormModalState();
}

class _ClinicFormModalState extends State<_ClinicFormModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _regNoCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _aboutCtrl;

  bool _isActive = true;
  bool _isSubmitting = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final c = widget.existingClinic;
    _nameCtrl = TextEditingController(text: c?.clinicName ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _regNoCtrl = TextEditingController(text: c?.registrationNo ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _cityCtrl = TextEditingController(text: c?.city ?? '');
    _stateCtrl = TextEditingController(text: c?.state ?? '');
    _pincodeCtrl = TextEditingController(text: c?.pincode ?? '');
    _aboutCtrl = TextEditingController(text: c?.about ?? '');
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _regNoCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImagePath = picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor session expired. Log in again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isEdit = widget.existingClinic != null;

      ClinicMutationResponse res;
      if (isEdit) {
        res = await ClinicService.updateClinic(
          token: token,
          clinicId: widget.existingClinic!.id,
          clinicName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          pincode: _pincodeCtrl.text.trim(),
          registrationNo: _regNoCtrl.text.trim(),
          about: _aboutCtrl.text.trim(),
          isActive: _isActive,
          imagePaths: _selectedImagePath != null ? [_selectedImagePath!] : null,
        );
      } else {
        res = await ClinicService.createClinic(
          token: token,
          clinicName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          pincode: _pincodeCtrl.text.trim(),
          registrationNo: _regNoCtrl.text.trim(),
          about: _aboutCtrl.text.trim(),
          imagePaths: _selectedImagePath != null ? [_selectedImagePath!] : null,
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(isEdit
                ? 'Clinic updated successfully!'
                : 'Clinic registered successfully!'),
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Failed to save clinic.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingClinic != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Clinic Details' : 'Register New Clinic',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Image Picker Area
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                    image: _selectedImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_selectedImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImagePath == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36, color: AppColors.primary),
                            SizedBox(height: 6),
                            Text(
                              'Tap to upload clinic photo / facade',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // Clinic Name
              _textField(
                controller: _nameCtrl,
                label: 'Clinic Name *',
                hint: 'e.g. AyurVeda Healing Care Clinic',
                icon: Icons.local_hospital_outlined,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter clinic name' : null,
              ),

              const SizedBox(height: 12),

              // Registration No
              _textField(
                controller: _regNoCtrl,
                label: 'Registration / License Number *',
                hint: 'e.g. AYUSH-CL-2024-984',
                icon: Icons.numbers_rounded,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter registration number'
                    : null,
              ),

              const SizedBox(height: 12),

              // Phone & Email
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _phoneCtrl,
                      label: 'Phone *',
                      hint: 'e.g. 9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter phone'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _textField(
                      controller: _emailCtrl,
                      label: 'Email *',
                      hint: 'e.g. clinic@hemlu.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Enter email'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Street Address
              _textField(
                controller: _addressCtrl,
                label: 'Full Address / Landmark *',
                hint: 'e.g. 102 Green Park Main Market',
                icon: Icons.home_outlined,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter address' : null,
              ),

              const SizedBox(height: 12),

              // City, State, Pincode
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: _cityCtrl,
                      label: 'City *',
                      hint: 'e.g. New Delhi',
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'City' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      controller: _stateCtrl,
                      label: 'State *',
                      hint: 'e.g. Delhi',
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'State' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      controller: _pincodeCtrl,
                      label: 'Pincode *',
                      hint: 'e.g. 110016',
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Pin' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // About / Services
              _textField(
                controller: _aboutCtrl,
                label: 'About & Specialized Services (Optional)',
                hint: 'e.g. Panchakarma therapy, Nadi Pariksha, Herbal dispensary',
                maxLines: 2,
              ),

              if (isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Clinic Active Status',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _isActive,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit ? 'Save Changes' : 'Register Clinic',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog to Add Doctor / Staff Doctor to a Clinic
class _AddDoctorToClinicDialog extends StatefulWidget {
  final ApiClinic clinic;

  const _AddDoctorToClinicDialog({required this.clinic});

  @override
  State<_AddDoctorToClinicDialog> createState() =>
      _AddDoctorToClinicDialogState();
}

class _AddDoctorToClinicDialogState extends State<_AddDoctorToClinicDialog> {
  final _doctorIdCtrl = TextEditingController();
  String _selectedRole = 'visiting';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _doctorIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final docId = _doctorIdCtrl.text.trim();
    if (docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Doctor ID')),
      );
      return;
    }

    final token = AppState().doctorToken;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    final res = await ClinicService.addDoctorToClinic(
      token: token,
      clinicId: widget.clinic.id,
      doctorId: docId,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(res['message'] ?? 'Doctor added to clinic successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(res['message'] ?? 'Failed to add doctor to clinic.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.person_add_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Add Doctor to Clinic',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Associate a fellow practitioner or visiting consultant with "${widget.clinic.clinicName}".',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 14),
          const Text('Doctor ID *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _doctorIdCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Doctor MongoDB or Ayush ID',
              prefixIcon: const Icon(Icons.badge_outlined, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Practitioner Role',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'visiting', child: Text('Visiting Consultant')),
                  DropdownMenuItem(
                      value: 'resident', child: Text('Resident Doctor')),
                  DropdownMenuItem(
                      value: 'senior_consultant',
                      child: Text('Senior Consultant')),
                  DropdownMenuItem(
                      value: 'partner', child: Text('Managing Partner')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Add Doctor',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
