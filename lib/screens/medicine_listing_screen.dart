import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hemlukart_app/screens/doctor_listing_screen.dart';
import 'clinic_listing_screen.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'product_detail_screen.dart';
import 'product_catalog_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'my_prescriptions_screen.dart';
import 'my_orders_screen.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../widgets/product_quantity_selector.dart';
import '../services/doctor_service.dart';
import '../models/testimonial_model.dart';
import '../services/testimonial_service.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

class MedicineListingScreen extends StatefulWidget {
  const MedicineListingScreen({super.key});

  @override
  State<MedicineListingScreen> createState() => _MedicineListingScreenState();
}

class _MedicineListingScreenState extends State<MedicineListingScreen> {
  final AppState _appState = AppState();
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<BannerModel> _medicineBanners = [];
  bool _isLoadingMedicineBanners = false;

  List<BannerModel> _medicineBanner1 = [];
  bool _isLoadingMedicineBanner1 = false;

  List<CategoryModel> _apiCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryError;

  final List<Map<String, dynamic>> _healthConcerns = [
    {
      'name': 'Diabetes',
      'icon': Icons.water_drop_outlined,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Heart Care',
      'icon': Icons.favorite_outline,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Stomach Care',
      'icon': Icons.healing_outlined,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Muscle Pain',
      'icon': Icons.fitness_center_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Liver Care',
      'icon': Icons.shield_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Kidney Care',
      'icon': Icons.clean_hands_outlined,
      'color': const Color(0xFF06B6D4),
    },
    {
      'name': 'Respiratory',
      'icon': Icons.air_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Skin Care',
      'icon': Icons.face_outlined,
      'color': const Color(0xFFF43F5E),
    },
    {
      'name': 'Hair Care',
      'icon': Icons.cut_outlined,
      'color': const Color(0xFF6366F1),
    },
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {
      'id': 'book_appointment',
      'name': 'Book\nAppointment',
      'icon': Icons.calendar_month_outlined,
      'color': const Color(0xFF7C3AED),
    },
    {
      'id': 'consult_doctor',
      'name': 'Consult\nDoctor',
      'icon': Icons.medical_services_outlined,
      'color': const Color(0xFF2563EB),
    },
    {
      'id': 'find_clinic',
      'name': 'Find\nClinic',
      'icon': Icons.local_hospital_outlined,
      'color': const Color(0xFF059669),
    },
    {
      'id': 'view_prescription',
      'name': 'View\nPrescription',
      'icon': Icons.description_outlined,
      'color': const Color(0xFF0D9488),
    },
    {
      'id': 'order_history',
      'name': 'Order\nHistory',
      'icon': Icons.receipt_long_outlined,
      'color': const Color(0xFFD97706),
    },
    {
      'id': 'lab_tests',
      'name': 'Lab\nTests',
      'icon': Icons.science_outlined,
      'color': const Color(0xFFDB2777),
      'isComingSoon': true,
    },
  ];

  final List<Map<String, String>> _brands = [
    {'name': 'Dabur', 'image': 'assets/d1.png'},
    {'name': 'Baidyanath', 'image': 'assets/d2.png'},
    {'name': 'Himalaya Wellness', 'image': 'assets/d3.png'},
    {'name': 'Patanjali', 'image': 'assets/d4.png'},
    {'name': 'Kerala Ayurveda', 'image': 'assets/d5.png'},
    {'name': 'Zandu', 'image': 'assets/d6.png'},
    {'name': 'Maharishi Ayurveda', 'image': 'assets/d7.png'},
    {'name': 'Organic India', 'image': 'assets/d8.png'},
  ];

  List<Doctor> _medicineDoctors = [];
  bool _isLoadingMedicineDoctors = false;

  List<TestimonialModel> _testimonials = [];
  bool _isLoadingTestimonials = false;
  String? _testimonialError;
  final PageController _testimonialController = PageController();
  int _currentTestimonialIndex = 0;
  Timer? _testimonialTimer;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
    _startBannerAutoSlide();
    _fetchMedicineBanners();
    _fetchMedicineBanner1();
    _fetchCategories();
    _fetchDoctors();
    _fetchTestimonials();
  }

  Future<void> _fetchDoctors() async {
    if (!mounted) return;
    setState(() => _isLoadingMedicineDoctors = true);

    final response = await DoctorService.getAllDoctors();
    if (!mounted) return;

    if (response.success && response.doctors.isNotEmpty) {
      final initialDocs = response.doctors.map((d) => Doctor.fromApiDoctor(d)).toList();
      setState(() {
        _medicineDoctors = initialDocs;
        _isLoadingMedicineDoctors = false;
      });

      final enriched = await DoctorService.enrichDoctorsWithDetails(response.doctors);
      if (mounted) {
        setState(() {
          _medicineDoctors = enriched.map((d) => Doctor.fromApiDoctor(d)).toList();
        });
      }
    } else {
      setState(() {
        _medicineDoctors = _appState.mockDoctors;
        _isLoadingMedicineDoctors = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    final response = await CategoryService.getCategories();
    if (!mounted) return;

    if (response.success) {
      setState(() {
        _apiCategories = response.categories;
        _isLoadingCategories = false;
      });
    } else {
      setState(() {
        _categoryError = response.message ?? 'Failed to load categories';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchTestimonials() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTestimonials = true;
      _testimonialError = null;
    });

    final response = await TestimonialService.getTestimonials();
    if (!mounted) return;

    if (response.success) {
      final activeList = response.testimonials
          .where((t) => t.isActive && !t.isDeleted)
          .toList();
      setState(() {
        _testimonials = activeList.isNotEmpty
            ? activeList
            : response.testimonials;
        _isLoadingTestimonials = false;
      });
      if (_testimonials.length > 1) {
        _startTestimonialAutoSlide();
      }
    } else {
      setState(() {
        _testimonialError = response.message ?? 'Failed to load testimonials';
        _isLoadingTestimonials = false;
      });
    }
  }

  void _startTestimonialAutoSlide() {
    _testimonialTimer?.cancel();
    _testimonialTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _testimonials.isEmpty) return;
      final nextIndex = (_currentTestimonialIndex + 1) % _testimonials.length;
      if (_testimonialController.hasClients) {
        _testimonialController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _testimonialTimer?.cancel();
    _testimonialController.dispose();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    if (_medicineBanners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _medicineBanners.isEmpty) return;
      final nextIndex = (_currentBannerIndex + 1) % _medicineBanners.length;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchMedicineBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingMedicineBanners = true);

    final response = await BannerService.getMedicineBanners();
    if (!mounted) return;

    if (response.success && response.banners.isNotEmpty) {
      final active = response.banners
          .where((b) => b.isActive && !b.isDeleted)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _medicineBanners = active.isNotEmpty ? active : response.banners;
        _isLoadingMedicineBanners = false;
      });
      _startBannerAutoSlide();
    } else {
      setState(() => _isLoadingMedicineBanners = false);
    }
  }

  Future<void> _fetchMedicineBanner1() async {
    if (!mounted) return;
    setState(() => _isLoadingMedicineBanner1 = true);

    final response = await BannerService.getMedicineBanner1();
    if (!mounted) return;

    if (response.success && response.banners.isNotEmpty) {
      final active = response.banners
          .where((b) => b.isActive && !b.isDeleted)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _medicineBanner1 = active.isNotEmpty ? active : response.banners;
        _isLoadingMedicineBanner1 = false;
      });
    } else {
      setState(() => _isLoadingMedicineBanner1 = false);
    }
  }

  void _rebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  _buildShopByCategorySection(),
                  _buildSectionTitle('Shop by Health Concerns'),
                  _buildHealthConcernsRow(),
                  _buildConsultationBanner(),
                  _buildSectionTitle('Quick Healthcare Services'),
                  _buildQuickActionsGrid(),
                  // _buildAyushBanner(),
                  _buildProductSection(
                    'Ayurvedic Medicines',
                    'Herbal Medicine',
                  ),
                  _buildProductSection('Ayurvedic Vati & Tablets', 'Ayurvedic'),
                  _buildTopBrandsSection(),
                  _buildMedicineBanner1(),
                  _buildProductSection('Skin & Personal Care', 'Personal Care'),
                  // _buildUploadPrescriptionCTA(),
                  _buildProductSection(
                    'Immunity & Wellness',
                    'Immunity Boosters',
                  ),
                  _buildProductSection('Homeopathy & Allopathy', 'Allopathy'),
                  _buildDoctorsSection(),
                  _buildTestimonialsSection(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    int cartCount = 0;
    for (var item in _appState.cart) {
      cartCount += item.quantity;
    }

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        12,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/banner.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chikitsakart Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final loggedIn = await LoginScreen.checkAndNavigate(
                        context,
                      );
                      if (loggedIn && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        if (cartCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search input
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductCatalogScreen(
                              initialSearchQuery: val.trim(),
                            ),
                          ),
                        );
                      }
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Search for Medicines, Brands & Active Salts...',
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 6),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textLight,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HERO BANNER (from API: medicine/banner) ----------------
  Widget _buildHeroBanner() {
    if (_isLoadingMedicineBanners) {
      return const SizedBox(
        height: 196,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_medicineBanners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _medicineBanners.length,
            onPageChanged: (idx) =>
                setState(() => _currentBannerIndex = idx),
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _medicineBanners[idx].imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.border,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_medicineBanners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_medicineBanners.length, (idx) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentBannerIndex == idx ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == idx
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ---------------- SHOP BY CATEGORY ----------------
  Widget _buildShopByCategorySection() {
    final List<CategoryModel> activeCategories =
        _apiCategories.where((c) => c.isActive && !c.isDeleted).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Shop By Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Configurable from admin dashboard',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              if (_isLoadingCategories)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_categoryError != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: AppColors.primary),
                  onPressed: _fetchCategories,
                  tooltip: 'Retry loading categories',
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 12;
              // Ensure 3.5 cards are visible at one time
              final double cardWidth =
                  ((constraints.maxWidth - (3 * spacing)) / 3.5).clamp(70.0, 110.0);
              final double cardHeight = cardWidth + 34;

              if (_isLoadingCategories && activeCategories.isEmpty) {
                return SizedBox(
                  height: cardHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: spacing),
                      child: Column(
                        children: [
                          Container(
                            width: cardWidth,
                            height: cardWidth,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: cardWidth * 0.7,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (_categoryError != null && activeCategories.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _categoryError!,
                          style: const TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (activeCategories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No categories available',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                );
              } else {
                return SizedBox(
                  height: cardHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemCount: activeCategories.length,
                    itemBuilder: (context, idx) {
                      final category = activeCategories[idx];
                      final bool hasNetworkIcon =
                          category.icon.isNotEmpty && category.icon.startsWith('http');

                      return Padding(
                        padding: const EdgeInsets.only(right: spacing),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductCatalogScreen(
                                  initialCategory: category.name,
                                  initialCategoryId: category.id,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                width: cardWidth,
                                height: cardWidth,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasNetworkIcon
                                    ? Image.network(
                                        category.icon,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            child: Icon(
                                              Icons.medical_services_outlined,
                                              color: AppColors.primary,
                                              size: cardWidth * 0.42,
                                            ),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.medical_services_outlined,
                                          color: AppColors.primary,
                                          size: cardWidth * 0.42,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: cardWidth,
                                child: Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- HEALTH CONCERNS (Illness Category Circles) ----------------
  Widget _buildHealthConcernsRow() {
    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _healthConcerns.length,
        itemBuilder: (context, idx) {
          final item = _healthConcerns[idx];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
              );
            },
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 6),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.45),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item['icon'] as IconData,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['name'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- QUICK ACTIONS ("Simplify Medicine Purchases") ----------------
  Widget _buildQuickActionsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
        ),
        itemCount: _quickActions.length,
        itemBuilder: (context, idx) {
          final qa = _quickActions[idx];
          return GestureDetector(
            onTap: () async {
              final id = qa['id'] ?? '';
              if (id == 'view_prescription') {
                if (await LoginScreen.checkAndNavigate(context)) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyPrescriptionsScreen(),
                      ),
                    );
                  }
                }
              } else if (id == 'consult_doctor') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorConsultationScreen(),
                  ),
                );
              } else if (id == 'find_clinic') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClinicListingScreen(),
                  ),
                );
              } else if (id == 'book_appointment') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorListingScreen(),
                  ),
                );
              } else if (id == 'order_history') {
                if (await LoginScreen.checkAndNavigate(context)) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyOrdersScreen(),
                      ),
                    );
                  }
                }
              } else if (id == 'lab_tests' || qa['isComingSoon'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧪 Lab Tests are coming soon! Stay tuned.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Opening ${qa['name'].toString().replaceAll('\n', ' ')}...',
                    ),
                  ),
                );
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (qa['color'] as Color).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (qa['color'] as Color).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        qa['icon'] as IconData,
                        color: qa['color'] as Color,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        qa['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: qa['color'] as Color,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (qa['isComingSoon'] == true)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDB2777),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SOON',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- AYUSH SPECIAL BANNER ----------------
  Widget _buildAyushBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Special AYUSH Discounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Get up to 70% OFF on certified Ayurvedic & Herbal medicines.',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ProductCatalogScreen(initialCategory: 'Ayurvedic'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Shop AYUSH',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF064D34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor & Clinic Consultations',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Book online video consultations or visit nearby verified Ayush & Wellness Clinics.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorConsultationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.medical_services_outlined, size: 16),
                  label: const Text(
                    'Consult Doctor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8B800),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClinicListingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_hospital_outlined, size: 16, color: Colors.white),
                  label: const Text(
                    'Find Clinic',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- PRODUCT SECTION (CAROUSEL WITH "VIEW ALL") ----------------
  Widget _buildProductSection(String title, String category) {
    final products = _appState.products.where((p) {
      if (_searchQuery.isNotEmpty) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return p.category == category || category.isEmpty;
    }).toList();

    if (products.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductCatalogScreen(initialCategory: category),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, idx) {
              final prod = products[idx];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: _buildHorizontalProductCard(prod),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(Product prod) {
    final isWish = _appState.wishlistProductIds.contains(prod.id);
    final discountPct =
        (((prod.originalPrice - prod.price) / prod.originalPrice) * 100)
            .toInt();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: (prod.image.startsWith('http://') ||
                                prod.image.startsWith('https://'))
                            ? NetworkImage(prod.image) as ImageProvider
                            : AssetImage(
                                prod.image.isNotEmpty
                                    ? prod.image
                                    : 'assets/img2.png',
                              ),
                        fit: BoxFit.contain,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(
                          () => _appState.toggleProductWishlist(prod.id),
                        );
                      },
                      child: Icon(
                        isWish ? Icons.favorite : Icons.favorite_border,
                        color: isWish ? Colors.pink : AppColors.textLight,
                        size: 16,
                      ),
                    ),
                  ),
                  if (prod.isPrescriptionRequired)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Rx',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (discountPct > 0)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _appState.isDoctorLoggedIn ? const Color(0xFF0D9488) : Colors.green[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _appState.isDoctorLoggedIn
                              ? (prod.roleDiscountLabel.isNotEmpty ? prod.roleDiscountLabel : 'Dr. $discountPct% OFF')
                              : '$discountPct% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prod.brand.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prod.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${prod.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (prod.price < prod.originalPrice)
                      Text(
                        '₹${prod.originalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough, 
                        ),
                      ),
                  ],
                ),
                ProductQuantitySelector(product: prod, iconSize: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- MEDICINE BANNER 1 (below Top Ayurvedic Brands) ----------------
  Widget _buildMedicineBanner1() {
    if (_isLoadingMedicineBanner1) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_medicineBanner1.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _medicineBanner1.first.imageUrl,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.border,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- TOP AYURVEDIC BRANDS ----------------
  Widget _buildTopBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Top Ayurvedic Brands'),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _brands.length,
            itemBuilder: (context, idx) {
              final brand = _brands[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductCatalogScreen(
                        initialSearchQuery: brand['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 88,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      brand['image'] ?? 'assets/d1.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- UPLOAD PRESCRIPTION CTA BANNER ----------------
  Widget _buildUploadPrescriptionCTA() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner,
              color: Colors.lightBlueAccent,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Have a Prescription?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload your prescription and let our expert pharmacists fulfill your order.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showUploadPrescriptionDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Upload Now',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FEATURED DOCTORS SECTION ----------------
  Widget _buildDoctorsSection() {
    final doctors = _medicineDoctors.isNotEmpty
        ? _medicineDoctors
        : _appState.mockDoctors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best Doctors for Consultations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DoctorListingScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: _isLoadingMedicineDoctors
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, idx) {
                    final doc = doctors[idx];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorProfileScreen(doctor: doc),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: (doc.image.startsWith('http://') ||
                                                doc.image.startsWith('https://'))
                                            ? NetworkImage(doc.image)
                                                as ImageProvider
                                            : AssetImage(
                                                doc.image.isNotEmpty
                                                    ? doc.image
                                                    : 'assets/doctor_profile.png',
                                              ),
                                        fit: BoxFit.cover,
                                        onError: (_, __) {},
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: AppColors.primary,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${doc.rating}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              doc.specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  size: 10,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${doc.experienceYears} Yrs Exp.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${doc.getFeeForType().toInt()}/Consultation',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              height: 24,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (await LoginScreen.checkAndNavigate(context)) {
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookAppointmentScreen(doctor: doc),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------- TESTIMONIALS SECTION ----------------
  Widget _buildTestimonialsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Loved by Thousands',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Patient success stories from our consultations',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoadingTestimonials)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_testimonialError != null && _testimonials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _testimonialError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _fetchTestimonials,
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          else if (_testimonials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'No testimonials available right now.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _testimonialController,
                onPageChanged: (idx) {
                  setState(() => _currentTestimonialIndex = idx);
                },
                itemCount: _testimonials.length,
                itemBuilder: (context, idx) {
                  final item = _testimonials[idx];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                item.rating.clamp(1, 5),
                                (_) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '"${item.testimonial}"',
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              backgroundImage:
                                  item.image.isNotEmpty &&
                                      item.image.startsWith('http')
                                  ? NetworkImage(item.image)
                                  : null,
                              child:
                                  item.image.isEmpty ||
                                      !item.image.startsWith('http')
                                  ? Text(
                                      item.name.isNotEmpty
                                          ? item.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                if (item.isVerified)
                                  const Text(
                                    'Verified Patient',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_testimonials.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_testimonials.length, (idx) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentTestimonialIndex == idx ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentTestimonialIndex == idx
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  void _showUploadPrescriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Upload Prescription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              SizedBox(height: 12),
              Text(
                'Please select your prescription photo from your device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                    withData: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final fileName = result.files.first.name;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Prescription "$fileName" uploaded successfully! Our pharmacist will contact you.',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to pick prescription image: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Select Image',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
