import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_service.dart';
import 'product_detail_screen.dart';
import 'doctor_profile_screen.dart';
import '../widgets/product_quantity_selector.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  late TabController _tabController;
  bool _isLoadingDoctors = true;
  List<Doctor> _loadedDoctors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _appState.addListener(_onAppStateChanged);
    _loadData();
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDoctors = true;
    });

    await Future.wait([
      _appState.fetchUserWishlistProducts(),
      _appState.fetchUserWishlistDoctors(),
    ]);

    final List<Doctor> allDocs = [..._appState.mockDoctors];

    // Fetch doctors list from backend
    final res = await DoctorService.getAllDoctors();
    if (res.success && res.doctors.isNotEmpty) {
      final enriched = await DoctorService.enrichDoctorsWithDetails(res.doctors);
      for (final apiDoc in enriched) {
        final docObj = Doctor.fromApiDoctor(apiDoc);
        if (!allDocs.any((d) => d.id == docObj.id)) {
          allDocs.add(docObj);
        }
      }
    }

    // For any wishlisted doctor ID not yet loaded, fetch directly by ID
    final wishIds = _appState.wishlistDoctorIds;
    final missingIds =
        wishIds.where((id) => !allDocs.any((d) => d.id == id)).toList();

    for (final id in missingIds) {
      final docRes = await DoctorService.getDoctorById(id);
      if (docRes.success && docRes.doctor != null) {
        final docObj = Doctor.fromApiDoctor(docRes.doctor!);
        if (!allDocs.any((d) => d.id == docObj.id)) {
          allDocs.add(docObj);
        }
      }
    }

    if (mounted) {
      setState(() {
        _loadedDoctors = allDocs;
        _isLoadingDoctors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gather wishlist items
    final wishProducts = _appState.products
        .where((p) => _appState.wishlistProductIds.contains(p.id))
        .toList();
    final wishDoctors = _loadedDoctors
        .where((d) => _appState.wishlistDoctorIds.contains(d.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'Medicines (${wishProducts.length})'),
            Tab(text: 'Doctors (${wishDoctors.length})'),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Medicines Grid
            wishProducts.isEmpty
                ? _buildEmptyState(
                    'No medicines saved in wishlist.',
                    Icons.bookmark_border,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: wishProducts.length,
                    itemBuilder: (context, idx) {
                      final prod = wishProducts[idx];
                      return _buildProductCard(prod);
                    },
                  ),

            // Doctors List
            _isLoadingDoctors || _appState.isLoadingDoctorWishlist
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : wishDoctors.isEmpty
                    ? _buildEmptyState(
                        'No doctors saved in wishlist.',
                        Icons.person_outline,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: wishDoctors.length,
                        itemBuilder: (context, idx) {
                          final doc = wishDoctors[idx];
                          return _buildDoctorListItem(doc);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product prod) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
        );
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
                        image: (prod.image.startsWith('http://') ||
                                prod.image.startsWith('https://'))
                            ? NetworkImage(prod.image) as ImageProvider
                            : AssetImage(
                                prod.image.isNotEmpty
                                    ? prod.image
                                    : 'assets/img2.png',
                              ),
                        fit: BoxFit.contain,
                        onError: (_, __) {},
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
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prod.brand,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prod.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${prod.price.toInt()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                ProductQuantitySelector(product: prod, iconSize: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorListItem(Doctor doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (doc.image.startsWith('http://') || doc.image.startsWith('https://'))
                ? NetworkImage(doc.image) as ImageProvider
                : AssetImage(
                    doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png',
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${doc.degree} • ${doc.specialty}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${doc.getFeeForType().toInt()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final res = await _appState.toggleDoctorWishlist(doc.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.message.isNotEmpty
                          ? res.message
                          : 'Removed from wishlist',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorProfileScreen(doctor: doc),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Consult',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
