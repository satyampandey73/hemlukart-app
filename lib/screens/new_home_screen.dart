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

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _appState.removeListener(_rebuild);
    _bannerController.dispose();
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

  final List<Map<String, String>> _faqList = [
    {
      'question': 'What types of products does Hemlukart offer?',
      'answer':
          'Hemlukart specializes in authentic, high-quality Ayurvedic and natural wellness products. Our catalog includes organic supplements, wellness remedies, skincare products, and personalized herbal formulations designed to promote holistic health.',
    },
    {
      'question': 'Are the products certified and safe to use?',
      'answer':
          'Yes, all wellness products are sourced from verified GMP-certified facilities and FDA-registered laboratories. Every batch is evaluated to ensure absolute purity and safety.',
    },
    {
      'question': 'How long does delivery take?',
      'answer':
          'Standard delivery takes 3-5 business days. Express shipping is available for select zones (1-2 business days).',
    },
    {
      'question': 'Is doctor consultation available online?',
      'answer':
          'Yes, we provide online video/audio consultations with certified Ayurvedic, Homeopathic, and Unani practitioners. You can choose a slot and book directly.',
    },
  ];

  final List<bool> _faqExpanded = [false, false, false, false];

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
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.healing,
                            color: AppColors.primary,
                            size: 24,
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
                  onTap: () => widget.onTabChange(2), // Navigate to Shop
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

          // Our Brands
          _buildSectionHeader(
            'Our Brands',
            'Pick from our favorite brands',
            () => widget.onTabChange(2),
          ),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
                _buildBrandCard(
                  'Sugar Free',
                  '',
                  onTap: () => widget.onTabChange(2),
                ),
              ],
            ),
          ),

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
            () => widget.onTabChange(1),
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
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryCard('Must Have', Icons.star, Colors.orange),
                _buildCategoryCard(
                  'Vitamin Store',
                  Icons.health_and_safety,
                  Colors.green,
                ),
                _buildCategoryCard(
                  'Sexual Wellness',
                  Icons.favorite,
                  Colors.pink,
                ),
                _buildCategoryCard('Personal Care', Icons.face, Colors.teal),
                _buildCategoryCard(
                  'Summer Store',
                  Icons.wb_sunny,
                  Colors.amber,
                ),
                _buildCategoryCard('Self Care', Icons.spa, Colors.indigo),
              ],
            ),
          ),

          // Featured Products
          _buildSectionHeader(
            'Featured Products',
            'Shop our best featured wellness products',
            () => widget.onTabChange(2),
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
            itemCount: _appState.mockProducts.take(4).length,
            itemBuilder: (context, idx) {
              final prod = _appState.mockProducts[idx];
              return _buildProductCard(prod);
            },
          ),

          const SizedBox(height: 24),

          // Blog Section
          _buildSectionHeader('Our Blogs', 'Health Articles', () {}),
          SizedBox(
            height: 260,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (context, idx) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                return _buildBlogCard(
                  title:
                      'Smog: What Is It, Causes and Ways To Protect Yourself From',
                  imagePath: 'assets/img2.png',
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Loved by Thousands (Testimonial Slider)
          Container(
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
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '"The telemedicine consultation was incredibly professional. I received my Ayurvedic supplements the next day. Truly life-changing service!"',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Robert Wilson',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
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
                ),
              ],
            ),
          ),

          // FAQ Accordion Section
          Padding(
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _faqList.length,
                  itemBuilder: (context, idx) {
                    final item = _faqList[idx];
                    final isExp = _faqExpanded[idx];
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
                            onTap: () =>
                                setState(() => _faqExpanded[idx] = !isExp),
                            title: Text(
                              item['question']!,
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
                                item['answer']!,
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
          ),
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

  Widget _buildBrandCard(String title, String subtitle, {VoidCallback? onTap}) {
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
              child: Stack(
                children: [
                  Image.asset(
                    'assets/img2.png',
                    width: 144,
                    height: 104,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        // color: AppColors.secondary,
                        color: const Color.fromRGBO(140, 244, 235, 1.0),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        '15% OFF',
                        style: TextStyle(
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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

  Widget _buildBlogCard({required String title, required String imagePath}) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            child: Image.asset(imagePath, height: 140, fit: BoxFit.cover),
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
                    color: AppColors.primary.withOpacity(0.12),
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
                  title,
                  maxLines: 4,
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

  Widget _buildCategoryCard(String name, IconData icon, Color color) {
    return Container(
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
                Image.asset(
                  'assets/img2.png',
                  width: 144,
                  height: 104,
                  fit: BoxFit.cover,
                ),
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      '15% OFF',
                      style: TextStyle(
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Text(
              name,
              maxLines: 2,
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
                        image: AssetImage(
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
                  children: const [
                    Text(
                      '450ml',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    Icon(
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
}
