import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/order_model.dart';
import '../services/delivery_charge_service.dart';
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
  String _selectedPaymentMethod = 'UPI'; // UPI, Card, NetBanking, COD
  bool _isPlacingOrder = false;
  late double _deliveryFee;

  late Razorpay _razorpay;
  String? _pendingBackendOrderId;
  CheckoutApiResponse? _pendingCheckoutResponse;
  List<CartItem> _pendingCartItems = [];
  ShippingAddressModel? _pendingSelectedAddress;
  double _pendingTotal = 0.0;
  String? _currentRazorpayOrderId;

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deliveryFee = widget.deliveryFee;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpayPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);

    _appState.addListener(_onStateChanged);
    if (_appState.isLoggedIn) {
      _appState.fetchShippingAddresses();
    }
    if (_appState.appliedCoupon != null) {
      _couponController.text = _appState.appliedCoupon!.code;
    }
    _verifyDeliveryCharge();
  }

  void _handleRazorpayPaymentSuccess(PaymentSuccessResponse response) async {
    final orderId = _pendingBackendOrderId;
    if (orderId == null) return;

    setState(() => _isPlacingOrder = true);

    debugPrint('┌── [Razorpay Payment Success] ──');
    debugPrint('│ Order ID: $orderId');
    debugPrint('│ Razorpay Payment ID: ${response.paymentId}');
    debugPrint('│ Razorpay Order ID: ${response.orderId}');
    debugPrint('│ Razorpay Signature: ${response.signature}');
    debugPrint('└──');

    final verifyRes = await _appState.verifyOrderPayment(
      orderId: orderId,
      razorpayOrderId: response.orderId ?? _currentRazorpayOrderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    if (verifyRes.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified & Order placed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      final selectedAddress = _pendingSelectedAddress;
      final checkoutResp = _pendingCheckoutResponse;
      final finalOrderNo = (checkoutResp?.data?.order.orderNo != null &&
              checkoutResp!.data!.order.orderNo.isNotEmpty)
          ? checkoutResp.data!.order.orderNo
          : (checkoutResp?.data?.order.id != null &&
                  checkoutResp!.data!.order.id.isNotEmpty
              ? checkoutResp.data!.order.id
              : 'OD${DateTime.now().millisecondsSinceEpoch}');

      final String formattedAddr = selectedAddress != null
          ? [
              selectedAddress.addressLine,
              selectedAddress.city,
              selectedAddress.state,
              selectedAddress.pincode
            ].where((s) => s.isNotEmpty).join(', ')
          : '';

      final placedOrder = Order(
        id: checkoutResp?.data?.order.id ?? finalOrderNo,
        orderNo: finalOrderNo,
        items: _pendingCartItems.isNotEmpty
            ? _pendingCartItems
            : (checkoutResp?.data != null
                ? checkoutResp!.data!.toOrder(_appState.apiProducts).items
                : []),
        totalAmount: (checkoutResp?.data?.order.totalAmount != null &&
                checkoutResp!.data!.order.totalAmount > 0)
            ? checkoutResp.data!.order.totalAmount
            : _pendingTotal,
        discount: (checkoutResp?.data?.order.discountAmount != null &&
                checkoutResp!.data!.order.discountAmount > 0)
            ? checkoutResp.data!.order.discountAmount
            : widget.discount,
        shippingCharge: (checkoutResp?.data?.order.shippingCharge != null &&
                checkoutResp!.data!.order.shippingCharge > 0)
            ? checkoutResp.data!.order.shippingCharge
            : _deliveryFee,
        status: 'Placed',
        orderDate: 'Just now',
        paymentMode: 'Online (Razorpay)',
        deliveryAddress: formattedAddr,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(order: placedOrder),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verifyRes.message.isNotEmpty
                ? verifyRes.message
                : 'Payment verification failed. Please contact support.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleRazorpayPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isPlacingOrder = false);
    debugPrint('❌ [Razorpay Error] code: ${response.code}, message: ${response.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message != null && response.message!.isNotEmpty
              ? 'Payment failed: ${response.message}'
              : 'Payment was cancelled or failed.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected external wallet: ${response.walletName}'),
      ),
    );
  }

  Future<void> _verifyDeliveryCharge() async {
    final res = await DeliveryChargeService.calculateDeliveryCharge(widget.subtotal);
    if (mounted) {
      setState(() {
        _deliveryFee = res.shippingCharge;
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
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

  Future<void> _processOrderPlacement(double total, double effectiveDiscount) async {
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

    setState(() => _isPlacingOrder = true);

    final isCod = _selectedPaymentMethod.toUpperCase() == 'COD';
    final paymentMode = isCod ? 'cod' : 'online';
    final paymentStatus = 'pending';
    final enteredCoupon = _couponController.text.trim();
    final String? effectiveCoupon = enteredCoupon.isNotEmpty ? enteredCoupon : _appState.appliedCoupon?.code;
    final cartItemsBeforeCheckout = List<CartItem>.from(_appState.cart);

    // Step 1: Create Order (Checkout)
    final response = await _appState.checkoutOrder(
      shippingAddressId: selectedAddress.id,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus,
      paymentProvider: isCod ? null : 'razorpay',
      couponCode: effectiveCoupon,
      clearCartOnSuccess: isCod,
    );

    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Failed to create order. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final orderId = response.data!.order.id;

    if (isCod) {
      setState(() => _isPlacingOrder = false);
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
            : response.data!.toOrder(_appState.apiProducts).items,
        totalAmount: (response.data?.order.totalAmount != null && response.data!.order.totalAmount > 0)
            ? response.data!.order.totalAmount
            : total,
        discount: (response.data?.order.discountAmount != null && response.data!.order.discountAmount > 0)
            ? response.data!.order.discountAmount
            : widget.discount,
        shippingCharge: (response.data?.order.shippingCharge != null && response.data!.order.shippingCharge > 0)
            ? response.data!.order.shippingCharge
            : _deliveryFee,
        status: response.data?.order.orderStatus ?? 'placed',
        orderDate: (response.data?.order.createdAt != null && response.data!.order.createdAt.isNotEmpty)
            ? response.data!.order.createdAt
            : 'Just now',
        paymentMode: 'Cash on Delivery',
        deliveryAddress: formattedAddr,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(order: placedOrder),
        ),
      );
      return;
    }

    // Step 2: Initiate Razorpay Payment for Online Payment
    final initiateRes = await _appState.initiateOrderPayment(orderId);
    if (!mounted) return;

    if (!initiateRes.success || initiateRes.payment == null) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            initiateRes.message.isNotEmpty
                ? 'Payment initiation failed: ${initiateRes.message}'
                : 'Unable to initiate Razorpay payment. Please try again.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Step 3: Open Razorpay Modal
    _pendingBackendOrderId = orderId;
    _pendingCheckoutResponse = response;
    _pendingCartItems = cartItemsBeforeCheckout;
    _pendingSelectedAddress = selectedAddress;
    _pendingTotal = total;
    _currentRazorpayOrderId = initiateRes.payment?.orderId;

    final payment = initiateRes.payment!;
    final num amountInPaise = payment.amount > 0 ? payment.amount : (total * 100).round();
    final String keyId = payment.keyId.isNotEmpty ? payment.keyId : 'rzp_live_TvCFkhbaRgqo6M';
    final user = _appState.currentUser;

    final options = {
      'key': keyId,
      'amount': amountInPaise,
      'currency': payment.currency.isNotEmpty ? payment.currency : 'INR',
      'name': 'Chikitsakart',
      'description': 'Order Payment',
      if (payment.orderId.isNotEmpty) 'order_id': payment.orderId,
      'prefill': {
        'name': (user?.fullName != null && user!.fullName.isNotEmpty)
            ? user.fullName
            : selectedAddress.fullName,
        'email': (user?.email != null && user!.email.isNotEmpty) ? user.email : 'patient@chikitsakart.com',
        'contact': (user?.mobile != null && user!.mobile.isNotEmpty)
            ? user.mobile
            : selectedAddress.phone,
      },
      'theme': {
        'color': '#2E7D32',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open Razorpay checkout: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double effectiveDiscount = widget.discount;
    if (_appState.appliedCoupon != null) {
      effectiveDiscount = _appState.appliedCoupon!.calculateDiscount(widget.subtotal);
    }
    double total = widget.subtotal + _deliveryFee - effectiveDiscount;

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
                        if (_appState.isDoctorLoggedIn) ...[
                          const SizedBox(height: 6),
                          _buildSummaryRow('Role Pricing', 'Doctor Discount Applied', isGreen: true),
                        ],
                        const SizedBox(height: 6),
                        _buildSummaryRow('Platform Discount', '-₹${effectiveDiscount.toStringAsFixed(2)}', isGreen: true),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                            Row(
                              children: [
                                if (_deliveryFee <= 0) ...[
                                  Text(
                                    '₹50.00',
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
                                  Text('₹${_deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      onPressed: _isPlacingOrder
                          ? null
                          : () => _processOrderPlacement(total, effectiveDiscount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isPlacingOrder
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Processing Payment...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedPaymentMethod.toUpperCase() == 'COD'
                                      ? 'Place Order (COD) • ₹${total.toStringAsFixed(2)}'
                                      : 'Pay ₹${total.toStringAsFixed(2)} with Razorpay',
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
    return Material(
      color: isEnabled ? Colors.white : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSel ? AppColors.primary : AppColors.border.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
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
