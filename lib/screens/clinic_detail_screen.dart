import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/clinic_model.dart';
import '../services/clinic_service.dart';
import 'doctor_profile_screen.dart';
import 'cart_screen.dart';
import 'book_appointment_screen.dart';
import 'login_screen.dart';
import '../models/doctor_model.dart';

class ClinicDetailScreen extends StatefulWidget {
  final String clinicId;
  final Clinic? initialClinic;
  final ApiClinic? initialApiClinic;

  const ClinicDetailScreen({
    super.key,
    required this.clinicId,
    this.initialClinic,
    this.initialApiClinic,
  });

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  final AppState _appState = AppState();

  ApiClinic? _apiClinic;
  Clinic? _clinicView;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isBookmarked = false;
  int _selectedImageIndex = 0;
  List<ClinicDoctor> _clinicDoctors = [];

  @override
  void initState() {
    super.initState();
    _initInitialData();
    _fetchClinicDetails();
  }

  void _initInitialData() {
    if (widget.initialApiClinic != null) {
      _apiClinic = widget.initialApiClinic;
      _clinicView = Clinic.fromApiClinic(widget.initialApiClinic!);
      _isLoading = false;
    } else if (widget.initialClinic != null) {
      _clinicView = widget.initialClinic;
      _apiClinic = widget.initialClinic?.rawApiClinic;
      _isLoading = false;
    }
  }

  Future<void> _fetchClinicDetails() async {
    if (widget.clinicId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid Clinic ID specified.';
        });
      }
      return;
    }

    if (_clinicView == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final response = await ClinicService.getClinicById(widget.clinicId);

    if (!mounted) return;

    if (response.success && response.clinic != null) {
      setState(() {
        _apiClinic = response.clinic;
        _clinicView = Clinic.fromApiClinic(response.clinic!);
        _clinicDoctors = response.doctors;
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      // If API fails but we had initial clinic data or fallback mock clinic data, use mock/fallback
      if (_clinicView == null) {
        final mockMatch = _appState.mockClinics.firstWhere(
          (c) => c.id == widget.clinicId,
          orElse: () => _appState.mockClinics.first,
        );
        setState(() {
          _clinicView = mockMatch;
          _apiClinic = mockMatch.rawApiClinic;
          _isLoading = false;
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Unable to fetch clinic details from server.';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _clinicName {
    if (_apiClinic != null && _apiClinic!.clinicName.isNotEmpty) {
      return _apiClinic!.clinicName;
    }
    return _clinicView?.name ?? 'Care & Wellness Clinic';
  }

  String get _fullAddress {
    if (_apiClinic != null) {
      final parts = [
        if (_apiClinic!.address != null &&
            _apiClinic!.address!.trim().isNotEmpty)
          _apiClinic!.address!.trim(),
        if (_apiClinic!.city != null && _apiClinic!.city!.trim().isNotEmpty)
          _apiClinic!.city!.trim(),
        if (_apiClinic!.state != null && _apiClinic!.state!.trim().isNotEmpty)
          _apiClinic!.state!.trim(),
        if (_apiClinic!.pincode != null &&
            _apiClinic!.pincode!.trim().isNotEmpty)
          _apiClinic!.pincode!.trim(),
      ];
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return _clinicView?.location ?? 'Main Healthcare Avenue, Wellness District';
  }

  List<String> get _clinicImages {
    if (_apiClinic?.images != null && _apiClinic!.images!.isNotEmpty) {
      final valid = _apiClinic!.images!
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (valid.isNotEmpty) return valid;
    }
    if (_clinicView != null && _clinicView!.image.trim().isNotEmpty) {
      return [_clinicView!.image.trim()];
    }
    return ['assets/clinical_marketplace.jpg'];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _clinicName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked
                        ? 'Saved clinic to your bookmarks'
                        : 'Removed clinic from bookmarks',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _shareClinicDetails,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchClinicDetails,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading Clinic Details...',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _buildContent(isDesktop),
      ),
      // bottomNavigationBar: _clinicView != null ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildContent(bool isDesktop) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1000 : double.infinity,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) _buildNoticeBanner(),

              // Top Image Gallery / Hero Banner
              _buildImageGallerySection(),

              const SizedBox(height: 20),

              // Clinic Main Card
              _buildMainInfoCard(),

              const SizedBox(height: 20),

              // Highlights & Quick Stats Grid
              _buildHighlightsGrid(),

              const SizedBox(height: 20),

              // About & Description Card
              _buildAboutCard(),

              const SizedBox(height: 20),

              // Available Services & Facilities Card
              _buildServicesCard(),

              const SizedBox(height: 20),

              // Contact & Location Detail Card
              _buildContactLocationCard(),

              const SizedBox(height: 20),

              // Associated Doctors Section
              _buildAssociatedDoctorsSection(),

              const SizedBox(height: 20),

              // Patient Reviews Section
              _buildReviewsSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _fetchClinicDetails,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallerySection() {
    final images = _clinicImages;
    final primaryImg = images[_selectedImageIndex % images.length];

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    (primaryImg.startsWith('http://') ||
                        primaryImg.startsWith('https://'))
                    ? Image.network(
                        primaryImg,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(),
                      )
                    : Image.asset(
                        primaryImg.isNotEmpty
                            ? primaryImg
                            : 'assets/clinical_marketplace.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(),
                      ),
              ),
            ),

            // Top Badges Overlay
            Positioned(
              top: 14,
              left: 14,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (_apiClinic?.isActive ?? true)
                          ? const Color(0xFF0F766E)
                          : Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (_apiClinic?.isActive ?? true)
                              ? Icons.verified
                              : Icons.access_time_filled,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (_apiClinic?.isActive ?? true)
                              ? 'VERIFIED CLINIC'
                              : 'TEMPORARILY CLOSED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      _clinicView?.specialty.toUpperCase() ??
                          'AYURVEDA & AYUSH',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Image Counter Overlay
            if (images.length > 1)
              Positioned(
                bottom: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Thumbnail Row if multiple images available
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                final img = images[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child:
                          (img.startsWith('http://') ||
                              img.startsWith('https://'))
                          ? Image.network(img, fit: BoxFit.cover)
                          : Image.asset(img, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/clinical_marketplace.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital_rounded,
                size: 54,
                color: AppColors.primary,
              ),
              SizedBox(height: 8),
              Text(
                'Ayush Certified Healthcare Facility',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    final rating = _clinicView?.rating ?? 4.8;
    final isActive = _apiClinic?.isActive ?? true;
    final phone = _apiClinic?.phone ?? '';
    final email = _apiClinic?.email ?? '';
    final about = _apiClinic?.about ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges: VERIFIED & ACTIVE
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Clinic Title
          Text(
            _clinicName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${rating.toStringAsFixed(1)} (125 reviews)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF0F766E), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fullAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_iphone_outlined, color: Color(0xFF0F766E), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF0F766E), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (about.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Clinic',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    about,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightsGrid() {
    final docsCount = _clinicView?.doctorsCount ?? 8;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.medical_services_outlined,
            title: '$docsCount+ Doctors',
            subtitle: 'Specialist Staff',
            bgColor: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            icon: Icons.access_time_filled,
            title: '9 AM - 8 PM',
            subtitle: 'Mon to Sat',
            bgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            icon: Icons.thumb_up_alt_outlined,
            title: '98% Positive',
            subtitle: 'Patient Rating',
            bgColor: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    final aboutText =
        (_apiClinic?.about != null && _apiClinic!.about!.trim().isNotEmpty)
        ? _apiClinic!.about!.trim()
        : 'Welcome to $_clinicName. Our multi-specialty wellness centre provides authentic Ayush holistic consultations, specialized herbal therapies, advanced diagnostic screening, and personalized care plans tailored for complete physical and mind restoration. Our certified doctors bring years of clinical experience in root-cause healing and natural medicine.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'About Clinic & Vision',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aboutText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    final services =
        _clinicView?.availableServices ??
        [
          'In-Person Consultations',
          'Ayurveda & Panchakarma',
          'Homeopathy Consultation',
          'Unani Herbal Regimens',
          'Diagnostic Testing',
          'Pharmacy & Medicines',
          'Tele-Consultation',
        ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_hospital_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available Treatments & Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactLocationCard() {
    final phone = _apiClinic?.phone ?? '+91 98765 43210';
    final email =
        _apiClinic?.email ??
        'contact@${_clinicName.toLowerCase().replaceAll(' ', '')}.com';
    final city = _apiClinic?.city ?? 'New Delhi';
    final state = _apiClinic?.state ?? 'Delhi';
    final pincode = _apiClinic?.pincode ?? '110001';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.contact_phone_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contact & Support Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildContactTile(
            icon: Icons.phone,
            title: 'Phone Number',
            subtitle: phone,
            onTap: () => _copyToClipboard(phone, 'Phone number copied'),
            actionLabel: 'Call / Copy',
          ),
          const Divider(height: 24),
          _buildContactTile(
            icon: Icons.email_outlined,
            title: 'Email Address',
            subtitle: email,
            onTap: () => _copyToClipboard(email, 'Email copied'),
            actionLabel: 'Copy Email',
          ),
          const Divider(height: 24),
          _buildContactTile(
            icon: Icons.location_city_outlined,
            title: 'City & State',
            subtitle: '$city, $state - $pincode',
            onTap: _openDirections,
            actionLabel: 'Map View',
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required String actionLabel,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Doctor _clinicDoctorToDoctor(ClinicDoctor doc) {
    String formattedName = doc.fullName.trim();
    if (!formattedName.toLowerCase().startsWith('dr.') &&
        !formattedName.toLowerCase().startsWith('dr ')) {
      formattedName = 'Dr. $formattedName';
    }

    return Doctor(
      id: doc.doctorId,
      name: formattedName,
      specialty: (doc.ayushSystem != null && doc.ayushSystem!.isNotEmpty)
          ? doc.ayushSystem!
          : 'Ayurveda (BAMS)',
      degree: (doc.qualifications != null && doc.qualifications!.isNotEmpty)
          ? doc.qualifications!
          : (doc.ayushSystem ?? 'BAMS'),
      system: (doc.ayushSystem != null && doc.ayushSystem!.isNotEmpty)
          ? doc.ayushSystem!
          : 'Ayurveda',
      experienceYears: doc.experience ?? 0,
      consultationFee: 500,
      rating: 4.8,
      reviewsCount: 15,
      image: (doc.profilePhoto != null && doc.profilePhoto!.isNotEmpty)
          ? doc.profilePhoto!
          : 'assets/doctor1.png',
      languages: const ['Hindi', 'English'],
      clinicName: _clinicName,
      clinicAddress: _fullAddress,
      clinicId: widget.clinicId,
      about:
          'Practitioner specializing in ${doc.ayushSystem ?? "holistic healthcare"}.',
      rawApiDoctor: ApiDoctor(
        id: doc.doctorId,
        fullName: doc.fullName,
        mobile: doc.mobile,
        email: doc.email,
        ayushSystem: doc.ayushSystem,
        isActive: doc.isActive,
      ),
    );
  }

  Widget _buildAssociatedDoctorsSection() {
    final docs = _clinicDoctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.supervised_user_circle_rounded,
                color: Color(0xFF0F766E),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Available Doctors (${docs.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (docs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No doctors currently registered in this clinic.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return _buildDoctorCard(doc);
            },
          ),
      ],
    );
  }

  Widget _buildDoctorCard(ClinicDoctor doc) {
    final doctorModel = _clinicDoctorToDoctor(doc);
    final hasPhoto = doc.profilePhoto != null && doc.profilePhoto!.startsWith('http');
    final roleText = doc.role != null && doc.role!.isNotEmpty
        ? (doc.role![0].toUpperCase() + doc.role!.substring(1).toLowerCase())
        : 'Visiting';

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Row
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorProfileScreen(doctor: doctorModel),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  backgroundImage: hasPhoto ? NetworkImage(doc.profilePhoto!) : null,
                  child: !hasPhoto
                      ? Text(
                          doc.fullName.isNotEmpty
                              ? doc.fullName.trim()[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (doc.ayushSystem != null && doc.ayushSystem!.isNotEmpty)
                        Text(
                          doc.ayushSystem!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      const SizedBox(height: 2),
                      if (doc.qualifications != null && doc.qualifications!.isNotEmpty)
                        Text(
                          doc.qualifications!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.experience ?? 0} years experience',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          roleText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Available Timings
          Row(
            children: const [
              Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Available Timings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              (doc.schedules != null && doc.schedules!.isNotEmpty)
                  ? '${doc.schedules!.length} schedule slots configured'
                  : 'No schedules available',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),

          if (!_appState.isDoctorLoggedIn) ...[
            const SizedBox(height: 14),

            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  if (await LoginScreen.checkAndNavigate(context)) {
                    if (!mounted) return;
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => BookAppointmentScreen(doctor: doctorModel),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Book Appointment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.rate_review_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Patient Reviews & Testimonials',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSingleReviewItem(
            name: 'Sunita Sharma',
            date: '2 weeks ago',
            rating: 5.0,
            comment:
                'Exceptional patient care and clean hygiene standards. The doctor spent over 30 minutes explaining the holistic healing regimen.',
          ),
          const Divider(height: 20),
          _buildSingleReviewItem(
            name: 'Rajesh Verma',
            date: '1 month ago',
            rating: 4.5,
            comment:
                'Smooth appointment booking and quick registration process. Highly recommended for authentic Ayush therapies.',
          ),
        ],
      ),
    );
  }

  Widget _buildSingleReviewItem({
    required String name,
    required String date,
    required double rating,
    required String comment,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < rating.floor() ? Icons.star : Icons.star_half,
              color: Colors.amber,
              size: 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          comment,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textDark,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /*
  // Bottom action bar (Call Clinic & Book Appointment buttons) - commented out / hidden as requested
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: _appState.isDoctorLoggedIn ? 1 : 2,
              child: OutlinedButton.icon(
                onPressed: () {
                  final phone = _apiClinic?.phone ?? '+919876543210';
                  _copyToClipboard(phone, 'Clinic Contact: $phone');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.call,
                  color: AppColors.primary,
                  size: 18,
                ),
                label: const Text(
                  'Call Clinic',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!_appState.isDoctorLoggedIn) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await LoginScreen.checkAndNavigate(context)) {
                      if (!mounted) return;
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => DoctorListingScreen(
                            systemFilter: _clinicView?.specialty,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Book Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  */

  void _shareClinicDetails() {
    final shareMsg =
        'Check out $_clinicName on Chikitsakart App! Address: $_fullAddress';
    _copyToClipboard(shareMsg, 'Clinic details copied to clipboard');
  }

  void _openDirections() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening maps for $_fullAddress'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMsg), duration: const Duration(seconds: 2)),
    );
  }
}