import 'dart:async';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'clinic_listing_screen.dart';
import '../widgets/product_quantity_selector.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

class ProductCatalogScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryId;
  final String? initialSearchQuery;
  const ProductCatalogScreen({
    super.key,
    this.initialCategory,
    this.initialCategoryId,
    this.initialSearchQuery,
  });

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final AppState _appState = AppState();

  // Search & Filter State
  String _searchQuery = '';
  bool _isGridView = true;
  String _sortBy = 'Relevance';

  // Filter selections
  final Set<String> _selectedCategories = {};
  double _minPrice = 0;
  double _maxPrice = 2000;
  final Set<String> _selectedBrands = {};
  String _selectedBrandQuery = '';
  int _selectedDiscountMin = 0; // 0, 10, 20, 30, 40, 50
  String _prescriptionFilter = 'All'; // 'All', 'Rx Required', 'Non-Rx'
  double _minRating = 0.0; // 0.0, 3.0, 4.0

  final TextEditingController _searchController = TextEditingController();
  late final PageController _promoBannerController;
  int _currentPromoBannerIndex = 0;
  Timer? _promoBannerTimer;

  List<BannerModel> _productsBanners = [];
  bool _isLoadingProductsBanners = false;

  final List<String> _allCategories = [
    'Health Care',
    'Herbal Medicine',
    'Digestive Care',
    'Ayurvedic',
    'Personal Care',
    'Immunity Boosters',
    'Allopathy',
    'Supplements',
  ];

  final List<String> _allBrands = [
    'Baidyanath',
    'Kerala Ayurveda',
    'Dabur',
    'Himalaya Wellness',
    'Zandu',
    'Maharishi Ayurveda',
    'Organic India',
    'Medisynth',
    'GreenLeaf Nutrition',
  ];

  final List<String> _sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
    'Discount: High to Low',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategories.add(widget.initialCategory!);
    }
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    _promoBannerController = PageController(viewportFraction: 0.92);
    _appState.addListener(_rebuild);
    _startPromoBannerAutoSlide();
    _fetchProductsBanners();
    _appState.fetchProductsFromApi(
      categoryId: widget.initialCategoryId,
      search: widget.initialSearchQuery,
    );
  }

  @override
  void dispose() {
    _promoBannerTimer?.cancel();
    _promoBannerController.dispose();
    _searchController.dispose();
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _startPromoBannerAutoSlide() {
    _promoBannerTimer?.cancel();
    _promoBannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_promoBannerController.hasClients) return;
      final count = _productsBanners.isNotEmpty ? _productsBanners.length : 3;
      final nextIndex = (_currentPromoBannerIndex + 1) % count;
      _promoBannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchProductsBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingProductsBanners = true);

    final response = await BannerService.getProductsBanners();
    if (!mounted) return;

    if (response.success && response.banners.isNotEmpty) {
      final active = response.banners
          .where((b) => b.isActive && !b.isDeleted)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _productsBanners = active.isNotEmpty ? active : response.banners;
        _isLoadingProductsBanners = false;
      });
    } else {
      setState(() => _isLoadingProductsBanners = false);
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategories.isNotEmpty) count++;
    if (_minPrice > 0 || _maxPrice < 2000) count++;
    if (_selectedBrands.isNotEmpty) count++;
    if (_selectedDiscountMin > 0) count++;
    if (_prescriptionFilter != 'All') count++;
    if (_minRating > 0) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _minPrice = 0;
      _maxPrice = 2000;
      _selectedBrands.clear();
      _selectedBrandQuery = '';
      _selectedDiscountMin = 0;
      _prescriptionFilter = 'All';
      _minRating = 0.0;
    });
  }

  List<Product> _getFilteredProducts() {
    return _appState.products.where((prod) {
      // Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = prod.name.toLowerCase().contains(q);
        final brandMatch = prod.brand.toLowerCase().contains(q);
        final catMatch = prod.category.toLowerCase().contains(q);
        if (!nameMatch && !brandMatch && !catMatch) return false;
      }

      // Categories
      if (_selectedCategories.isNotEmpty) {
        if (!_selectedCategories.contains(prod.category)) return false;
      }

      // Price Range
      if (prod.price < _minPrice || prod.price > _maxPrice) return false;

      // Brands
      if (_selectedBrands.isNotEmpty) {
        if (!_selectedBrands.contains(prod.brand)) return false;
      }

      // Discount %
      final discountPct =
          ((prod.originalPrice - prod.price) / prod.originalPrice) * 100;
      if (discountPct < _selectedDiscountMin) return false;

      // Prescription Required
      if (_prescriptionFilter == 'Rx Required' && !prod.isPrescriptionRequired)
        return false;
      if (_prescriptionFilter == 'Non-Rx' && prod.isPrescriptionRequired)
        return false;

      // Vendor Rating
      if (prod.rating < _minRating) return false;

      return true;
    }).toList()..sort((a, b) {
      if (_sortBy == 'Price: Low to High') {
        return a.price.compareTo(b.price);
      } else if (_sortBy == 'Price: High to Low') {
        return b.price.compareTo(a.price);
      } else if (_sortBy == 'Rating: High to Low') {
        return b.rating.compareTo(a.rating);
      } else if (_sortBy == 'Discount: High to Low') {
        final discA = ((a.originalPrice - a.price) / a.originalPrice);
        final discB = ((b.originalPrice - b.price) / b.originalPrice);
        return discB.compareTo(discA);
      }
      return 0; // Relevance default
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPromoBanners(),
                  _buildBreadcrumbAndControls(filteredProducts.length),
                  if (_activeFilterCount > 0) _buildActiveFilterChips(),
                  const SizedBox(height: 8),
                  filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : (_isGridView
                            ? _buildProductsGrid(filteredProducts)
                            : _buildProductsList(filteredProducts)),
                  const SizedBox(height: 24),
                  _buildShowMoreButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildTopHeader(BuildContext context) {
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
                    'Chikitsakart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClinicListingScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_hospital_outlined, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Clinics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                 
                  const SizedBox(width: 22),
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
          // Search input box
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
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    onSubmitted: (val) {
                      _appState.fetchProductsFromApi(
                        categoryId: widget.initialCategoryId,
                        search: val.trim(),
                      );
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search for Medicines, Brands and more...',
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
                      setState(() {
                        _searchQuery = '';
                      });
                      _appState.fetchProductsFromApi(
                        categoryId: widget.initialCategoryId,
                      );
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

  // ---------------- PROMO BANNERS (from API: products/banner) ----------------
  Widget _buildPromoBanners() {
    if (_isLoadingProductsBanners) {
      return Container(
        height: 148,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_productsBanners.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 148,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _promoBannerController,
              itemCount: _productsBanners.length,
              onPageChanged: (index) {
                if (mounted) setState(() => _currentPromoBannerIndex = index);
              },
              itemBuilder: (context, idx) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _productsBanners[idx].imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
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
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.border,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_productsBanners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_productsBanners.length, (index) {
                final isActive = index == _currentPromoBannerIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- BREADCRUMB & CONTROL BAR ----------------
  Widget _buildBreadcrumbAndControls(int totalItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          const Text(
            'Home > Medicines',
            style: TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $totalItems items',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  // View mode toggle
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: _isGridView
                          ? AppColors.primary
                          : AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list_rounded,
                      color: !_isGridView
                          ? AppColors.primary
                          : AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                  const SizedBox(width: 4),
                  // Filter Button
                  ElevatedButton.icon(
                    onPressed: _openFilterBottomSheet,
                    icon: const Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Row(
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_activeFilterCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sort selection dropdown chip
          Row(
            children: [
              const Text(
                'Sort by: ',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
              DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                underline: const SizedBox(),
                items: _sortOptions.map((opt) {
                  return DropdownMenuItem<String>(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sortBy = val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- ACTIVE FILTER CHIPS ----------------
  Widget _buildActiveFilterChips() {
    final List<Widget> chips = [];

    for (var cat in _selectedCategories) {
      chips.add(
        _buildChip(cat, () {
          setState(() => _selectedCategories.remove(cat));
        }),
      );
    }
    if (_minPrice > 0 || _maxPrice < 2000) {
      chips.add(
        _buildChip('₹${_minPrice.toInt()} - ₹${_maxPrice.toInt()}', () {
          setState(() {
            _minPrice = 0;
            _maxPrice = 2000;
          });
        }),
      );
    }
    for (var b in _selectedBrands) {
      chips.add(
        _buildChip(b, () {
          setState(() => _selectedBrands.remove(b));
        }),
      );
    }
    if (_selectedDiscountMin > 0) {
      chips.add(
        _buildChip('${_selectedDiscountMin}%+ Off', () {
          setState(() => _selectedDiscountMin = 0);
        }),
      );
    }
    if (_prescriptionFilter != 'All') {
      chips.add(
        _buildChip(_prescriptionFilter, () {
          setState(() => _prescriptionFilter = 'All');
        }),
      );
    }
    if (_minRating > 0) {
      chips.add(
        _buildChip('${_minRating.toInt()}★ & Above', () {
          setState(() => _minRating = 0.0);
        }),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips,
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.cancel, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ---------------- PRODUCTS GRID VIEW ----------------
  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: products.length,
      itemBuilder: (context, idx) {
        return _buildGridProductCard(products[idx]);
      },
    );
  }

  Widget _buildSizeSelector(Product prod) {
    final String packText = prod.packSize.isNotEmpty ? prod.packSize : '1 Pack';
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                packText,
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
    );
  }

  Widget _buildGridProductCard(Product prod) {
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                  // Wishlist Icon
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _appState.toggleProductWishlist(prod.id);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWish ? Icons.favorite : Icons.favorite_border,
                          color: isWish ? Colors.pink : AppColors.textLight,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Rx Tag
                  if (prod.isPrescriptionRequired)
                    Positioned(
                      top: 4,
                      left: 4,
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
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Discount Tag
                  if (discountPct > 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
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
                    fontSize: 8,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSizeSelector(prod),
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
                          fontSize: 9,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                ProductQuantitySelector(product: prod),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- PRODUCTS LIST VIEW ----------------
  Widget _buildProductsList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, idx) {
        return _buildListProductCard(products[idx]);
      },
    );
  }

  Widget _buildListProductCard(Product prod) {
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: (prod.image.startsWith('http://') ||
                          prod.image.startsWith('https://'))
                      ? NetworkImage(prod.image) as ImageProvider
                      : AssetImage(
                          prod.image.isNotEmpty ? prod.image : 'assets/img2.png',
                        ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prod.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prod.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
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
                        '(${prod.reviewsCount} reviews)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSizeSelector(prod),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '₹${prod.price.toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (prod.price < prod.originalPrice)
                            Text(
                              '₹${prod.originalPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          if (discountPct > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '$discountPct% OFF',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      ProductQuantitySelector(product: prod),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- EMPTY STATE ----------------
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 60, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'No matching products found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try clearing your search query or filters.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _clearAllFilters,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Clear All Filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SHOW MORE / LOAD MORE ----------------
  Widget _buildShowMoreButton() {
    return Center(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Show More',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ---------------- FILTER BOTTOM SHEET (Reference Image Mobile Adaption) ----------------
  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Header bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.filter_list, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              _clearAllFilters();
                              setModalState(() {});
                            },
                            child: const Text(
                              'CLEAR ALL',
                              style: TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  // Filter Scroll Area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CATEGORIES
                          _buildFilterSectionTitle('Categories'),
                          ..._allCategories.map((cat) {
                            final isSelected = _selectedCategories.contains(
                              cat,
                            );
                            return CheckboxListTile(
                              title: Text(
                                cat,
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: isSelected,
                              activeColor: AppColors.primary,
                              dense: true,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _selectedCategories.add(cat);
                                  } else {
                                    _selectedCategories.remove(cat);
                                  }
                                });
                                setState(() {});
                              },
                            );
                          }),

                          const Divider(height: 24),

                          // PRICE SLIDER
                          _buildFilterSectionTitle('Price Range (₹)'),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${_minPrice.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '₹${_maxPrice.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 2000,
                            divisions: 40,
                            activeColor: AppColors.primary,
                            labels: RangeLabels(
                              '₹${_minPrice.toInt()}',
                              '₹${_maxPrice.toInt()}',
                            ),
                            onChanged: (vals) {
                              setModalState(() {
                                _minPrice = vals.start;
                                _maxPrice = vals.end;
                              });
                              setState(() {});
                            },
                          ),

                          const Divider(height: 24),

                          // BRANDS WITH SEARCH INPUT
                          _buildFilterSectionTitle('Brands'),
                          Container(
                            height: 36,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              onChanged: (val) {
                                setModalState(() => _selectedBrandQuery = val);
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search Brands...',
                                hintStyle: TextStyle(fontSize: 11),
                                prefixIcon: Icon(Icons.search, size: 16),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          ..._allBrands
                              .where(
                                (b) => b.toLowerCase().contains(
                                  _selectedBrandQuery.toLowerCase(),
                                ),
                              )
                              .map((brand) {
                                final isSel = _selectedBrands.contains(brand);
                                return CheckboxListTile(
                                  title: Text(
                                    brand,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  value: isSel,
                                  activeColor: AppColors.primary,
                                  dense: true,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        _selectedBrands.add(brand);
                                      } else {
                                        _selectedBrands.remove(brand);
                                      }
                                    });
                                    setState(() {});
                                  },
                                );
                              }),

                          const Divider(height: 24),

                          // DISCOUNT
                          _buildFilterSectionTitle('Discount'),
                          ...[50, 40, 30, 20, 10].map((disc) {
                            return RadioListTile<int>(
                              title: Text(
                                '$disc% or more',
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: disc,
                              groupValue: _selectedDiscountMin,
                              activeColor: AppColors.primary,
                              dense: true,
                              onChanged: (val) {
                                setModalState(() {
                                  _selectedDiscountMin =
                                      (val == _selectedDiscountMin)
                                      ? 0
                                      : (val ?? 0);
                                });
                                setState(() {});
                              },
                            );
                          }),

                          const Divider(height: 24),

                          // PRESCRIPTION REQUIRED
                          _buildFilterSectionTitle('Prescription Required'),
                          ...['All', 'Rx Required', 'Non-Rx'].map((opt) {
                            return RadioListTile<String>(
                              title: Text(
                                opt,
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: opt,
                              groupValue: _prescriptionFilter,
                              activeColor: AppColors.primary,
                              dense: true,
                              onChanged: (val) {
                                setModalState(
                                  () => _prescriptionFilter = val ?? 'All',
                                );
                                setState(() {});
                              },
                            );
                          }),

                          const Divider(height: 24),

                          // VENDOR / PRODUCT RATING
                          _buildFilterSectionTitle('Vendor / Product Rating'),
                          CheckboxListTile(
                            title: const Text(
                              '4★ and above',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: _minRating >= 4.0,
                            activeColor: AppColors.primary,
                            dense: true,
                            onChanged: (val) {
                              setModalState(
                                () => _minRating = (val == true) ? 4.0 : 0.0,
                              );
                              setState(() {});
                            },
                          ),
                          CheckboxListTile(
                            title: const Text(
                              '3★ and above',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: _minRating >= 3.0 && _minRating < 4.0,
                            activeColor: AppColors.primary,
                            dense: true,
                            onChanged: (val) {
                              setModalState(
                                () => _minRating = (val == true) ? 3.0 : 0.0,
                              );
                              setState(() {});
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Apply Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Apply Filters (${_getFilteredProducts().length} items)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
        );
      },
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
