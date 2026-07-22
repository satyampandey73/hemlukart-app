import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AppState _appState = AppState();
  final TextEditingController _promoController = TextEditingController();
  bool _promoApplied = false;
  double _promoDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _appState.removeListener(_rebuild);
    _promoController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = _appState.cart;

    // Calculations
    double subtotal = 0.0;
    int totalItems = 0;
    for (var item in cart) {
      subtotal += item.product.price * item.quantity;
      totalItems += item.quantity;
    }

    double delivery = subtotal > 0 && subtotal < 500 ? 50.0 : 0.0;
    if (_promoApplied) {
      _promoDiscount = subtotal * 0.1; // 10% coupon
    } else {
      _promoDiscount = 0.0;
    }

    double total = subtotal + delivery - _promoDiscount;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Your Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textLight.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add wellness products to get started.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top Cart Title Info Panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalItems items in your cart',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _appState.clearCart();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart cleared.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC21807), // Red button
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Clear Cart',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Cart List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.length,
                    itemBuilder: (context, idx) {
                      final item = cart[idx];
                      return _buildCartListItem(item);
                    },
                  ),
                ),

                // Order summary bottom panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Prices Breakdown
                        _buildPriceSummaryRow('Subtotal ($totalItems items)', '₹${subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 6),
                        _buildPriceSummaryRow('Delivery Charges', delivery == 0.0 ? 'FREE' : '₹${delivery.toStringAsFixed(2)}'),
                        if (_promoApplied) ...[
                          const SizedBox(height: 6),
                          _buildPriceSummaryRow('Discount (AYUSH10)', '-₹${_promoDiscount.toStringAsFixed(2)}', isDiscount: true),
                        ],
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Inclusive of all taxes',
                                  style: TextStyle(fontSize: 10, color: AppColors.textLight.withOpacity(0.8)),
                                ),
                              ],
                            ),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Promo code box
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _promoController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter Promo Code (AYUSH10)',
                                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Colors.grey[50],
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(color: AppColors.border.withOpacity(0.6)),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_promoController.text.toUpperCase() == 'AYUSH10') {
                                    setState(() {
                                      _promoApplied = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Promo Code AYUSH10 Applied!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid Promo Code.')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Proceed Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Verify prescription rules
                              bool missingPresc = false;
                              for (var item in cart) {
                                if (item.product.isPrescriptionRequired && item.prescriptionFile == null) {
                                  missingPresc = true;
                                  break;
                                }
                              }

                              if (missingPresc) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please upload a doctor prescription for prescription-required (Rx) medicines!'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    subtotal: subtotal,
                                    deliveryFee: delivery,
                                    discount: _promoDiscount,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Proceed to Checkout',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock_outline, size: 12, color: AppColors.textLight),
                              SizedBox(width: 4),
                              Text(
                                'Secure SSL Checkout',
                                style: TextStyle(color: AppColors.textLight, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartListItem(CartItem item) {
    final prod = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image container
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  prod.image.isNotEmpty ? prod.image : 'assets/img2.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prod.brand,
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                    const SizedBox(height: 6),

                    // Custom Tags matching Figma
                    Row(
                      children: [
                        if (prod.isPrescriptionRequired) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(color: Colors.blue[300]!, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Prescription Required',
                              style: TextStyle(color: Colors.blue[700], fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6), // Teal solid In Stock tag
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'In Stock',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[300]!, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 8, color: Colors.grey[600]),
                                const SizedBox(width: 2),
                                Text(
                                  'OTC',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[300]!, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Only 2 left',
                              style: TextStyle(color: Colors.grey[600], fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Price (Top-Right of Item Card)
              Text(
                '₹${(prod.price * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Prescription upload container (Teal-bordered dashed container)
          if (prod.isPrescriptionRequired) ...[
            CustomPaint(
              painter: DashedRectPainter(
                color: Colors.blue[300]!,
                borderRadius: 8.0,
                gap: 4.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50]!.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined, color: Colors.blue[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Prescription',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.prescriptionFile ?? 'Required for this medicine',
                            style: TextStyle(
                              color: item.prescriptionFile != null ? AppColors.success : AppColors.textLight,
                              fontSize: 9,
                              fontWeight: item.prescriptionFile != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _appState.attachPrescription(prod, 'prescription_rx_${prod.id}.pdf');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Prescription prescription_rx_${prod.id}.pdf attached.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Choose File',
                        style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1),
          const SizedBox(height: 8),

          // Bottom Action Row: Qty adjustment, Wishlist, Remove
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Qty adjusters
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _appState.updateCartQty(prod, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(Icons.remove, size: 14, color: AppColors.textDark),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _appState.updateCartQty(prod, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(Icons.add, size: 14, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),

              // Wishlist & Remove buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _appState.toggleProductWishlist(prod.id);
                      _appState.removeFromCart(prod);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Moved to Wishlist.')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, size: 12, color: AppColors.secondary),
                    label: const Text(
                      'Move to Wishlist',
                      style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _appState.removeFromCart(prod);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from Cart.')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryRow(String label, String val, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDiscount ? AppColors.success : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// Custom Painter to draw dashed rectangles for upload area
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  DashedRectPainter({
    this.color = Colors.blue,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    ));

    final dashPath = _dashPath(path, gap);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashLength) {
    if (dashLength <= 0.0) return source;
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = dashLength;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.borderRadius != borderRadius;
  }
}
