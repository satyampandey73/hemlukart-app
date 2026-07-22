import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'dashboard_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

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
        title: const Text('Track Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track Order Header Title Panel
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Order Tracking',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Track the live status of your medical supplies.',
                          style: TextStyle(color: AppColors.textLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ORDER ID',
                        style: TextStyle(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order.id,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stepper Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTrackerStep('Placed', true),
                      _buildTrackerConnector(true),
                      _buildTrackerStep('Confirmed', true, icon: Icons.assignment_turned_in_outlined),
                      _buildTrackerConnector(true),
                      _buildTrackerStep('Dispatched', true, icon: Icons.local_shipping_outlined),
                      _buildTrackerConnector(false),
                      _buildTrackerStep('Delivered', false, icon: Icons.home_outlined),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue box
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Current Status: In Transit. Your package is on the way to the final delivery hub.',
                            style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Logistics & Address cards (Row)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'LOGISTICS PARTNER',
                              style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'BlueDart',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'AWB: 7789054321',
                          style: TextStyle(fontSize: 10, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'DELIVERY ADDRESS',
                              style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Rahul Sharma',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Flat 402, Green Valley Apartments, Bengaluru - 560034',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timeline Card
            const Text(
              'Activity Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    'In Transit',
                    'Package has reached the Bengaluru regional sorting facility.',
                    'Oct 12, 2024 • 11:00 AM',
                    isCurrent: true,
                  ),
                  _buildTimelineItem(
                    'Picked Up by Courier',
                    'Carrier collected parcel from dispatch dock.',
                    'Oct 11, 2024 • 04:00 PM',
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    'Packed',
                    'Order has been packed in secure medical-grade packaging.',
                    'Oct 11, 2024 • 09:00 AM',
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    'Order Confirmed',
                    'Merchant accepted request.',
                    'Oct 10, 2024 • 02:30 PM',
                    isCurrent: false,
                  ),
                  _buildTimelineItem(
                    'Order Placed',
                    'Payment processed successfully.',
                    'Oct 10, 2024 • 10:00 AM',
                    isCurrent: false,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Summary Card
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
                    children: const [
                      Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Order Summary',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 26.0),
                    child: Text(
                      '$totalItemsCount items in this shipment',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  ),
                  const Divider(height: 20),
                  Column(
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Image.asset(
                                item.product.image.isNotEmpty ? item.product.image : 'assets/img2.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
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
                                    'Qty: ${item.quantity} • ${item.product.brand}',
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
                  const Divider(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading invoice...')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Download Invoice',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Consultation Promo Banner (Doctor picture matching Figma)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need Medical Advice?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Consult with certified Ayurveda & Homeopathy practitioners online.',
                          style: TextStyle(color: Colors.white70, fontSize: 10, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardScreen(initialTab: 1)),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Consult Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Display Doctor Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('assets/doctor_profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recommended Products
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
    );
  }

  Widget _buildTrackerStep(String label, bool isDone, {IconData icon = Icons.check}) {
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

  Widget _buildTimelineItem(String title, String desc, String time, {required bool isCurrent, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: isCurrent ? 5.5 : 4,
              backgroundColor: isCurrent ? AppColors.success : Colors.blue[400],
            ),
            if (!isLast) Container(width: 1.5, height: 42, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isCurrent ? AppColors.primary : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textLight, fontSize: 10, height: 1.4),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  color: isCurrent ? AppColors.secondary : Colors.grey,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
