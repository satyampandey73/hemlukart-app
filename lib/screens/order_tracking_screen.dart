import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/order_model.dart';
import 'dashboard_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderTrackingScreen({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final AppState _appState = AppState();
  bool _isLoading = false;
  SingleOrderDetailData? _apiOrderDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    final String? targetId = widget.orderId ?? widget.order?.id;
    if (targetId == null || targetId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _appState.fetchOrderDetail(targetId);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success && res.data != null) {
        _apiOrderDetail = res.data;
      } else {
        _errorMessage = res.message ?? 'Failed to load order details';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final orderNo = _apiOrderDetail?.order.orderNo.isNotEmpty == true
        ? _apiOrderDetail!.order.orderNo
        : (widget.order?.orderNo ?? widget.order?.id ?? widget.orderId ?? 'ORDER');

    final orderStatus = (_apiOrderDetail?.order.orderStatus ?? widget.order?.status ?? 'placed').toLowerCase();

    final deliveryName = _apiOrderDetail?.order.deliveryName?.isNotEmpty == true
        ? _apiOrderDetail!.order.deliveryName!
        : (_appState.currentUser?.fullName ?? 'Valued Customer');

    String formattedAddress = widget.order?.deliveryAddress ?? '';
    if (_apiOrderDetail?.order != null) {
      final o = _apiOrderDetail!.order;
      final parts = [o.deliveryAddress, o.deliveryCity, o.deliveryState, o.deliveryPincode]
          .where((p) => p != null && p.isNotEmpty)
          .join(', ');
      if (parts.isNotEmpty) {
        formattedAddress = parts;
      }
    }
    if (formattedAddress.isEmpty) {
      formattedAddress = 'Address details available in order profile';
    }

    final paymentMode = (_apiOrderDetail?.order.paymentMode ?? widget.order?.paymentMode ?? 'cod').toUpperCase();
    final totalAmount = _apiOrderDetail?.order.totalAmount ?? widget.order?.totalAmount ?? 0.0;

    final historyList = _apiOrderDetail?.history ?? [];
    final itemsList = _apiOrderDetail?.items ?? [];

    int totalItemsCount = 0;
    if (itemsList.isNotEmpty) {
      for (var item in itemsList) {
        totalItemsCount += item.quantity;
      }
    } else if (widget.order != null) {
      for (var item in widget.order!.items) {
        totalItemsCount += item.quantity;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Track Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrderDetail,
            tooltip: 'Refresh Order',
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                              'ORDER NO',
                              style: TextStyle(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              orderNo,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
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
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildTrackerStep('Placed', true),
                            _buildTrackerConnector(orderStatus != 'placed'),
                            _buildTrackerStep('Confirmed', orderStatus == 'confirmed' || orderStatus == 'dispatched' || orderStatus == 'delivered', icon: Icons.assignment_turned_in_outlined),
                            _buildTrackerConnector(orderStatus == 'dispatched' || orderStatus == 'delivered'),
                            _buildTrackerStep('Dispatched', orderStatus == 'dispatched' || orderStatus == 'delivered', icon: Icons.local_shipping_outlined),
                            _buildTrackerConnector(orderStatus == 'delivered'),
                            _buildTrackerStep('Delivered', orderStatus == 'delivered', icon: Icons.home_outlined),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Current Status: ${orderStatus.toUpperCase()} • Mode: $paymentMode',
                                  style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Logistics & Address cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          height: 110,
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
                                  Icon(Icons.payment_outlined, color: AppColors.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'PAYMENT DETAILS',
                                    style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mode: $paymentMode',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${_apiOrderDetail?.order.paymentStatus ?? "pending"}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          height: 110,
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
                                  Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'DELIVERY ADDRESS',
                                    style: TextStyle(fontSize: 8, color: AppColors.textLight, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                deliveryName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: AppColors.textLight, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Timeline Card (Live API History)
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
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: historyList.isNotEmpty
                        ? Column(
                            children: List.generate(historyList.length, (idx) {
                              final h = historyList[idx];
                              return _buildTimelineItem(
                                'Status: ${h.status.toUpperCase()}',
                                h.note.isNotEmpty ? h.note : 'Updated by ${h.changedBy}',
                                _formatDate(h.createdAt),
                                isCurrent: idx == 0,
                                isLast: idx == historyList.length - 1,
                              );
                            }),
                          )
                        : Column(
                            children: [
                              _buildTimelineItem(
                                'Order ${orderStatus.toUpperCase()}',
                                'Order status updated in system',
                                _formatDate(_apiOrderDetail?.order.createdAt ?? widget.order?.orderDate),
                                isCurrent: true,
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
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            Text(
                              'Total: ₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
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

                        // Item List
                        if (itemsList.isNotEmpty)
                          Column(
                            children: itemsList.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundLight.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Image.asset(
                                        'assets/img2.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: ${item.quantity} • Unit: ₹${item.unitPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${item.itemTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        else if (widget.order != null && widget.order!.items.isNotEmpty)
                          Column(
                            children: widget.order!.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundLight.withValues(alpha: 0.3),
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

                  // Consultation Promo Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary.withValues(alpha: 0.8)],
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

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
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
