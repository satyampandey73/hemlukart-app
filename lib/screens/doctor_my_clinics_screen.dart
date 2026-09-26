import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/clinic_model.dart';
import '../services/clinic_service.dart';
import '../services/doctor_service.dart';
import '../models/doctor_model.dart';

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
      builder: (ctx) => _AddDoctorDialog(clinic: clinic),
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
    final images = clinic.images ?? [];
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
          // Header banner / 1-second auto slider + Status
          Stack(
            children: [
              _ClinicImageSlider(images: images),
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

/// Auto-sliding image carousel for clinic cards with 1-second interval
class _ClinicImageSlider extends StatefulWidget {
  final List<String> images;
  const _ClinicImageSlider({required this.images});

  @override
  State<_ClinicImageSlider> createState() => _ClinicImageSliderState();
}

class _ClinicImageSliderState extends State<_ClinicImageSlider> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  List<String> get _validImages => widget.images
      .where((img) =>
          img.isNotEmpty &&
          (img.startsWith('http://') || img.startsWith('https://')))
      .toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    final imgs = _validImages;
    if (imgs.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      final currentImgs = _validImages;
      if (currentImgs.length <= 1) return;

      if (_pageController.hasClients &&
          _pageController.position.hasContentDimensions) {
        final current =
            (_pageController.page ?? _currentIndex.toDouble()).round();
        final next = (current + 1) % currentImgs.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ClinicImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = _validImages;

    if (imgs.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Center(
          child: Icon(
            Icons.local_hospital_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    if (imgs.length == 1) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imgs.first,
          width: double.infinity,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Center(
              child: Icon(
                Icons.local_hospital_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imgs.length,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
            },
            itemBuilder: (context, index) {
              return Image.network(
                imgs[index],
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(imgs.length, (idx) {
                  final isDotActive = _currentIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isDotActive ? 12 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDotActive ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
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
  // Multi-photo state: min 3, max 7, max 500KB each
  static const int _minPhotos = 3;
  static const int _maxPhotos = 7;
  static const int _maxFileSizeKB = 500;
  final List<String> _existingImageUrls = [];
  final List<String> _selectedImagePaths = [];

  int get _totalPhotosCount => _existingImageUrls.length + _selectedImagePaths.length;

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

    // Load existing uploaded clinic photos if editing
    if (c?.images != null && c!.images!.isNotEmpty) {
      _existingImageUrls.addAll(
        c.images!.where((url) => url.trim().isNotEmpty),
      );
    }
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

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final remaining = _maxPhotos - _totalPhotosCount;
      if (remaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('Maximum 7 photos allowed.'),
          ),
        );
        return;
      }

      final picked = await picker.pickMultiImage(
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked.isEmpty) return;

      final List<String> valid = [];
      final List<String> tooLarge = [];

      for (final xfile in picked) {
        final bytes = await xfile.readAsBytes();
        final sizeKB = bytes.lengthInBytes ~/ 1024;
        if (sizeKB > _maxFileSizeKB) {
          tooLarge.add(xfile.name);
        } else {
          valid.add(xfile.path);
        }
      }

      if (tooLarge.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(
              '${tooLarge.length} photo(s) skipped: each must be ≤ ${_maxFileSizeKB}KB.\n'
              'Skipped: ${tooLarge.join(', ')}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (valid.isEmpty) return;

      // Enforce max
      final List<String> toAdd = valid.take(remaining).toList();
      if (valid.length > remaining && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only $remaining more photo(s) allowed. Added first $remaining.'),
          ),
        );
      }

      setState(() {
        _selectedImagePaths.addAll(toAdd);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick images: $e')),
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Photo count validation: counts both saved old photos and newly added photos
    if (_totalPhotosCount < _minPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(
            'Please keep or upload at least $_minPhotos clinic photos ($_totalPhotosCount/$_minPhotos uploaded).'),
        ),
      );
      return;
    }
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
          existingImages: _existingImageUrls,
          imagePaths: _selectedImagePaths.isNotEmpty ? _selectedImagePaths : null,
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
          imagePaths: _selectedImagePaths.isNotEmpty ? _selectedImagePaths : null,
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

  Widget _buildPhotoGrid() {
    final count = _totalPhotosCount;
    final canAddMore = count < _maxPhotos;
    final hasEnough = count >= _minPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: label + count badge
        Row(
          children: [
            const Text(
              'Clinic Photos *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasEnough
                    ? const Color(0xFF059669).withValues(alpha: 0.12)
                    : const Color(0xFFDC2626).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count / $_maxPhotos',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: hasEnough
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Min $_minPhotos · Max $_maxPhotos · Max ${_maxFileSizeKB}KB per photo',
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 8),

        // Photo strip (horizontal scroll)
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 1. Existing saved photos from backend
              ...List.generate(_existingImageUrls.length, (i) {
                final url = _existingImageUrls[i];
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded,
                                  size: 28, color: AppColors.textLight),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // "Saved" badge
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Saved',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingImage(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 2. Newly picked local photos
              ...List.generate(_selectedImagePaths.length, (i) {
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_selectedImagePaths[i]),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // "New" badge
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Delete button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeSelectedImage(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 3. "Add" / "Add More" cell — shown while under the limit
              if (canAddMore)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasEnough
                            ? const Color(0xFFCBD5E1)
                            : AppColors.primary.withValues(alpha: 0.6),
                        width: hasEnough ? 1 : 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 28,
                          color: hasEnough
                              ? AppColors.textLight
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count == 0 ? 'Add Photos' : 'Add More',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasEnough
                                ? AppColors.textLight
                                : AppColors.primary,
                            fontWeight: hasEnough
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        if (count == 0)
                          Text(
                            '(min $_minPhotos)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Warning if photos added but not enough yet
        if (count > 0 && !hasEnough)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text(
                  'Add ${_minPhotos - count} more photo(s) to proceed.',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
      ],
    );
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

              // ── Multi-photo picker area ──
              _buildPhotoGrid(),

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

// ─────────────────────────────────────────────────────────────────────────────
/// Dialog: Add Doctor to Clinic
/// Shows a tappable doctor selector field + role dropdown + submit button.
// ─────────────────────────────────────────────────────────────────────────────
class _AddDoctorDialog extends StatefulWidget {
  final ApiClinic clinic;
  const _AddDoctorDialog({required this.clinic});

  @override
  State<_AddDoctorDialog> createState() => _AddDoctorDialogState();
}

class _AddDoctorDialogState extends State<_AddDoctorDialog> {
  ApiDoctor? _selectedDoctor;
  String _selectedRole = 'visiting';
  bool _isSubmitting = false;

  /// Opens the doctor picker bottom sheet and awaits the selected doctor.
  Future<void> _openDoctorPicker() async {
    final picked = await showModalBottomSheet<ApiDoctor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DoctorPickerSheet(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDoctor = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }
    final token = AppState().doctorToken;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    final res = await ClinicService.addDoctorToClinic(
      token: token,
      clinicId: widget.clinic.id,
      doctorId: _selectedDoctor!.id,
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
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add Doctor to Clinic',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign a doctor to "${widget.clinic.clinicName}"',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // ── Doctor selector ──
          const Text(
            'Select Doctor *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openDoctorPicker,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDoctor != null
                      ? AppColors.primary
                      : const Color(0xFFCBD5E1),
                ),
                borderRadius: BorderRadius.circular(10),
                color: _selectedDoctor != null
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : null,
              ),
              child: Row(
                children: [
                  if (_selectedDoctor != null) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        _selectedDoctor!.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const Icon(Icons.person_search_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedDoctor != null
                              ? _selectedDoctor!.fullName
                              : '-- Choose a doctor --',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedDoctor != null
                                ? AppColors.textDark
                                : const Color(0xFF94A3B8),
                            fontWeight: _selectedDoctor != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (_selectedDoctor != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Doctor ID: ${_selectedDoctor!.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _selectedDoctor != null
                        ? AppColors.primary
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          // Show selected doctor's specialty below
          if (_selectedDoctor?.ayushSystem != null &&
              _selectedDoctor!.ayushSystem!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                _selectedDoctor!.ayushSystem!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight),
              ),
            ),

          const SizedBox(height: 14),

          // ── Role dropdown ──
          const Text(
            'Role / Designation in Clinic *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Add Doctor',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Bottom Sheet: Doctor Picker
/// Fetches all doctors, lets user search & pick one, then pops with the result.
// ─────────────────────────────────────────────────────────────────────────────
class _DoctorPickerSheet extends StatefulWidget {
  const _DoctorPickerSheet();

  @override
  State<_DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends State<_DoctorPickerSheet> {
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String? _loadError;
  List<ApiDoctor> _allDoctors = [];
  List<ApiDoctor> _filtered = [];
  ApiDoctor? _pending; // highlighted but not yet confirmed

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_allDoctors)
          : _allDoctors.where((d) {
              return d.fullName.toLowerCase().contains(q) ||
                  d.id.toLowerCase().contains(q) ||
                  (d.ayushSystem ?? '').toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final res = await DoctorService.getAllDoctors();
      if (!mounted) return;
      if (res.success) {
        setState(() {
          _allDoctors = res.doctors;
          _filtered = List.from(res.doctors);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadError =
              res.message.isNotEmpty ? res.message : 'Failed to load doctors.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a Doctor',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  if (!_isLoading && _loadError == null)
                    Text(
                      '${_allDoctors.length} doctors available',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),

          // Search
          TextField(
            controller: _searchCtrl,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search by name, ID, or specialty...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search_rounded, size: 20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Doctor list
          SizedBox(
            height: 280,
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFDC2626), size: 32),
                            const SizedBox(height: 8),
                            Text(_loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight)),
                            TextButton(
                              onPressed: _fetchDoctors,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? const Center(
                            child: Text('No doctors found',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textLight)))
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFE2E8F0),
                                indent: 12,
                                endIndent: 12),
                            itemBuilder: (ctx, i) {
                              final doc = _filtered[i];
                              final isHighlighted =
                                  _pending?.id == doc.id;
                              return InkWell(
                                onTap: () {
                                  setState(() => _pending = doc);
                                  // Pop with the selected doctor
                                  Navigator.pop(context, doc);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  color: isHighlighted
                                      ? AppColors.primary
                                          .withValues(alpha: 0.08)
                                      : null,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        child: Text(
                                          doc.fullName.isNotEmpty
                                              ? doc.fullName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc.fullName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isHighlighted
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Doctor ID: ${doc.id}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (doc.ayushSystem != null &&
                                                doc.ayushSystem!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  doc.ayushSystem!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textLight,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isHighlighted)
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}



