import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'order_placed_screen.dart';
import 'shipping_addresses_screen.dart';
import '../models/shipping_address_model.dart';

class CheckoutScreen extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;

  const CheckoutScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AppState _appState = AppState();
  String _selectedPaymentMethod = 'COD'; // COD, UPI, Card, NetBanking
  bool _isPlacingOrder = false;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    if (_appState.isLoggedIn) {
      _appState.fetchShippingAddresses();
    }
    if (_appState.appliedCoupon != null) {
      _couponController.text = _appState.appliedCoupon!.code;
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _couponController.dispose();
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
    double effectiveDiscount = widget.discount;
    if (_appState.appliedCoupon != null) {
      effectiveDiscount = _appState.appliedCoupon!.calculateDiscount(widget.subtotal);
    }
    double total = widget.subtotal + widget.deliveryFee - effectiveDiscount;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stepper Progress Tracker (Figma design adapted)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  _buildStepBubble(true, 'Address', isCompleted: true),
                  _buildStepConnector(true),
                  _buildStepBubble(true, 'Payment', stepNum: '2'),
                  _buildStepConnector(false),
                  _buildStepBubble(false, 'Confirmation', stepNum: '3'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address card
                  Builder(
                    builder: (context) {
                      final selectedAddress = _appState.selectedShippingAddress;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                    ),
                                    if (selectedAddress != null && selectedAddress.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Default',
                                          style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    final ShippingAddressModel? picked = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ShippingAddressesScreen(selectMode: true),
                                      ),
                                    );
                                    if (picked != null) {
                                      _appState.selectShippingAddress(picked);
                                    }
                                  },
                                  child: Text(
                                    selectedAddress != null ? 'Change' : 'Add / Select',
                                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (selectedAddress != null) ...[
                              Text(
                                selectedAddress.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selectedAddress.formattedAddress}\n+91 ${selectedAddress.phone}',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 12, height: 1.4),
                              ),
                            ] else if (_appState.isLoadingAddresses) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                              ),
                            ] else ...[
                              const Text(
                                'No shipping address selected. Tap Change to add or choose an address.',
                                style: TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),


                  const SizedBox(height: 16),

                  // Payment method selection
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '2',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // UPI Card Accordion
                  _buildPaymentAccordion('UPI', 'UPI (GPAY, PhonePe, Paytm)', [
                    const Text(
                      'Instant payment from your bank account',
                      style: TextStyle(color: AppColors.textLight, fontSize: 11),
                    ),
                  ], leadingWidget: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                        child: const Text('GPay', style: TextStyle(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                        child: const Text('Pe', style: TextStyle(color: AppColors.textLight, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )),
                  const SizedBox(height: 10),

                  // Card Accordion
                  _buildPaymentAccordion(
                    'Card',
                    'Credit / Debit Card',
                    [
                      const Text('Visa, Mastercard, RuPay', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cardNumberController,
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          hintText: 'XXXX XXXX XXXX XXXX',
                          labelStyle: const TextStyle(fontSize: 12),
                          hintStyle: const TextStyle(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: const OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border.withOpacity(0.5))),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _expiryController,
                              decoration: InputDecoration(
                                labelText: 'Expiry (MM/YY)',
                                hintText: 'MM/YY',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: const OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border.withOpacity(0.5))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _cvvController,
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                hintText: '***',
                                labelStyle: const TextStyle(fontSize: 12),
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: const OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border.withOpacity(0.5))),
                                suffixIcon: Icon(Icons.help_outline, size: 16, color: Colors.grey[400]),
                              ),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                    icon: Icons.credit_card,
                  ),
                  const SizedBox(height: 10),

                  // Net Banking Accordion
                  _buildPaymentAccordion(
                    'NetBanking',
                    'Net Banking',
                    [
                      const Text(
                        'Secure redirect to your primary bank website.',
                        style: TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                    icon: Icons.account_balance,
                  ),
                  const SizedBox(height: 10),

                  // Cash on Delivery Accordion
                  _buildPaymentAccordion(
                    'COD',
                    'Cash on Delivery',
                    [
                      const Text(
                        'Pay cash or UPI upon delivery at your doorstep.',
                        style: TextStyle(color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                    icon: Icons.payments_outlined,
                    isEnabled: true,
                  ),

                  const SizedBox(height: 20),

                  // Order Summary Card
                  const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Real-time items list
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _appState.cart.length,
                          itemBuilder: (context, idx) {
                            final item = _appState.cart[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(height: 16),

                        // Coupon input
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: _appState.appliedCoupon != null
                                        ? 'Applied: ${_appState.appliedCoupon!.code}'
                                        : 'Enter coupon code',
                                    hintStyle: TextStyle(
                                      fontSize: 11,
                                      color: _appState.appliedCoupon != null ? AppColors.success : AppColors.textLight,
                                      fontWeight: _appState.appliedCoupon != null ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                    fillColor: Colors.grey[50],
                                    filled: true,
                                    border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border.withOpacity(0.4))),
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_appState.appliedCoupon != null) {
                                    _appState.clearAppliedCoupon();
                                    _couponController.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Coupon removed.')),
                                    );
                                  } else {
                                    final code = _couponController.text.trim();
                                    if (code.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a coupon code.')),
                                      );
                                      return;
                                    }
                                    final applied = _appState.applyCouponByCode(code, widget.subtotal);
                                    if (applied) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Coupon "${_appState.appliedCoupon!.code}" applied!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid coupon code or order minimum not met.'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _appState.appliedCoupon != null ? AppColors.error : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _appState.appliedCoupon != null ? 'Remove' : 'Apply',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildSummaryRow('Item Total', '₹${widget.subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 6),
                        _buildSummaryRow('Platform Discount', '-₹${effectiveDiscount.toStringAsFixed(2)}', isGreen: true),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                            Row(
                              children: [
                                if (widget.deliveryFee == 0) ...[
                                  Text(
                                    '₹40.00',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(0.6),
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Free',
                                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ] else ...[
                                  Text('₹${widget.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('To Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                            Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guarantee Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue box
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_user_outlined, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Safe and secure payments. 100% Authentic products guaranteed.',
                            style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Final Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : () async {
                        if (_appState.cart.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart is empty. Cannot place order.')),
                          );
                          return;
                        }

                        final selectedAddress = _appState.selectedShippingAddress;
                        if (selectedAddress == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select or add a shipping address first.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          _isPlacingOrder = true;
                        });

                        final paymentMode = _selectedPaymentMethod.toLowerCase(); // 'cod', 'upi', 'card', 'netbanking'
                        final paymentStatus = 'pending';
                        final enteredCoupon = _couponController.text.trim();
                        final String? effectiveCoupon = enteredCoupon.isNotEmpty ? enteredCoupon : _appState.appliedCoupon?.code;

                        final cartItemsBeforeCheckout = List<CartItem>.from(_appState.cart);

                        final response = await _appState.checkoutOrder(
                          shippingAddressId: selectedAddress.id,
                          paymentMode: paymentMode,
                          paymentStatus: paymentStatus,
                          couponCode: effectiveCoupon,
                        );

                        if (!mounted) return;

                        setState(() {
                          _isPlacingOrder = false;
                        });

                        if (response.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message.isNotEmpty ? response.message : 'Order created successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );

                          final String finalOrderNo = (response.data?.order.orderNo != null && response.data!.order.orderNo.isNotEmpty)
                              ? response.data!.order.orderNo
                              : (response.data?.order.id != null && response.data!.order.id.isNotEmpty
                                  ? response.data!.order.id
                                  : 'OD${DateTime.now().millisecondsSinceEpoch}');

                          final String formattedAddr = [
                            selectedAddress.addressLine,
                            selectedAddress.city,
                            selectedAddress.state,
                            selectedAddress.pincode
                          ].where((s) => s.isNotEmpty).join(', ');

                          final placedOrder = Order(
                            id: response.data?.order.id ?? finalOrderNo,
                            orderNo: finalOrderNo,
                            items: cartItemsBeforeCheckout.isNotEmpty
                                ? cartItemsBeforeCheckout
                                : (response.data != null
                                    ? response.data!.toOrder(_appState.apiProducts).items
                                    : []),
                            totalAmount: (response.data?.order.totalAmount != null && response.data!.order.totalAmount > 0)
                                ? response.data!.order.totalAmount
                                : total,
                            discount: (response.data?.order.discountAmount != null && response.data!.order.discountAmount > 0)
                                ? response.data!.order.discountAmount
                                : widget.discount,
                            status: response.data?.order.orderStatus ?? 'placed',
                            orderDate: (response.data?.order.createdAt != null && response.data!.order.createdAt.isNotEmpty)
                                ? response.data!.order.createdAt
                                : 'Just now',
                            paymentMode: _selectedPaymentMethod,
                            deliveryAddress: formattedAddr,
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderPlacedScreen(
                                order: placedOrder,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message.isNotEmpty ? response.message : 'Failed to place order.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Pay ₹${total.toStringAsFixed(2)} & Place Order',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
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

  Widget _buildStepBubble(bool isActive, String label, {bool isCompleted = false, String stepNum = '1'}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: isActive ? AppColors.primary : AppColors.border,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 12)
              : Text(
                  stepNum,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primary : AppColors.textLight,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildPaymentAccordion(
    String code,
    String label,
    List<Widget> children, {
    IconData icon = Icons.account_balance_wallet_outlined,
    bool isEnabled = true,
    Widget? leadingWidget,
  }) {
    final isSel = _selectedPaymentMethod == code;
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSel ? AppColors.primary : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: isEnabled
                ? () {
                    setState(() {
                      _selectedPaymentMethod = code;
                    });
                  }
                : null,
            leading: Icon(icon, color: isSel ? AppColors.primary : AppColors.textLight, size: 20),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isEnabled ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingWidget != null) ...[
                  leadingWidget,
                  const SizedBox(width: 8),
                ],
                isEnabled
                    ? Radio<String>(
                        value: code,
                        groupValue: _selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      )
                    : const Icon(Icons.block, size: 14, color: Colors.grey),
              ],
            ),
          ),
          if (isSel && isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isGreen ? AppColors.success : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
