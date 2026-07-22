import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'dashboard_screen.dart';

class OrderPlacedScreen extends StatelessWidget {
  final Order order;
  const OrderPlacedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Custom recommended products list matching Figma
    final List<Map<String, dynamic>> figmaRecommendations = [
      {
        'name': 'Pure Vitamin C 1000mg',
        'rating': 4.9,
        'price': '₹450.00',
        'image': 'assets/img2.png'
      },
      {
        'name': 'Premium Omega-3 Fish Oil',
        'rating': 4.7,
        'price': '₹550.00',
        'image': 'assets/img2.png'
      },
      {
        'name': 'Magnesium Citrate 400mg',
        'rating': 4.8,
        'price': '₹399.00',
        'image': 'assets/img2.png'
      },
      {
        'name': 'Zinc Picolinate 50mg',
        'rating': 4.6,
        'price': '₹299.00',
        'image': 'assets/img2.png'
      },
    ];

    int totalItemsCount = 0;
    for (var item in order.items) {
      totalItemsCount += item.quantity;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Order Placed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Card Panel
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // Large Checkmark
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5), // Light mint green
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
                  const SizedBox(height: 4),
                  Text(
                    'Order ID: ${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Mobile Adapted Stepper Timeline
                  Row(
                    children: [
                      _buildTrackerStep('Placed', true, isFirst: true),
                      _buildTrackerConnector(false),
                      _buildTrackerStep('Confirmed', false, icon: Icons.schedule),
                      _buildTrackerConnector(false),
                      _buildTrackerStep('Dispatched', false, icon: Icons.local_shipping),
                      _buildTrackerConnector(false),
                      _buildTrackerStep('Delivered', false, icon: Icons.home_outlined),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items Ordered Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
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
                              '$totalItemsCount Items',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Column(
                          children: order.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Image.asset(
                                      item.product.image.isNotEmpty ? item.product.image : 'assets/img2.png',
                                      fit: BoxFit.contain,
                                    ),
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
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Qty: ${item.quantity} • Seller: ${item.product.brand}',
                                          style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Paid',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                            Text(
                              '₹${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions Buttons row
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialTab: 4)),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 16),
                          label: const Text(
                            'View All Orders',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recommended Products Section
                  const Text(
                    'Recommended Product',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: figmaRecommendations.length,
                      itemBuilder: (context, idx) {
                        final p = figmaRecommendations[idx];
                        return Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Image.asset(
                                      p['image'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['name'],
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
                                    '${p['rating']}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p['price'],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerStep(String label, bool isDone, {bool isFirst = false, IconData icon = Icons.check}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isDone ? AppColors.success : AppColors.border,
          child: Icon(icon, color: Colors.white, size: 11),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.primary : AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppColors.success : AppColors.border,
      ),
    );
  }
}
