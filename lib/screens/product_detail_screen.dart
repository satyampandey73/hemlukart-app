import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
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
    final prod = widget.product;
    final isWish = _appState.wishlistProductIds.contains(prod.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(prod.brand, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _buildCartIconBtn(),
          IconButton(
            icon: Icon(isWish ? Icons.favorite : Icons.favorite_border, color: Colors.white),
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
              height: 250,
              width: double.infinity,
              color: Colors.white,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: AssetImage(prod.image.isNotEmpty ? prod.image : 'assets/img2.png'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(4)),
                        child: const Text('Prescription Required', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Details Container
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prod.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text('${prod.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${prod.reviewsCount} Customer Reviews', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${prod.price.toInt()}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text(
                        '₹${prod.originalPrice.toInt()}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textLight, decoration: TextDecoration.lineThrough),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save ${((prod.originalPrice - prod.price) / prod.originalPrice * 100).toInt()}%',
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Attributes selectors (Pack Size, Potency, Flavour)
                  const Text('Pack Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: _packSizes.map((size) {
                      final isSel = _selectedPackSize == size;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(size),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPackSize = size);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text('Potency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: _potencies.map((potency) {
                      final isSel = _selectedPotency == potency;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(potency),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPotency = potency);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text('Flavour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: _flavours.map((flavour) {
                      final isSel = _selectedFlavour == flavour;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(flavour),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedFlavour = flavour);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontSize: 12),
                        ),
                      );
                    }).toList(),
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
                            Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                content: Text('Added $_qty x ${prod.name} to cart!'),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
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
                  _buildCollapsibleHeader('Product Description', _descExpanded, (val) => setState(() => _descExpanded = val)),
                  if (_descExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(prod.description, style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5)),
                    ),
                  const Divider(height: 1),
                  _buildCollapsibleHeader('Key Benefits', _benefitsExpanded, (val) => setState(() => _benefitsExpanded = val)),
                  if (_benefitsExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _BenefitRow('Provides natural energy enhancement without caffeine crashes.'),
                          _BenefitRow('Fortifies daily immunity defense with traditional Ayurvedic antioxidants.'),
                          _BenefitRow('Supports gut metabolism and healthy nutrient absorption levels.'),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  _buildCollapsibleHeader('Ingredients', _ingredientsExpanded, (val) => setState(() => _ingredientsExpanded = val)),
                  if (_ingredientsExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text('Pure extracts of ${prod.name.split(' ').first}, Organic Cellulose, Plant Stearates, Silica, Minerals.', style: const TextStyle(color: AppColors.textLight, fontSize: 13, height: 1.5)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader(String title, bool isExpanded, ValueChanged<bool> onToggle) {
    return ListTile(
      onTap: () => onToggle(!isExpanded),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
      trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.primary),
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
          const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textDark, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }
}
