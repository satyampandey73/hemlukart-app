import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../constants/order_status.dart';
import 'order_tracking_screen.dart';
import 'product_detail_screen.dart';
import 'medicine_listing_screen.dart';
import 'login_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _appState.addListener(_onAppStateChanged);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    if (_appState.isLoggedIn) {
      if (_appState.apiProducts.isEmpty) {
        _appState.fetchProductsFromApi();
      }
      _appState.fetchMyOrders();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshOrders() async {
    if (_appState.apiProducts.isEmpty) {
      _appState.fetchProductsFromApi();
    }
    await _appState.fetchMyOrders();
  }

  // Get orders list strictly from live API state
  List<Order> _getAllOrders() {
    return _appState.orders;
  }

  bool _matchesStatus(Order order, int tabIndex) {
    final parsedStatus = OrderStatusHelper.parse(order.status);
    switch (tabIndex) {
      case 0: // All
        return true;
      case 1: // Active (placed, confirmed, seller_assigned, packed, invoice_generated, manifested, dispatched, in_transit, out_for_delivery)
        return OrderStatusHelper.isActive(parsedStatus);
      case 2: // Delivered
        return parsedStatus == OrderStatusType.delivered;
      case 3: // Returned / RTO
        return parsedStatus == OrderStatusType.rto || parsedStatus == OrderStatusType.returned;
      case 4: // Cancelled
        return parsedStatus == OrderStatusType.cancelled;
      default:
        return true;
    }
  }

  bool _matchesSearch(Order order) {
    if (_searchQuery.isEmpty) return true;
    final orderId = (order.orderNo ?? order.id).toLowerCase();
    final parsedStatus = OrderStatusHelper.parse(order.status);
    final statusLabel = OrderStatusHelper.getLabel(parsedStatus).toLowerCase();
    final itemsMatch = order.items.any((item) =>
        item.product.name.toLowerCase().contains(_searchQuery) ||
        item.product.brand.toLowerCase().contains(_searchQuery));
    return orderId.contains(_searchQuery) ||
        statusLabel.contains(_searchQuery) ||
        order.status.toLowerCase().contains(_searchQuery) ||
        itemsMatch;
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = _getAllOrders();
    final activeOrders = allOrders.where((o) => _matchesStatus(o, 1)).toList();
    final deliveredOrders = allOrders.where((o) => _matchesStatus(o, 2)).toList();
    final returnedOrders = allOrders.where((o) => _matchesStatus(o, 3)).toList();
    final cancelledOrders = allOrders.where((o) => _matchesStatus(o, 4)).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                decoration: const InputDecoration(
                  hintText: 'Search by Order # or item name...',
                  hintStyle: TextStyle(color: Color.fromARGB(179, 0, 0, 0)),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'My Orders',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrders,
            tooltip: 'Refresh Orders',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${allOrders.length})'),
            Tab(text: 'Active (${activeOrders.length})'),
            Tab(text: 'Delivered (${deliveredOrders.length})'),
            Tab(text: 'RTO/Returned (${returnedOrders.length})'),
            Tab(text: 'Cancelled (${cancelledOrders.length})'),
          ],
        ),
      ),
      body: !_appState.isLoggedIn
          ? _buildLoggedOutView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(allOrders, 0),
                _buildOrdersList(allOrders, 1),
                _buildOrdersList(allOrders, 2),
                _buildOrdersList(allOrders, 3),
                _buildOrdersList(allOrders, 4),
              ],
            ),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to view your orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep track of your purchases, deliveries, and order history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> sourceOrders, int tabIndex) {
    if (_appState.isLoadingMyOrders) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Fetching your orders...',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final filtered = sourceOrders
        .where((o) => _matchesStatus(o, tabIndex) && _matchesSearch(o))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final order = filtered[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    String title = 'No Orders Found';
    String subtitle = 'You have not placed any orders yet.';

    if (_searchQuery.isNotEmpty) {
      title = 'No Matching Orders';
      subtitle = 'No orders matched your search query "$_searchQuery".';
    } else if (tabIndex == 1) {
      title = 'No Active Orders';
      subtitle = 'You currently have no active or in-transit orders.';
    } else if (tabIndex == 2) {
      title = 'No Delivered Orders';
      subtitle = 'None of your orders have been marked as delivered yet.';
    } else if (tabIndex == 3) {
      title = 'No Returned or RTO Orders';
      subtitle = 'You have no orders marked as RTO or Returned.';
    } else if (tabIndex == 4) {
      title = 'No Cancelled Orders';
      subtitle = 'You do not have any cancelled orders.';
    }

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicineListingScreen()),
                );
              },
              icon: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 18),
              label: const Text(
                'Explore Medicines & Catalog',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final parsedStatus = OrderStatusHelper.parse(order.status);
    final statusColor = OrderStatusHelper.getColor(parsedStatus);
    final statusIcon = OrderStatusHelper.getIcon(parsedStatus);
    final statusLabel = OrderStatusHelper.getLabel(parsedStatus);

    final orderDisplayNo = order.orderNo != null && order.orderNo!.isNotEmpty
        ? order.orderNo!
        : 'OD-${order.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderDisplayNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Placed on ${order.orderDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
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

          const Divider(height: 1),

          // Order Items List Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.items.isEmpty)
                  const Text(
                    'Order details processing...',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  )
                else
                  ...order.items.map((cartItem) {
                    final prod = cartItem.product;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // Thumbnail Image
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: prod),
                                ),
                              );
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.border.withValues(alpha: 0.4),
                                ),
                                image: DecorationImage(
                                  image: (prod.image.startsWith('http://') ||
                                          prod.image.startsWith('https://'))
                                      ? NetworkImage(prod.image) as ImageProvider
                                      : AssetImage(
                                          prod.image.isNotEmpty
                                              ? prod.image
                                              : 'assets/img1.png',
                                        ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.brand.isNotEmpty ? prod.brand.toUpperCase() : 'Chikitsakart',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  prod.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${cartItem.quantity} • ₹${prod.price.toStringAsFixed(2)} each',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${(prod.price * cartItem.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const Divider(height: 1, color: AppColors.border),

                const SizedBox(height: 12),

                // Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payment, size: 14, color: AppColors.textLight),
                            const SizedBox(width: 4),
                            Text(
                              order.paymentMode ?? 'Online Payment',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        if (order.discount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Discount Saved: ₹${order.discount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              children: [
                // Reorder Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReorder(order),
                    icon: const Icon(Icons.refresh, size: 15, color: AppColors.primary),
                    label: const Text(
                      'Reorder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Track Order Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(
                            order: order,
                            orderId: order.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping_outlined, size: 15, color: Colors.white),
                    label: const Text(
                      'Track Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
  }

  void _handleReorder(Order order) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items in this order to reorder.')),
      );
      return;
    }

    for (final item in order.items) {
      _appState.addToCart(item.product, qty: item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('${order.items.length} item(s) added back to your cart!'),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
