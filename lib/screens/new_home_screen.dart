import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'product_detail_screen.dart';
import 'doctor_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'product_catalog_screen.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../models/testimonial_model.dart';
import '../services/testimonial_service.dart';
import '../models/faq_model.dart';
import '../services/faq_service.dart';
import '../models/brand_model.dart';
import '../services/brand_service.dart';
import '../models/blog_model.dart';
import '../services/blog_service.dart';
import 'blog_detail_screen.dart';

// harsh.s@btplsoft.com
class NewHomeScreen extends StatefulWidget {
  final Function(int) onTabChange;
  const NewHomeScreen({super.key, required this.onTabChange});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  final AppState _appState = AppState();
  Timer? _bannerTimer;

  List<CategoryModel> _apiCategories = [];
  bool _isLoadingCategories = false;
  String? _categoryError;

  List<TestimonialModel> _testimonials = [];
  bool _isLoadingTestimonials = false;
  String? _testimonialError;
  final PageController _testimonialController = PageController();
  int _currentTestimonialIndex = 0;
  Timer? _testimonialTimer;

  List<FaqModel> _apiFaqs = [];
  List<bool> _faqExpandedStates = [];
  bool _isLoadingFaqs = false;
  String? _faqError;

  List<BrandModel> _apiBrands = [];
  bool _isLoadingBrands = false;
  String? _brandError;

  List<BlogModel> _apiBlogs = [];
  bool _isLoadingBlogs = false;
  String? _blogError;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
    _startBannerAutoSlide();
    _fetchCategories();
    _fetchTestimonials();
    _fetchFaqs();
    _fetchBrands();
    _fetchBlogs();
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
      final activeList =
          response.testimonials.where((t) => t.isActive && !t.isDeleted).toList();
      setState(() {
        _testimonials = activeList.isNotEmpty ? activeList : response.testimonials;
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

  Future<void> _fetchFaqs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFaqs = true;
      _faqError = null;
    });

    final response = await FaqService.getFaqs();
    if (!mounted) return;

    if (response.success) {
      final activeList =
          response.faqs.where((f) => f.isActive && !f.isDeleted).toList();
      activeList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _apiFaqs = activeList.isNotEmpty ? activeList : response.faqs;
        _faqExpandedStates = List.filled(_apiFaqs.length, false);
        _isLoadingFaqs = false;
      });
    } else {
      setState(() {
        _faqError = response.message ?? 'Failed to load FAQs';
        _isLoadingFaqs = false;
      });
    }
  }

  Future<void> _fetchBrands() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBrands = true;
      _brandError = null;
    });

    final response = await BrandService.getBrands();
    if (!mounted) return;

    if (response.success) {
      final activeList =
          response.brands.where((b) => b.isActive && !b.isDeleted).toList();
      activeList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _apiBrands = activeList.isNotEmpty ? activeList : response.brands;
        _isLoadingBrands = false;
      });
    } else {
      setState(() {
        _brandError = response.message ?? 'Failed to load brands';
        _isLoadingBrands = false;
      });
    }
  }

  Future<void> _fetchBlogs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBlogs = true;
      _blogError = null;
    });

    final response = await BlogService.getBlogs();
    if (!mounted) return;

    if (response.success) {
      final activeList =
          response.blogs.where((b) => b.isActive && !b.isDeleted).toList();
      activeList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _apiBlogs = activeList.isNotEmpty ? activeList : response.blogs;
        _isLoadingBlogs = false;
      });
    } else {
      setState(() {
        _blogError = response.message ?? 'Failed to load blogs';
        _isLoadingBlogs = false;
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _testimonialTimer?.cancel();
    _appState.removeListener(_rebuild);
    _bannerController.dispose();
    _testimonialController.dispose();
    super.dispose();
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      final nextIndex = (_currentBannerIndex + 1) % 3;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    VoidCallback onViewAll,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: Row(
              children: const [
                Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIconBtn() {
    int count = 0;
    for (var item in _appState.cart) {
      count += item.quantity;
    }
    return GestureDetector(
      onTap: () async {
        if (await LoginScreen.checkAndNavigate(context)) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          }
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 22,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Search Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/banner.png',
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hemlukart',

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Deliver to 452001',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCartIconBtn(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => widget.onTabChange(1), // Navigate to Shop
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.textLight),
                        SizedBox(width: 8),
                        Text(
                          'Search for Medicines, Products...',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // const SizedBox(height: 16),

          // Banner Carousel
          SizedBox(
            height: 180,
            child: PageView(
              controller: _bannerController,
              onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
              children: [
                _buildBannerSlide(
                  '',
                  '',
                  Colors.transparent,
                  'assets/img1.png',
                ),
                _buildBannerSlide(
                  '',
                  '',
                  Colors.transparent,
                  'assets/img1.png',
                ),
                _buildBannerSlide(
                  '',
                  '',
                  Colors.transparent,
                  'assets/img1.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              return Container(
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

          const SizedBox(height: 20),

          // Our Brands (from API)
          _buildBrandsSection(),

          const SizedBox(height: 20),

          // Quick Actions Grid (mobile-friendly layout instead of desktop side-bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildQuickActionCard(
                  'Order Medicines',
                  'Genuine products',
                  Icons.medication_liquid,
                  const Color.fromARGB(255, 255, 255, 255),
                  () => widget.onTabChange(2),
                ),
                _buildQuickActionCard(
                  'Book a Doctor',
                  'Expert Consulting',
                  Icons.local_hospital,
                  const Color.fromARGB(255, 255, 255, 255),
                  () => widget.onTabChange(1),
                ),
                _buildQuickActionCard(
                  'Track Your Order',
                  'Real-time tracking',
                  Icons.local_shipping_outlined,
                  const Color.fromARGB(255, 255, 255, 255),
                  () {
                    if (_appState.orders.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            order: _appState.orders.first,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No active orders to track. Place an order first!',
                          ),
                        ),
                      );
                    }
                  },
                ),
              
                _buildQuickActionCard(
                  'View Prescriptions',
                  'Digital health vaults',
                  Icons.receipt_long,
                  const Color.fromARGB(255, 255, 255, 255),
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prescription records vault is empty.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Featured Doctors
          _buildSectionHeader(
            'Featured Doctors',
            'Consult with our top-rated medical experts',
            () => widget.onTabChange(3),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _appState.mockDoctors.length,
              itemBuilder: (context, idx) {
                final doc = _appState.mockDoctors[idx];
                return _buildDoctorCard(doc);
              },
            ),
          ),

          // Categories
          _buildSectionHeader(
            'Our Categories',
            'Shop by health category interests',
            () => widget.onTabChange(2),
          ),
          _buildCategorySection(),

          // Featured Products
          _buildSectionHeader(
            'Featured Products',
            'Shop our best featured wellness products',
            () => widget.onTabChange(1),
          ),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.60,
            ),
            itemCount: _appState.products.take(4).length,
            itemBuilder: (context, idx) {
              final prod = _appState.products[idx];
              return _buildProductCard(prod);
            },
          ),

          const SizedBox(height: 24),

          // Blog Section (from API)
          _buildBlogsSection(),

          const SizedBox(height: 24),

          // Loved by Thousands (Testimonials Section from API)
          _buildTestimonialsSection(),

          // FAQ Accordion Section from API
          _buildFaqSection(),
        ],
      ),
    );
  }

  Widget _buildBannerSlide(
    String title,
    String desc,
    Color bgColor,
    String? imagePath,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null && title.isEmpty && desc.isEmpty
          ? Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imagePath,
                                width: 86,
                                height: 86,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                size: 40,
                                color: AppColors.secondary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildBlogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Our Blogs', 'Health Articles', () {
          if (_apiBlogs.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlogDetailScreen(
                  blogId: _apiBlogs.first.id,
                  initialBlog: _apiBlogs.first,
                ),
              ),
            );
          }
        }),
        if (_isLoadingBlogs)
          Container(
            height: 260,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else if (_blogError != null && _apiBlogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _blogError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fetchBlogs,
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                    label: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          )
        else if (_apiBlogs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No blogs available right now.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _apiBlogs.length,
              separatorBuilder: (context, idx) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final blog = _apiBlogs[idx];
                return _buildApiBlogCard(blog);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildApiBlogCard(BlogModel blog) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlogDetailScreen(
              blogId: blog.id,
              initialBlog: blog,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 140,
                color: AppColors.backgroundLight,
                child: blog.image.isNotEmpty && blog.image.startsWith('http')
                    ? Image.network(
                        blog.image,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/img2.png',
                            height: 140,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/img2.png',
                        height: 140,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Health Articles',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    blog.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doc)),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
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
                        image: AssetImage(
                          doc.image.isNotEmpty
                              ? doc.image
                              : 'assets/doctor_profile.png',
                        ),
                        fit: BoxFit.cover,
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
                            color: Colors.black.withOpacity(0.08),
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
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
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
                  '₹${doc.consultationFee.toInt()}/Consultation',
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
                          builder: (_) => BookAppointmentScreen(doctor: doc),
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
  }

  Widget _buildCategorySection() {
    final activeCategories =
        _apiCategories.where((c) => c.isActive && !c.isDeleted).toList();

    if (_isLoadingCategories && activeCategories.isEmpty) {
      return SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, idx) => Container(
            width: 144,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    if (_categoryError != null && activeCategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _categoryError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: _fetchCategories,
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (activeCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: activeCategories.length,
        itemBuilder: (context, idx) {
          final category = activeCategories[idx];
          return _buildApiCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildApiCategoryCard(CategoryModel category) {
    final bool hasNetworkIcon =
        category.icon.isNotEmpty && category.icon.startsWith('http');

    return GestureDetector(
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
      child: Container(
        width: 144,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    width: 144,
                    height: 104,
                    child: hasNetworkIcon
                        ? Image.network(
                            category.icon,
                            width: 144,
                            height: 104,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.medical_services_outlined,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                  ),
                  if (category.discount > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(140, 244, 235, 1.0),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${category.discount}% OFF',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 12, 112, 93),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductCard(Product prod) {
    final isWish = _appState.wishlistProductIds.contains(prod.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
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
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _appState.toggleProductWishlist(prod.id);
                        });
                      },
                      child: Icon(
                        isWish ? Icons.favorite : Icons.favorite_border,
                        color: isWish ? Colors.pink : AppColors.textLight,
                        size: 18,
                      ),
                    ),
                  ),
                  if (prod.price < prod.originalPrice)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${((prod.originalPrice - prod.price) / prod.originalPrice * 100).toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prod.brand,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prod.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 10),
                const SizedBox(width: 2),
                Text(
                  '${prod.rating}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${prod.reviewsCount})',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.secondary, width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prod.packSize.isNotEmpty ? prod.packSize : '1 Pack',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${prod.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (prod.price < prod.originalPrice)
                      Text(
                        '₹${prod.originalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _appState.addToCart(prod, qty: 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${prod.name} added to cart!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                color: AppColors.backgroundLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _testimonialError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _fetchTestimonials,
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                    label: const Text('Retry', style: TextStyle(color: AppColors.primary)),
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
                      color: AppColors.backgroundLight.withOpacity(0.4),
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
                              backgroundImage: item.image.isNotEmpty && item.image.startsWith('http')
                                  ? NetworkImage(item.image)
                                  : null,
                              child: item.image.isEmpty || !item.image.startsWith('http')
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

  Widget _buildFaqSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingFaqs)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_faqError != null && _apiFaqs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    _faqError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _fetchFaqs,
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                    label: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            )
          else if (_apiFaqs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: const Text(
                'No FAQs available at the moment.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _apiFaqs.length,
              itemBuilder: (context, idx) {
                final item = _apiFaqs[idx];
                final isExp =
                    idx < _faqExpandedStates.length ? _faqExpandedStates[idx] : false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            if (idx < _faqExpandedStates.length) {
                              _faqExpandedStates[idx] = !_faqExpandedStates[idx];
                            }
                          });
                        },
                        title: Text(
                          item.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        trailing: Icon(
                          isExp ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.primary,
                        ),
                      ),
                      if (isExp)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            item.answer,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Our Brands',
          'Pick from our favorite brands',
          () => widget.onTabChange(2),
        ),
        if (_isLoadingBrands)
          Container(
            height: 150,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          )
        else if (_brandError != null && _apiBrands.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _brandError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _fetchBrands,
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                    label: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          )
        else if (_apiBrands.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No brands available.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _apiBrands.length,
              itemBuilder: (context, idx) {
                final brand = _apiBrands[idx];
                return _buildApiBrandCard(
                  brand,
                  onTap: () => widget.onTabChange(2),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildApiBrandCard(BrandModel brand, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 144,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                width: 144,
                height: 104,
                color: AppColors.backgroundLight.withOpacity(0.5),
                child: brand.image.isNotEmpty && brand.image.startsWith('http')
                    ? Image.network(
                        brand.image,
                        width: 144,
                        height: 104,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/img2.png',
                            width: 144,
                            height: 104,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/img2.png',
                        width: 144,
                        height: 104,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
