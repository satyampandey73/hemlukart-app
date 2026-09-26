import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/clinic_service.dart';
import '../models/clinic_model.dart';
import 'clinic_detail_screen.dart';
import 'medicine_listing_screen.dart';
import 'doctor_consultation_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'login_screen.dart';

class ClinicListingScreen extends StatefulWidget {
  /// When [doctorId] is provided (e.g. from the Doctor Dashboard), only the
  /// clinics linked to that doctor are fetched via ?doctorId= query param.
  final String? doctorId;

  const ClinicListingScreen({super.key, this.doctorId});

  @override
  State<ClinicListingScreen> createState() => _ClinicListingScreenState();
}

class _ClinicListingScreenState extends State<ClinicListingScreen> {
  final AppState _appState = AppState();

  // Search & Filter State
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();

  String _sortBy = 'Highest Rated';

  // Selected Filter Checkboxes
  final Set<String> _selectedSpecialties = {};
  final Set<String> _selectedServices = {};
  String _selectedAvailability = 'Today';
  double _patientRating = 4.0;
  RangeValues _feeRange = const RangeValues(0, 10000);

  bool _isLoadingClinics = true;
  List<Clinic> _apiClinics = [];
  String? _clinicError;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _fetchClinics();
  }

  Future<void> _fetchClinics() async {
    if (!mounted) return;
    setState(() {
      _isLoadingClinics = true;
      _clinicError = null;
      _apiClinics = []; // reset so count is 0 during loading
    });

    final doctorId = widget.doctorId;
    final ClinicsApiResponse response;
    if (doctorId != null && doctorId.trim().isNotEmpty) {
      // Doctor dashboard: only fetch clinics linked to this doctor
      response = await ClinicService.getClinicsByDoctorId(doctorId: doctorId.trim());
    } else {
      response = await ClinicService.getClinics();
    }
    if (!mounted) return;

    if (response.success) {
      // success=true even with empty list is a valid result
      setState(() {
        _apiClinics = response.clinics.map((c) => Clinic.fromApiClinic(c)).toList();
        _clinicError = null;
        _isLoadingClinics = false;
      });
    } else {
      setState(() {
        _clinicError = response.message.isNotEmpty ? response.message : 'Failed to fetch clinics.';
        _apiClinics = [];
        _isLoadingClinics = false;
      });
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _clinicNameController.dispose();
    _locationController.dispose();
    _doctorNameController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _clearAllFilters() {
    setState(() {
      _clinicNameController.clear();
      _locationController.clear();
      _doctorNameController.clear();
      _selectedSpecialties.clear();
      _selectedServices.clear();
      _selectedAvailability = 'Today';
      _patientRating = 4.0;
      _feeRange = const RangeValues(0, 10000);
    });
  }

  int get _activeFilterCount {
    int count = 0;
    count += _selectedSpecialties.length;
    count += _selectedServices.length;
    if (_selectedAvailability != 'Today') {
      count += 1;
    }
    if (_feeRange.start > 0 || _feeRange.end < 10000) {
      count += 1;
    }
    return count;
  }

  List<Clinic> get _filteredClinics {
    final sourceList = _apiClinics;
    return sourceList.where((clinic) {
      // Unified Search (Clinic Name, Location, Specialty)
      final query = _clinicNameController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchName = clinic.name.toLowerCase().contains(query);
        final matchLoc = clinic.location.toLowerCase().contains(query);
        final matchSpec = clinic.specialty.toLowerCase().contains(query);
        final about = clinic.rawApiClinic?.about?.toLowerCase() ?? '';
        final matchAbout = about.contains(query);
        if (!matchName && !matchLoc && !matchSpec && !matchAbout) {
          return false;
        }
      }

      // Location Search (if used)
      if (_locationController.text.trim().isNotEmpty) {
        if (!clinic.location.toLowerCase().contains(
          _locationController.text.trim().toLowerCase(),
        )) {
          return false;
        }
      }

      // Specialty Filter
      if (_selectedSpecialties.isNotEmpty) {
        if (!_selectedSpecialties.contains(clinic.specialty)) {
          return false;
        }
      }

      // Services Available Filter
      if (_selectedServices.isNotEmpty) {
        bool matchService = false;
        for (var service in _selectedServices) {
          if (clinic.availableServices.contains(service)) {
            matchService = true;
            break;
          }
        }
        if (!matchService) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFEBF6F5),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Find Clinical Excellence',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WishlistScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Navigation Desktop Header (only on Desktop view)
            if (isDesktop) _buildDesktopTopHeader(),

            // Main Content Body Container
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading & Search header on Desktop
                    if (isDesktop) ...[
                      const Text(
                        'Find Clinical Excellence',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F3D39),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSearchHeaderCard(isDesktop),
                      const SizedBox(height: 24),
                    ] else ...[
                      // Modern, compact Search & Filter Bar on Mobile (takes only 48px height)
                      _buildMobileSearchAndFilterBar(),
                      const SizedBox(height: 12),
                    ],

                    // Active filters chips row on mobile
                    if (!isDesktop && _activeFilterCount > 0)
                      _buildActiveFilterChips(),

                    // Results Sub-header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '${_filteredClinics.length} Clinics ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const TextSpan(
                                text: 'found',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'SORT: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _sortBy,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 13,
                              ),
                              items:
                                  ['Highest Rated', 'Most Popular', 'Nearest']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _sortBy = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Main Layout Grid: Sidebar Filters + Cards
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Desktop Sidebar Filters
                        if (isDesktop)
                          SizedBox(width: 280, child: _buildFilterSidebar()),

                        if (isDesktop) const SizedBox(width: 24),

                        // Clinics Cards List Grid
                        Expanded(
                          child: _buildClinicsGrid(isDesktop, screenWidth),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desktop Header Component matching design header
  Widget _buildDesktopTopHeader() {
    int cartCount = 0;
    for (var item in _appState.cart) {
      cartCount += item.quantity;
    }

    return Column(
      children: [
        // Utility Small Top Bar
        Container(
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTopUtilLink('Doctor\'s Zone'),
              const SizedBox(width: 20),
              _buildTopUtilLink('Sell with us'),
              const SizedBox(width: 20),
              _buildTopUtilLink('Deals'),
              const SizedBox(width: 20),
              _buildTopUtilLink('Help'),
            ],
          ),
        ),

        // Main Primary Brand Navigation Header
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Row(
            children: [
              // Logo Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF237F79),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chikitsakart',
                      style: TextStyle(
                        color: Color(0xFF237F79),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Deliver To Location Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: const [
                    Text(
                      'Deliver to ',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '452001',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Central Search Bar Input
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Search for Medicines, Products, Brands and More',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Action Icons: Wishlist, Cart, Login
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),

              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Login / Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sub Navigation Menu
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              _buildSubNavTab(
                'Medicine',
                false,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicineListingScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _buildSubNavTab(
                'Doctor Consultation',
                false,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorConsultationScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _buildSubNavTab('Offline Clinic', true, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopUtilLink(String title) {
    return InkWell(
      onTap: () {},
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _buildSubNavTab(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  bottom: BorderSide(color: AppColors.primary, width: 3),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textDark,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Modern Compact Mobile Search & Filter Bar (Replaces bulky 60% height cards on mobile)
  Widget _buildMobileSearchAndFilterBar() {
    final activeCount = _activeFilterCount;
    final hasActive = activeCount > 0;

    return Row(
      children: [
        // Modern Search Input Field
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _clinicNameController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search clinic, city or specialty...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                suffixIcon: _clinicNameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _clinicNameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: _clinicNameController.text.isNotEmpty
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1),
                    width: _clinicNameController.text.isNotEmpty ? 1.5 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 100% Circular Filter Action Button with Active Badge
        Material(
          color: hasActive ? AppColors.primary : Colors.white,
          shape: const CircleBorder(),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          child: InkWell(
            onTap: () => _openMobileFilterSheet(context),
            customBorder: const CircleBorder(),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasActive ? AppColors.primary : const Color(0xFFCBD5E1),
                  width: 1.0,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: hasActive ? Colors.white : AppColors.primary,
                  ),
                  if (hasActive)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Active Filter Chips Strip for Mobile
  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._selectedSpecialties.map(
              (spec) => _buildFilterChip(
                spec,
                () => setState(() => _selectedSpecialties.remove(spec)),
              ),
            ),
            ..._selectedServices.map(
              (serv) => _buildFilterChip(
                serv,
                () => setState(() => _selectedServices.remove(serv)),
              ),
            ),
            TextButton(
              onPressed: _clearAllFilters,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Top Search Controls Card
  Widget _buildSearchHeaderCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildSearchField(
                    'Clinic Name',
                    'Search clinics...',
                    Icons.add_location_alt_outlined,
                    _clinicNameController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSearchField(
                    'Area/Location',
                    'City or zip code',
                    Icons.my_location,
                    _locationController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSearchField(
                    'Doctor Name',
                    'Search specialists',
                    Icons.person_search_outlined,
                    _doctorNameController,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _openMobileFilterSheet(context);
                  },
                  icon: const Icon(Icons.tune, color: AppColors.primary),
                  label: const Text(
                    'Filter',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildSearchField(
                  'Clinic Name',
                  'Search clinics...',
                  Icons.add_location_alt_outlined,
                  _clinicNameController,
                ),
                const SizedBox(height: 12),
                _buildSearchField(
                  'Area/Location',
                  'City or zip code',
                  Icons.my_location,
                  _locationController,
                ),
                const SizedBox(height: 12),
                _buildSearchField(
                  'Doctor Name',
                  'Search specialists',
                  Icons.person_search_outlined,
                  _doctorNameController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Desktop Sidebar / Mobile Modal Filter Widget
  Widget _buildFilterSidebar([StateSetter? setModalState]) {
    void update(VoidCallback fn) {
      setState(fn);
      setModalState?.call(() {});
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
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
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _clearAllFilters();
                    setModalState?.call(() {});
                  },
                  child: const Text(
                    'CLEAR ALL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // SPECIALTY
            const Text(
              'SPECIALTY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...['Cardiology', 'Dermatology', 'Pediatrics', 'Oncology'].map(
              (spec) => Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.primary,
                  title: Text(
                    spec,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                  value: _selectedSpecialties.contains(spec),
                  onChanged: (bool? val) {
                    update(() {
                      if (val == true) {
                        _selectedSpecialties.add(spec);
                      } else {
                        _selectedSpecialties.remove(spec);
                      }
                    });
                  },
                ),
              ),
            ),

            const Divider(height: 24),

            // SERVICE AVAILABLE
            const Text(
              'SERVICE AVAILABLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              'Panchkarma',
              'Leech Therapy',
              'Cupping',
              'Rakt Mokshan',
              'Agni Karma',
              'Kerali Panchkarma',
              'IPD',
            ].map(
              (serv) => Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.primary,
                  title: Text(
                    serv,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  ),
                  value: _selectedServices.contains(serv),
                  onChanged: (bool? val) {
                    update(() {
                      if (val == true) {
                        _selectedServices.add(serv);
                      } else {
                        _selectedServices.remove(serv);
                      }
                    });
                  },
                ),
              ),
            ),

            const Divider(height: 24),

            // AVAILABILITY
            const Text(
              'AVAILABILITY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        update(() => _selectedAvailability = 'Today'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedAvailability == 'Today'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      side: BorderSide(
                        color: _selectedAvailability == 'Today'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Today',
                      style: TextStyle(
                        color: _selectedAvailability == 'Today'
                            ? AppColors.primary
                            : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        update(() => _selectedAvailability = 'This Week'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedAvailability == 'This Week'
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      side: BorderSide(
                        color: _selectedAvailability == 'This Week'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        color: _selectedAvailability == 'This Week'
                            ? AppColors.primary
                            : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // PATIENT RATING
            const Text(
              'PATIENT RATING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < 4 ? Icons.star : Icons.star_border,
                      color: Colors.amber[600],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '4.0+',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // FEES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FEES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '₹${_feeRange.start.toInt()} - ₹${_feeRange.end.toInt()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _feeRange,
              min: 0,
              max: 10000,
              divisions: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (values) => update(() => _feeRange = values),
            ),
          ],
        ),
      ),
    );
  }

  // Clinics List Grid - Shows 2 offline clinics in one row on mobile
  Widget _buildClinicsGrid(bool isDesktop, double screenWidth) {
    if (_isLoadingClinics) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final clinics = _filteredClinics;

    if (clinics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            const Text(
              'No clinics found matching your filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      );
    }

    int crossAxisCount = 2; // Exactly 2 clinics per row on mobile!
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
    } else if (screenWidth >= 800) {
      crossAxisCount = 3;
    }

    final double aspectRatio = screenWidth < 360
        ? 0.56
        : (screenWidth < 400 ? 0.60 : (screenWidth < 750 ? 0.65 : 0.72));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: aspectRatio,
      ),
      itemCount: clinics.length,
      itemBuilder: (context, index) {
        return _buildClinicCard(clinics[index]);
      },
    );
  }

  // Clinic Card Widget matching design - fits 2 clinics per row cleanly
  Widget _buildClinicCard(Clinic clinic) {
    final raw = clinic.rawApiClinic;
    final phone = raw?.phone ?? '';
    final email = raw?.email ?? '';
    final about = raw?.about ?? '';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClinicDetailScreen(
                clinicId: clinic.id,
                initialClinic: clinic,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header Stack with Overlay Badges
            Stack(
              children: [
                (clinic.image.startsWith('http://') ||
                        clinic.image.startsWith('https://'))
                    ? Image.network(
                        clinic.image,
                        height: 105,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/clinical_marketplace.jpg',
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        clinic.image.trim().isNotEmpty
                            ? clinic.image.trim()
                            : 'assets/clinical_marketplace.jpg',
                        height: 105,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/clinical_marketplace.jpg',
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                // Top Badges Overlay (VERIFIED & CLINIC)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'VERIFIED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLINIC',
                          style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                clinic.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  clinic.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                clinic.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (about.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            about,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],

                        if (phone.isNotEmpty || email.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (phone.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          size: 10, color: Color(0xFFE11D48)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          phone,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (phone.isNotEmpty && email.isNotEmpty)
                                  const SizedBox(height: 2),
                                if (email.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.email_rounded,
                                          size: 10, color: Color(0xFF8B5CF6)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // View Doctors Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          'View Doctors',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF0F766E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Bottom Sheet for Filters
  void _openMobileFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Clinics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Material(
                        type: MaterialType.transparency,
                        child: _buildFilterSidebar(setSheetState),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}