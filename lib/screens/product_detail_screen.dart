import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/product_faq_model.dart';
import '../services/product_faq_service.dart';
import '../models/rating_model.dart';
import '../services/rating_service.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'clinic_listing_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AppState _appState = AppState();
  late String _selectedImage;
  final PageController _promoController = PageController();
  int _currentPromoIndex = 0;
  Timer? _promoTimer;

  List<BannerModel> _detailBanners = [];
  bool _isLoadingDetailBanners = false;

  late List<String> _galleryImages;
  late Product _currentProduct;

  List<ProductFaqModel> _productFaqs = [];
  bool _isLoadingFaqs = false;

  List<RatingItem> _productRatings = [];
  RatingStats? _ratingStats;
  bool _isLoadingRatings = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _selectedImage = _currentProduct.image.isNotEmpty
        ? _currentProduct.image
        : 'assets/p1.png';
    _galleryImages = _currentProduct.image.isNotEmpty
        ? [_currentProduct.image]
        : ['assets/p1.png'];
    _appState.addListener(_rebuild);
    _startPromoAutoSlide();
    _fetchDetailBanners();
    _fetchLiveDetails();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    if (!mounted) return;
    setState(() => _isLoadingRatings = true);
    final res = await RatingService.getRatings(
      targetType: 'product',
      targetId: _currentProduct.id,
    );
    if (mounted) {
      setState(() {
        _isLoadingRatings = false;
        if (res.success) {
          _productRatings = res.ratings;
          _ratingStats = res.stats;
        }
      });
    }
  }

  Future<void> _fetchLiveDetails() async {
    setState(() => _isLoadingFaqs = true);
    final liveProd = await _appState.fetchProductDetails(_currentProduct.id);
    final faqs = await _appState.fetchProductFaqs(_currentProduct.id);
    if (mounted) {
      setState(() {
        if (liveProd != null) {
          _currentProduct = liveProd;
          if (liveProd.image.isNotEmpty && liveProd.image.startsWith('http')) {
            _selectedImage = liveProd.image;
            _galleryImages = [liveProd.image];
          }
        }
        _productFaqs = faqs;
        _isLoadingFaqs = false;
      });
    }
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _startPromoAutoSlide() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_promoController.hasClients) return;
      final count = _detailBanners.isNotEmpty ? _detailBanners.length : 2;
      final nextIndex = (_currentPromoIndex + 1) % count;
      _promoController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      if (mounted) {
        setState(() => _currentPromoIndex = nextIndex);
      }
    });
  }

  Future<void> _fetchDetailBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingDetailBanners = true);

    final response = await BannerService.getProductDetailBanners();
    if (!mounted) return;

    if (response.success && response.banners.isNotEmpty) {
      final active = response.banners
          .where((b) => b.isActive && !b.isDeleted)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _detailBanners = active.isNotEmpty ? active : response.banners;
        _isLoadingDetailBanners = false;
      });
      // Restart auto-slide with the correct count
      _startPromoAutoSlide();
    } else {
      setState(() => _isLoadingDetailBanners = false);
    }
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
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
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
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
        ),
      ),
    );
  }

  int _qty = 1;

  String _selectedPackSize = '60 Tabs';
  String _selectedPotency = '500mg';
  String _selectedFlavour = 'Orange';

  final List<String> _packSizes = ['30 Tabs', '60 Tabs', '120 Tabs'];
  final List<String> _potencies = ['500mg', '1000mg'];
  final List<String> _flavours = ['Orange', 'Pineapple', 'Vanilla'];

  bool _descExpanded = true;
  bool _benefitsExpanded = false;
  bool _ingredientsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final prod = _currentProduct;
    final isWish = _appState.wishlistProductIds.contains(prod.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          prod.brand,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _buildCartIconBtn(),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Sharing ${prod.name}')));
            },
          ),
          IconButton(
            icon: Icon(
              isWish ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _appState.toggleProductWishlist(prod.id);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Showcase
            Container(
              height: 320,
              width: double.infinity,
              color: Colors.white,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: (_selectedImage.startsWith('http://') ||
                                  _selectedImage.startsWith('https://'))
                              ? NetworkImage(_selectedImage) as ImageProvider
                              : AssetImage(_selectedImage),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  if (prod.isPrescriptionRequired)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Prescription Required',
                          style: TextStyle(
                            color: Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ..._galleryImages.map((imagePath) {
                    final isSelected = _selectedImage == imagePath;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = imagePath;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: (imagePath.startsWith('http://') ||
                                    imagePath.startsWith('https://'))
                                ? NetworkImage(imagePath) as ImageProvider
                                : AssetImage(imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Details Container
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${prod.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${prod.reviewsCount} Customer Reviews',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${prod.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${prod.originalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save ${((prod.originalPrice - prod.price) / prod.originalPrice * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Attributes from API (Pack Size, Potency, Category)
                  const Text(
                    'Pack Size & Packing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(prod.packSize),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Variant / Potency',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(prod.potency),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(prod.category),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Qty adjust and Add to cart
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                            ),
                            Text(
                              '$_qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _appState.addToCart(prod, qty: _qty);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added $_qty x ${prod.name} to cart!',
                                ),
                                action: SnackBarAction(
                                  label: 'View Cart',
                                  textColor: Colors.amber,
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    final shouldNavigate =
                                        await LoginScreen.checkAndNavigate(
                                          context,
                                        );
                                    if (!mounted || !context.mounted) return;
                                    if (shouldNavigate) {
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (_) => const CartScreen(),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Find Nearby Clinic Advice Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Need In-Person Clinic Care?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Find nearby verified Ayush & Healthcare Clinics.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClinicListingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Find Clinic',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Collapsible Product details
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildCollapsibleHeader(
                    'Product Description',
                    _descExpanded,
                    (val) => setState(() => _descExpanded = val),
                  ),
                  if (_descExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        prod.description,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  _buildCollapsibleHeader(
                    'Key Benefits',
                    _benefitsExpanded,
                    (val) => setState(() => _benefitsExpanded = val),
                  ),
                  if (_benefitsExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _BenefitRow(
                            'Provides natural energy enhancement without caffeine crashes.',
                          ),
                          _BenefitRow(
                            'Fortifies daily immunity defense with traditional Ayurvedic antioxidants.',
                          ),
                          _BenefitRow(
                            'Supports gut metabolism and healthy nutrient absorption levels.',
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  _buildCollapsibleHeader(
                    'Ingredients',
                    _ingredientsExpanded,
                    (val) => setState(() => _ingredientsExpanded = val),
                  ),
                  if (_ingredientsExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        'Pure extracts of ${prod.name.split(' ').first}, Organic Cellulose, Plant Stearates, Silica, Minerals.',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  // _buildCollapsibleHeader(
                  //   'Customer Questions & Answers',
                  //   _faqsExpanded,
                  //   (val) => setState(() => _faqsExpanded = val),
                  // ),
                  // if (_faqsExpanded)
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    //   child: _isLoadingFaqs
                    //       ? const Center(
                    //           child: Padding(
                    //             padding: EdgeInsets.all(12),
                    //             child: CircularProgressIndicator(strokeWidth: 2),
                    //           ),
                    //         )
                    //       : _productFaqs.isEmpty
                    //           ? const Text(
                    //               'No FAQs available for this product yet.',
                    //               style: TextStyle(
                    //                 color: AppColors.textLight,
                    //                 fontSize: 13,
                    //               ),
                    //             )
                    //           : Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: _productFaqs.map((faq) {
                    //                 return Padding(
                    //                   padding: const EdgeInsets.only(bottom: 12),
                    //                   child: Column(
                    //                     crossAxisAlignment: CrossAxisAlignment.start,
                    //                     children: [
                    //                       Row(
                    //                         children: [
                    //                           const Icon(
                    //                             Icons.help_outline,
                    //                             size: 16,
                    //                             color: AppColors.primary,
                    //                           ),
                    //                           const SizedBox(width: 6),
                    //                           Expanded(
                    //                             child: Text(
                    //                               faq.question,
                    //                               style: const TextStyle(
                    //                                 fontWeight: FontWeight.bold,
                    //                                 fontSize: 13,
                    //                                 color: AppColors.textDark,
                    //                               ),
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                       const SizedBox(height: 4),
                    //                       Padding(
                    //                         padding: const EdgeInsets.only(left: 22),
                    //                         child: Text(
                    //                           faq.answer,
                    //                           style: const TextStyle(
                    //                             color: AppColors.textLight,
                    //                             fontSize: 12,
                    //                             height: 1.4,
                    //                           ),
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 );
                    //               }).toList(),
                    //             ),
                    // ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildRatingsContainer(),

            // Customer Questions & Answers Section (Powered by Live FAQs API)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Customer Questions & Answers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (_productFaqs.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${_productFaqs.length} answered questions',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (await LoginScreen.checkAndNavigate(context)) {
                            _showAskQuestionDialog();
                          }
                        },
                        icon: const Icon(Icons.help_outline, size: 15, color: Colors.white),
                        label: const Text(
                          'Ask Question',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingFaqs)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_productFaqs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Have a question about this product? Be the first to ask!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                if (await LoginScreen.checkAndNavigate(context)) {
                                  _showAskQuestionDialog();
                                }
                              },
                              icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Ask a Question',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _productFaqs.map((faq) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Q',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      faq.question,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      faq.answer,
                                      style: const TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (faq.answeredByRole != null &&
                                  faq.answeredByRole!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Answered by ${faq.answeredByRole}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 1),
            if (_isLoadingDetailBanners)
              Container(
                height: 160,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_detailBanners.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: PageView.builder(
                        controller: _promoController,
                        itemCount: _detailBanners.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPromoIndex = index),
                        itemBuilder: (context, idx) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(1),
                            ),
                            child: Image.network(
                              _detailBanners[idx].imageUrl,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppColors.backgroundLight,
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.backgroundLight,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.border,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_detailBanners.length > 1) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_detailBanners.length, (index) {
                          final isActive = index == _currentPromoIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isActive ? 16 : 8,
                            height: 8,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Recently Explored Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _appState.products
                          .where((product) => product.id != prod.id)
                          .take(4)
                          .length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = _appState.products
                            .where((item) => item.id != prod.id)
                            .toList()[index];
                        return _buildRecentlyExploredProductCard(product);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // _buildQASearchPanel(),
            // const SizedBox(height: 16),
            _buildManufacturerDetailsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem({
    required String question,
    required String answer,
    required String answerType,
    required int helpfulYes,
    required int helpfulNo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    answerType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Helpful? ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        'Yes ($helpfulYes)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'No ($helpfulNo)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQASearchPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Have a question? Search for answers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.7)),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: AppColors.textLight, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Have a question? Search for answers',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Q: Is this multivitamin suitable for vegetarians?',
                    style: TextStyle(color: AppColors.textDark, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Brand Answer',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'See all 45 questions',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManufacturerDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manufacture Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Brand', 'GreenLeaf Nutrition'),
          _buildDetailRow('Country of Origin', 'United States'),
          _buildDetailRow('Manufacturer Name', 'GreenLeaf Labs Inc.'),
          _buildDetailRow(
            'Manufacturer Address',
            '123 Wellness Way\nSuite 400\nAustin, TX 78701',
          ),
          _buildDetailRow('Certifications', 'GMP Certified, FDA Registered'),
          _buildDetailRow(
            'Contact Info',
            'support@greenleaf.com\n+1 (800) 555-0199',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyExploredProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: (product.image.startsWith('http://') ||
                            product.image.startsWith('https://'))
                        ? NetworkImage(product.image) as ImageProvider
                        : AssetImage(
                            product.image.isNotEmpty
                                ? product.image
                                : 'assets/img2.png',
                          ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.brand,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 10),
                const SizedBox(width: 2),
                Text(
                  '${product.rating}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${product.price.toInt()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(String label, double progress) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textDark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required String name,
    required String label,
    required String time,
    required String review,
    required int rating,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            Text(
              time,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            rating,
            (_) => const Icon(Icons.star, size: 14, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          review,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsContainer() {
    final double avgScore = (_ratingStats != null && _ratingStats!.averageScore > 0)
        ? _ratingStats!.averageScore
        : (_productRatings.isNotEmpty
            ? _productRatings.fold<double>(0, (prev, r) => prev + r.score) /
                _productRatings.length
            : _currentProduct.rating);

    final int totalReviewsCount =
        (_ratingStats != null && _ratingStats!.totalRatings > 0)
            ? _ratingStats!.totalRatings
            : (_productRatings.isNotEmpty ? _productRatings.length : 2450);

    final int totalListCount = _productRatings.length;
    final int count5 = _productRatings.where((r) => r.score == 5).length;
    final int count4 = _productRatings.where((r) => r.score == 4).length;
    final int count3 = _productRatings.where((r) => r.score == 3).length;
    final int count2 = _productRatings.where((r) => r.score == 2).length;
    final int count1 = _productRatings.where((r) => r.score == 1).length;

    final double p5 = totalListCount > 0 ? count5 / totalListCount : 0.85;
    final double p4 = totalListCount > 0 ? count4 / totalListCount : 0.10;
    final double p3 = totalListCount > 0 ? count3 / totalListCount : 0.03;
    final double p2 = totalListCount > 0 ? count2 / totalListCount : 0.01;
    final double p1 = totalListCount > 0 ? count1 / totalListCount : 0.01;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showWriteReviewBottomSheet,
                icon: const Icon(Icons.rate_review_outlined,
                    color: Colors.white, size: 16),
                label: const Text(
                  'Write Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avgScore.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviewsCount Reviews',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar('5', p5),
                    const SizedBox(height: 6),
                    _buildRatingBar('4', p4),
                    const SizedBox(height: 6),
                    _buildRatingBar('3', p3),
                    const SizedBox(height: 6),
                    _buildRatingBar('2', p2),
                    const SizedBox(height: 6),
                    _buildRatingBar('1', p1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (_isLoadingRatings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_productRatings.isNotEmpty)
            Column(
              children: _productRatings.map((item) {
                final name = item.user?.fullName.isNotEmpty == true
                    ? item.user!.fullName
                    : 'Verified Buyer';
                String dateStr = item.createdAt;
                if (dateStr.length >= 10) {
                  dateStr = dateStr.substring(0, 10);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewItem(
                    name: name,
                    label: 'Verified Buyer',
                    time: dateStr.isNotEmpty ? dateStr : 'Recently',
                    review: item.review,
                    rating: item.score,
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: [
                _buildReviewItem(
                  name: 'Sarah M.',
                  label: 'Verified Buyer',
                  time: '2 days ago',
                  review:
                      'Noticeable difference in energy! I\'ve been taking these for a month now and I definitely feel more energetic throughout the day without any crash. Highly recommend.',
                  rating: 5,
                ),
                const SizedBox(height: 12),
                _buildReviewItem(
                  name: 'David L.',
                  label: 'Verified Buyer',
                  time: '1 week ago',
                  review:
                      'Good quality supplement. Pills are a bit large, but they go down easy enough. Seems like a very comprehensive blend of vitamins.',
                  rating: 5,
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showWriteReviewBottomSheet() {
    if (!_appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to submit a rating & review.'),
          action: SnackBarAction(
            label: 'Log In',
            textColor: Colors.amber,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    int selectedScore = 5;
    final reviewController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Write a Review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      _currentProduct.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            starValue <= selectedScore
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setModalState(() {
                              selectedScore = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this product...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (reviewController.text.trim().isEmpty) {
                                  setModalState(() {
                                    errorMessage =
                                        'Please write a review text before submitting.';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });

                                final res = await _appState.submitRating(
                                  targetId: _currentProduct.id,
                                  targetType: 'product',
                                  score: selectedScore,
                                  review: reviewController.text.trim(),
                                );

                                if (res.success) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(res.message.isNotEmpty
                                            ? res.message
                                            : 'Rating submitted successfully!'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                    _fetchRatings();
                                  }
                                } else {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorMessage = res.message.isNotEmpty
                                        ? res.message
                                        : 'Failed to submit rating. Please try again.';
                                  });
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
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
            );
          },
        );
      },
    );
  }

  Widget _buildCollapsibleHeader(
    String title,
    bool isExpanded,
    ValueChanged<bool> onToggle,
  ) {
    return ListTile(
      onTap: () => onToggle(!isExpanded),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textDark,
        ),
      ),
      trailing: Icon(
        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        color: AppColors.primary,
      ),
    );
  }

  void _showAskQuestionDialog() {
    final TextEditingController questionController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ask a Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Have a question about ${_currentProduct.name}? Ask below and our experts will answer.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: questionController,
                    maxLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. Is this multivitamin suitable for vegetarians?',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = questionController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please type a question before submitting.'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final response = await ProductFaqService.askQuestion(
                                productId: _currentProduct.id,
                                question: text,
                                token: _appState.authToken,
                              );

                              if (!mounted) return;
                              Navigator.pop(context);

                              if (response.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.message ??
                                          'Question submitted. It will appear once answered and approved.',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                _fetchLiveDetails();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      response.message ?? 'Failed to submit question.',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Question',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  const _BenefitRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
