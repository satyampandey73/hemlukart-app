import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class MedicineListingScreen extends StatefulWidget {
  const MedicineListingScreen({super.key});

  @override
  State<MedicineListingScreen> createState() => _MedicineListingScreenState();
}

class _MedicineListingScreenState extends State<MedicineListingScreen> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
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
    );
  }
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Ayurveda', 'Allopathy', 'Supplements'];
  final List<Map<String, dynamic>> _healthConcerns = [
    {'name': 'Heart Care', 'icon': Icons.favorite_border},
    {'name': 'Diabetes', 'icon': Icons.water_drop_outlined},
    {'name': 'Stomach Care', 'icon': Icons.healing_outlined},
    {'name': 'Liver Care', 'icon': Icons.shield_outlined},
    {'name': 'Kidney Care', 'icon': Icons.clean_hands_outlined},
    {'name': 'Respiratory', 'icon': Icons.air_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _appState.mockProducts.where((prod) {
      return _selectedCategory == 'All' || prod.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight.withOpacity(0.2),
      body: Column(
        children: [
          // Header search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            color: AppColors.primary,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Medicines Store', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Deliver to 452001', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        _buildCartIconBtn(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.textLight, size: 20),
                      SizedBox(width: 8),
                      Text('Search medicines, brands, active salts...', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories horizontal list
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),

          // Scrollable shop floor
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health concerns section
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Text('Shop by Health Concerns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _healthConcerns.length,
                      itemBuilder: (context, idx) {
                        final concern = _healthConcerns[idx];
                        return Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(concern['icon'], color: AppColors.primary, size: 20),
                              const SizedBox(height: 6),
                              Text(concern['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // PLUS Banner
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Get Expert Consultation Instantly', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(height: 4),
                                Text('Join our PLUS membership for free consults & 5% discount on medicines.', style: TextStyle(color: Colors.white60, fontSize: 9)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Explore Now', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Grid Products listing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('$_selectedCategory Products', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  ),
                  const SizedBox(height: 12),

                  filteredProducts.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No products in this category.')))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, idx) {
                            final prod = filteredProducts[idx];
                            return _buildProductItem(prod);
                          },
                        ),

                  // Brand Banner
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Top Ayurvedic Brands', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildBrandCircle('Dabur'),
                        _buildBrandCircle('Baidyanath'),
                        _buildBrandCircle('Himalaya'),
                        _buildBrandCircle('Patanjali'),
                        _buildBrandCircle('Tata 1mg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product prod) {
    final isWish = _appState.wishlistProductIds.contains(prod.id);
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)));
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
                        image: AssetImage(prod.image.isNotEmpty ? prod.image : 'assets/img2.png'),
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
                  if (prod.isPrescriptionRequired)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(4)),
                        child: const Text('Rx', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(prod.brand, style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              prod.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.2),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 10),
                const SizedBox(width: 2),
                Text('${prod.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('(${prod.reviewsCount})', style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${prod.price.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    if (prod.price < prod.originalPrice)
                      Text(
                        '₹${prod.originalPrice.toInt()}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textLight, decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _appState.addToCart(prod, qty: 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${prod.name} added to cart!'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'View Cart',
                          textColor: Colors.amber,
                          onPressed: () async {
                            if (await LoginScreen.checkAndNavigate(context)) {
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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

  Widget _buildBrandCircle(String name) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
