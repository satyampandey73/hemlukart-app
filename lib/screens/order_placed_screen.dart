import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../constants/order_status.dart';
import 'dashboard_screen.dart';
import 'order_tracking_screen.dart';
import 'product_detail_screen.dart';

class OrderPlacedScreen extends StatefulWidget {
  final Order order;
  const OrderPlacedScreen({super.key, required this.order});

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    if (_appState.apiProducts.isEmpty) {
      _appState.fetchProductsFromApi();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalItemsCount = 0;
    double subtotal = 0.0;
    for (var item in widget.order.items) {
      totalItemsCount += item.quantity;
      subtotal += (item.product.price * item.quantity);
    }

    final products = _appState.apiProducts;
    final orderDisplayNo = widget.order.orderNo != null && widget.order.orderNo!.isNotEmpty
        ? widget.order.orderNo!
        : 'OD-${widget.order.id}';

    final parsedStatus = OrderStatusHelper.parse(widget.order.status);
    final statusColor = OrderStatusHelper.getColor(parsedStatus);
    final statusLabel = OrderStatusHelper.getLabel(parsedStatus);
    final statusIcon = OrderStatusHelper.getIcon(parsedStatus);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Order Confirmation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Header Card Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // Large Checkmark Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Order Placed Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order No: $orderDisplayNo',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${widget.order.orderDate}',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery & Payment Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Delivery & Payment Info',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.order.deliveryAddress!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            const Icon(Icons.payment_outlined, size: 16, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Mode: ${(widget.order.paymentMode ?? "Online Payment").toUpperCase()}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Items Ordered Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Items Ordered',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            Text(
                              '$totalItemsCount Item${totalItemsCount == 1 ? "" : "s"}',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (widget.order.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: Text(
                                'No item details available for this order',
                                style: TextStyle(color: AppColors.textLight, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: widget.order.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundLight.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                                      ),
                                      child: _buildProductImage(item.product.image),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Brand: ${item.product.brand.isNotEmpty ? item.product.brand : "Chikitsakart"} • Qty: ${item.quantity}',
                                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        const Divider(height: 20),

                        // Price Breakdown
                        if (subtotal > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                              Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (widget.order.discount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount Saved', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                              Text('- ₹${widget.order.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                            Text(
                              widget.order.shippingCharge <= 0
                                  ? 'FREE'
                                  : '₹${widget.order.shippingCharge.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.order.shippingCharge <= 0 ? Colors.green : AppColors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand Total Paid',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                            Text(
                              '₹${widget.order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Column
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            order: widget.order,
                            orderId: widget.order.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Track Order Status',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialTab: 0)),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 16),
                          label: const Text(
                            'Continue Shopping',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialTab: 4)),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 16),
                          label: const Text(
                            'My Account',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recommended Products Section
                  if (products.isNotEmpty) ...[
                    const Text(
                      'Recommended Products',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 185,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, idx) {
                          final p = products[idx];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                              );
                            },
                            child: Container(
                              width: 135,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: _buildProductImage(p.image),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 10, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${p.rating}',
                                        style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${p.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Image.asset('assets/img2.png', fit: BoxFit.contain),
      );
    } else {
      return Image.asset(
        imagePath.isNotEmpty ? imagePath : 'assets/img2.png',
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Image.asset('assets/img2.png', fit: BoxFit.contain),
      );
    }
  }
}
