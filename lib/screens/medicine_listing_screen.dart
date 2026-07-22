import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'product_detail_screen.dart';
import 'product_catalog_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_profile_screen.dart';

class MedicineListingScreen extends StatefulWidget {
  const MedicineListingScreen({super.key});

  @override
  State<MedicineListingScreen> createState() => _MedicineListingScreenState();
}

class _MedicineListingScreenState extends State<MedicineListingScreen> {
  final AppState _appState = AppState();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
      'name': 'Upload\nPrescription',
      'icon': Icons.upload_file,
      'color': const Color(0xFF0D9488),
    },
    {
      'name': 'Consult\nDoctor',
      'icon': Icons.medical_services_outlined,
      'color': const Color(0xFF2563EB),
    },
    {
      'name': 'Book\nAppointment',
      'icon': Icons.calendar_month_outlined,
      'color': const Color(0xFF7C3AED),
    },
    {
      'name': 'Order\nHistory',
      'icon': Icons.receipt_long_outlined,
      'color': const Color(0xFFD97706),
    },
    {
      'name': 'Refill\nMedicines',
      'icon': Icons.autorenew,
      'color': const Color(0xFF059669),
    },
    {
      'name': 'Lab\nTests',
      'icon': Icons.science_outlined,
      'color': const Color(0xFFDB2777),
    },
  ];

  final List<String> _brands = [
    'Dabur',
    'Baidyanath',
    'Himalaya Wellness',
    'Patanjali',
    'Kerala Ayurveda',
    'Zandu',
    'Maharishi Ayurveda',
    'Organic India',
  ];

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
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
                  _buildSectionTitle('Shop by Health Concerns'),
                  _buildHealthConcernsRow(),
                  _buildSectionTitle('Simplify Medicine Purchases'),
                  _buildQuickActionsGrid(),
                  _buildAyushBanner(),
                  _buildProductSection(
                    'Ayurvedic Medicines',
                    'Herbal Medicine',
                  ),
                  _buildProductSection('Ayurvedic Vati & Tablets', 'Ayurvedic'),
                  _buildTopBrandsSection(),
                  _buildProductSection('Skin & Personal Care', 'Personal Care'),
                  _buildUploadPrescriptionCTA(),
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'H',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hemlukart Store',
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

  // ---------------- HERO BANNER ("Your Health, Our Priority") ----------------
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HEMLUKART HEALTHCARE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Health, Our Priority',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find 100% genuine medicines & consult verified doctors online.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorConsultationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Consult Doctor Now',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 48,
            ),
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
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (item['color'] as Color).withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 26,
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
            onTap: () {
              if (idx == 0) {
                _showUploadPrescriptionDialog(context);
              } else if (idx == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorConsultationScreen(),
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
            child: Container(
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

  // ---------------- PRODUCT SECTION (CAROUSEL WITH "VIEW ALL") ----------------
  Widget _buildProductSection(String title, String category) {
    final products = _appState.mockProducts.where((p) {
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
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discountPct% OFF',
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
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ],
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
          height: 75,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _brands.length,
            itemBuilder: (context, idx) {
              final brand = _brands[idx];
              return Container(
                width: 75,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text(
                  brand,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
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
    final doctors = _appState.mockDoctors;
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
                      builder: (_) => const DoctorConsultationScreen(),
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
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: doctors.length,
            itemBuilder: (context, idx) {
              final doc = doctors[idx];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: AssetImage(
                        doc.image.isNotEmpty
                            ? doc.image
                            : 'assets/doctor_profile.png',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            doc.specialty,
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${doc.rating}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${doc.reviewsCount})',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DoctorProfileScreen(doctor: doc),
                                ),
                              );
                            },
                            child: const Text(
                              'Book Consult >',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Loved by Thousands'),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildTestimonialCard(
                'Pooja R.',
                'Great app! Genuine Ayurvedic medicines delivered in 2 hours.',
              ),
              _buildTestimonialCard(
                'Suresh K.',
                'Easy prescription upload and awesome discounts on Ayush items.',
              ),
              _buildTestimonialCard(
                'Ananya M.',
                'Top doctors consultation experience was super convenient.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(String name, String review) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.star, color: Colors.amber, size: 12),
              Icon(Icons.star, color: Colors.amber, size: 12),
              Icon(Icons.star, color: Colors.amber, size: 12),
              Icon(Icons.star, color: Colors.amber, size: 12),
              Icon(Icons.star, color: Colors.amber, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textDark),
          ),
          const Spacer(),
          Text(
            '— $name',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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
                'Please select your prescription photo or PDF from device.',
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
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Prescription uploaded successfully! Our pharmacist will contact you.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Select File',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
