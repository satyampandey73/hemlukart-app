import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_auth_service.dart';
import '../services/appointment_service.dart';
import '../services/eprescription_service.dart';
import '../models/doctor_model.dart';
import '../models/my_appointments_model.dart';
import 'appointment_detail_screen.dart';
import 'eprescription_detail_screen.dart';
import 'doctor_profile_settings_screen.dart';
import 'patient_detail_screen.dart';
import 'doctor_manage_schedules_screen.dart';
import 'doctor_my_clinics_screen.dart';
import 'clinic_listing_screen.dart';
import '../services/video_call_service.dart';
import 'video_call_screen.dart';
import 'cart_screen.dart';
import 'medicine_listing_screen.dart';
import 'my_orders_screen.dart';
import 'product_detail_screen.dart';
import 'new_home_screen.dart';
import 'product_catalog_screen.dart';
import 'doctor_consultation_screen.dart';
import 'doctor_eprescriptions_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  String _selectedFilter = 'All';

  // Live API State
  List<UserAppointmentItem> _doctorAppointments = [];
  List<Map<String, dynamic>> _apiPrescriptions = [];
  ApiDoctor? _apiDoctorProfile;

  @override
  void initState() {
    super.initState();
    _fetchDoctorDashboardData();
  }

  Future<void> _fetchDoctorDashboardData() async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;

    try {
      final profileRes = await DoctorAuthService.getProfile(token: token);
      if (profileRes.success && profileRes.doctor != null) {
        if (mounted) setState(() => _apiDoctorProfile = profileRes.doctor);
      }
    } catch (_) {}

    try {
      final aptRes = await AppointmentService.getDoctorAppointments(token: token);
      if (aptRes.success) {
        if (mounted) setState(() => _doctorAppointments = aptRes.appointments);
      }
    } catch (_) {}

    try {
      final rxRes = await EPrescriptionService.getDoctorPrescriptions(
        token: token,
        limit: 50,
      );
      if (rxRes['success'] == true && rxRes['prescriptions'] is List) {
        if (mounted) {
          setState(() {
            _apiPrescriptions = List<Map<String, dynamic>>.from(rxRes['prescriptions']);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshPrescriptions({String? search, String? status}) async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;
    if (mounted) setState(() => _rxIsLoading = true);

    // Resolve API status param from the UI filter label
    String? apiStatus;
    if (status != null) {
      apiStatus = status;
    } else {
      switch (_rxStatusFilter) {
        case 'Sent':
          apiStatus = 'sent';
          break;
        case 'Sent to Pharmacy':
          apiStatus = 'sent_to_pharmacy';
          break;
        case 'Dispensed':
          apiStatus = 'dispensed';
          break;
        default:
          apiStatus = null; // All Statuses → no filter param
      }
    }

    final query = search ?? _rxSearchQuery;

    try {
      final rxRes = await EPrescriptionService.getDoctorPrescriptions(
        token: token,
        search: query.isNotEmpty ? query : null,
        status: apiStatus,
        limit: 50,
      );
      if (rxRes['success'] == true && rxRes['prescriptions'] is List) {
        if (mounted) {
          setState(() {
            _apiPrescriptions = List<Map<String, dynamic>>.from(rxRes['prescriptions']);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _rxIsLoading = false);
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Patient Records State & Filters
  String _selectedSpecialty = 'All';
  String _patientRiskFilter = 'All';
  bool _isPatientGridView = false;

  // E-Prescription Filters & Queue State
  String _rxStatusFilter = 'All Statuses';
  String _rxSearchQuery = '';
  final TextEditingController _rxSearchController = TextEditingController();
  bool _rxIsLoading = false;
  Timer? _rxSearchDebounce;

  // State for interactive refill approvals
  final List<Map<String, dynamic>> _refillQueue = [];

  // Telehealth Active Consultation State (Image 4)
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isScreenSharing = false;
  final TextEditingController _clinicalNotesController = TextEditingController();
  bool _isAiSummarizing = false;

  // Settings State — unused, kept for future use
  String _activeSettingsTab = 'General';

  // Team Management State
  final List<Map<String, dynamic>> _teamMembers = [];

  // Patient Records Data
  final List<Map<String, dynamic>> _patientRecords = [];

  // E-Prescriptions List Data
  final List<Map<String, dynamic>> _ePrescriptions = [];

  // Appointments List (Overview Tab)
  final List<Map<String, dynamic>> _appointments = [];

  @override
  void dispose() {
    _searchController.dispose();
    _clinicalNotesController.dispose();
    _rxSearchController.dispose();
    _rxSearchDebounce?.cancel();
    super.dispose();
  }

  void _handleHomeTabChange(int index) {
    if (!mounted) return;
    if (index == 0) {
      setState(() => _currentIndex = 0);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductCatalogScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorConsultationScreen()),
      );
    } else if (index == 4) {
      setState(() => _currentIndex = 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      NewHomeScreen(onTabChange: _handleHomeTabChange),
      _buildDashboardOverview(),
      _buildPatientRecordsTab(),
      const DoctorProfileSettingsScreen(embeddedMode: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: (_currentIndex == 0 || _currentIndex == 3) ? null : _buildMobileAppBar(),
      drawer: _buildDoctorDrawer(),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_ind_outlined),
              activeIcon: Icon(Icons.assignment_ind),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorDrawer() {
    final doc = _apiDoctorProfile;
    final displayName = doc != null && doc.fullName.isNotEmpty
        ? 'Dr. ${doc.fullName}'
        : 'Doctor Portal';
    final subTitle = doc != null
        ? (doc.currentDesignation ??
            doc.ayushSystem ??
            'Ayurvedic Physician')
        : 'Ayush Practitioner';
    final photoUrl = doc?.documents?.profilePhoto ?? '';
    final initial = (doc != null && doc.fullName.isNotEmpty)
        ? doc.fullName.trim()[0].toUpperCase()
        : 'D';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Profile Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl.isEmpty || !photoUrl.startsWith('http'))
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF0D9488), size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Menu items matching user screenshot
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'E-Prescriptions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorEPrescriptionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    icon: Icons.access_time_filled_rounded,
                    label: 'My Schedule',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorManageSchedulesScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.apartment_rounded,
                    label: 'My Clinics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorMyClinicsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    icon: Icons.store_mall_directory_rounded,
                    label: 'Offline Clinics',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClinicListingScreen(
                            doctorId: _apiDoctorProfile?.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    icon: Icons.call_rounded,
                    label: 'Telehealth',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: const Color(0xFFF3F6FB),
                            appBar: AppBar(
                              title: const Text(
                                'Telehealth Consultations',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              backgroundColor: AppColors.primary,
                              iconTheme: const IconThemeData(color: Colors.white),
                              elevation: 0,
                            ),
                            body: SafeArea(child: _buildTelehealthTab()),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyOrdersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Material(
      color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    final doc = _apiDoctorProfile;
    final displayName = doc != null && doc.fullName.isNotEmpty
        ? 'Dr. ${doc.fullName}'
        : 'Doctor Portal';
    final subTitle = doc != null
        ? (doc.currentDesignation ??
            doc.ayushSystem ??
            'Chikitsakart Doctor Portal')
        : 'Chikitsakart Doctor Portal';
    final photoUrl = doc?.documents?.profilePhoto ?? '';
    final initial = (doc != null && doc.fullName.isNotEmpty)
        ? doc.fullName.trim()[0].toUpperCase()
        : 'D';

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage: (photoUrl.isNotEmpty && photoUrl.startsWith('http'))
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl.isEmpty || !photoUrl.startsWith('http'))
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: Color(0xFF5EEAD4), size: 15),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  subTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCCFBF1),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchDoctorDashboardData,
          tooltip: 'Sync Dashboard',
        ),
        // Live Cart Button with Quantity Badge
        AnimatedBuilder(
          animation: AppState(),
          builder: (context, _) {
            final cartCount = AppState().cart.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            );
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  tooltip: 'Doctor Cart',
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
          onPressed: _showGlobalSearchSheet,
          tooltip: 'Search Records',
        ),
      ],
    );
  }

  bool _isToday(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final clean = dateStr.trim();
      final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

      // 1. Plain YYYY-MM-DD
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clean)) {
        final todayStr = '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${nowIst.day.toString().padLeft(2, '0')}';
        return clean == todayStr;
      }

      // 2. ISO timestamp or other parsed string
      final dt = DateTime.parse(clean);
      final dtIst = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
      return dtIst.year == nowIst.year && dtIst.month == nowIst.month && dtIst.day == nowIst.day;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // TAB 0: DASHBOARD OVERVIEW
  // ===========================================================================
  Widget _buildDashboardOverview() {
    final allAppointments = _doctorAppointments.isNotEmpty ? _doctorAppointments : <UserAppointmentItem>[];
    final todayAppointments = allAppointments.where((a) => _isToday(a.appointmentDate)).toList();
    final todayCompleted = todayAppointments.where((a) => a.status.toLowerCase() == 'completed').length;

    // Apply filter to the appointments list
    final displayAppointments = allAppointments.where((apt) {
      if (_selectedFilter == 'Today') {
        return _isToday(apt.appointmentDate);
      }
      if (_selectedFilter == 'All') return true;
      final status = apt.status.toLowerCase();
      if (_selectedFilter == 'Upcoming') {
        if (status == 'cancelled' || status == 'completed') {
          return false;
        }
        return status == 'pending' || status == 'confirmed' || status == 'scheduled' || status == 'in-progress' || status == 'in_progress';
      }
      if (_selectedFilter == 'Completed') {
        return status == 'completed';
      }
      if (_selectedFilter == 'Cancelled') {
        return status == 'cancelled';
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchDoctorDashboardData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Statistics Grid (Live API Data)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Today's Appts",
                    value: '${todayAppointments.length}',
                    subtitle: '$todayCompleted Completed',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF2563EB),
                    bgTint: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Patients',
                    value: '${_doctorAppointments.map((a) => a.patientName).where((n) => n.trim().isNotEmpty).toSet().length}',
                    subtitle: 'Unique Patients',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF059669),
                    bgTint: const Color(0xFFECFDF5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending Review',
                    value: '${_apiPrescriptions.where((r) => r['status']?.toString().toLowerCase().contains('pending') == true || r['status']?.toString().toLowerCase() == 'sent').length}',
                    subtitle: 'Rx Pending',
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFDC2626),
                    bgTint: const Color(0xFFFEF2F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Consults',
                    value: '${_doctorAppointments.where((a) => a.status.toLowerCase() == 'in-progress' || a.status.toLowerCase() == 'in_progress' || a.status.toLowerCase() == 'confirmed' || a.status.toLowerCase() == 'pending' || a.status.toLowerCase() == 'scheduled').length}',
                    subtitle: 'Active Slots',
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFFD97706),
                    bgTint: const Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Today's Live Queue Header & Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${displayAppointments.length} ${_selectedFilter == 'All' ? 'scheduled' : _selectedFilter.toLowerCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Today', 'Upcoming', 'Completed', 'Cancelled'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final isCancelledChip = filter == 'Cancelled';
                  final selectedChipColor = isCancelledChip
                      ? const Color(0xFFDC2626)
                      : AppColors.primary;
                  final selectedBorderColor = isCancelledChip
                      ? const Color(0xFFDC2626)
                      : AppColors.primary;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: selectedChipColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? selectedBorderColor : const Color(0xFFCBD5E1),
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            if (displayAppointments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_available, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFilter == 'All'
                          ? 'No appointments found.'
                          : 'No $_selectedFilter appointments.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                    ),
                  ],
                ),
              )
            else
              ...displayAppointments.map((apt) => _buildAppointmentCard(apt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorProductsSection() {
    final appState = AppState();
    final products = appState.apiProducts;

    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF0D9488), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Ayush Pharmacy',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Doctor Pricing',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicineListingScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 235,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.take(10).length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final prod = products[index];
              final hasDiscount = prod.price < prod.originalPrice;
              final badgeLabel = prod.roleDiscountLabel.isNotEmpty
                  ? prod.roleDiscountLabel
                  : (hasDiscount ? '${prod.effectiveDiscountPercent}% OFF' : '');

              return Container(
                width: 155,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: prod),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image & Doctor Discount Tag
                          Stack(
                            children: [
                              Container(
                                height: 85,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: prod.image.startsWith('http')
                                      ? Image.network(
                                          prod.image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, stack) => const Icon(
                                            Icons.medication_rounded,
                                            size: 32,
                                            color: AppColors.textLight,
                                          ),
                                        )
                                      : Image.asset(
                                          prod.image.isNotEmpty ? prod.image : 'assets/p1.png',
                                          fit: BoxFit.contain,
                                        ),
                                ),
                              ),
                              if (badgeLabel.isNotEmpty)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badgeLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            prod.brand.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prod.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${prod.price.toInt()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '₹${prod.originalPrice.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textLight,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                appState.addToCart(prod, qty: 1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${prod.name} to cart at Doctor Price (₹${prod.price.toInt()})!'),
                                    backgroundColor: const Color(0xFF0D9488),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'View Cart',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const CartScreen()),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 12),
                              label: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: PATIENT RECORDS (Adapted from Image 1)
  // ===========================================================================
  Widget _buildPatientRecordsTab() {
    // Deduplicate: show each patient only once (keep the most recent appointment)
    final seen = <String>{};
    final List<Map<String, dynamic>> apiPatientList = _doctorAppointments
        .where((apt) {
          final key = apt.patientName.isNotEmpty ? apt.patientName : 'Patient';
          return seen.add(key);
        })
        .map((apt) {
          return {
            'id': apt.id,
            'patientName': apt.patientName.isNotEmpty ? apt.patientName : 'Patient',
            'age': apt.patientAge ?? 30,
            'gender': 'Patient',
            'lastVisit': apt.formattedDateTime,
            'diagnosis': apt.symptoms ?? 'General Consultation',
            'risk': 'Low',
            'specialty': apt.consultationType,
            'avatar': null,
            'phone': apt.patientMobile ?? 'N/A',
            'bloodGroup': 'N/A',
          };
        })
        .toList();

    List<Map<String, dynamic>> filteredPatients = (_patientRecords.isNotEmpty ? _patientRecords : apiPatientList).where((p) {
      if (_selectedSpecialty != 'All' && p['specialty'] != _selectedSpecialty) return false;
      if (_patientRiskFilter != 'All' && p['risk'] != _patientRiskFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = p['patientName'].toString().toLowerCase();
        final id = p['id'].toString().toLowerCase();
        final diag = p['diagnosis'].toString().toLowerCase();
        return name.contains(query) || id.contains(query) || diag.contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + "+ Add New Patient" Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Patient Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage & view clinical history for active patients.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Metric Cards (Image 1 top stats)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRecordMetricCard(
                  title: 'Total Patients',
                  value: '${_doctorAppointments.map((a) => a.patientName).toSet().length}',
                  sub: 'Live API',
                  icon: Icons.people_alt_outlined,
                  accentColor: const Color(0xFF059669),
                  progress: 0.7,
                ),
                const SizedBox(width: 10),
                _buildRecordMetricCard(
                  title: 'Recently Visited',
                  value: '${_doctorAppointments.where((a) => a.status.toLowerCase() == 'completed').length}',
                  sub: 'Completed',
                  icon: Icons.history_rounded,
                  accentColor: const Color(0xFF0284C7),
                  progress: 0.5,
                ),
                const SizedBox(width: 10),
                _buildRecordMetricCard(
                  title: 'Pending Review',
                  value: '${_apiPrescriptions.where((r) => r['status']?.toString().toLowerCase().contains('pending') == true).length}',
                  sub: 'High Priority',
                  icon: Icons.assignment_late_outlined,
                  accentColor: const Color(0xFFDC2626),
                  progress: 0.9,
                  isAlert: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters Bar: Search + Specialty + Risk + View Toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search patients, ID, or diagnosis...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Specialty Dropdown
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSpecialty,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSpecialty = val);
                            },
                            items: ['All', 'Cardiology', 'Neurology', 'Orthopedics', 'Pediatrics']
                                .map((s) => DropdownMenuItem(value: s, child: Text('Specialty: $s')))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Risk Filter
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _patientRiskFilter,
                          style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                          onChanged: (val) {
                            if (val != null) setState(() => _patientRiskFilter = val);
                          },
                          items: ['All', 'High', 'Medium', 'Low']
                              .map((r) => DropdownMenuItem(value: r, child: Text('Risk: $r')))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Grid / List Toggle
                    IconButton(
                      icon: Icon(_isPatientGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, size: 20),
                      color: AppColors.primary,
                      onPressed: () => setState(() => _isPatientGridView = !_isPatientGridView),
                      tooltip: _isPatientGridView ? 'List View' : 'Grid View',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Patients List (Cards adapted for Mobile)
          if (filteredPatients.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('No patient records found.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            )
          else if (_isPatientGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) => _buildPatientGridItem(filteredPatients[index]),
            )
          else
            ...filteredPatients.map((patient) => _buildPatientRowCard(patient)),

          const SizedBox(height: 12),
          // Pagination Footer (Image 1 footer)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1-${filteredPatients.length} of 1,248 patients',
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    const Text('2   3   ... 125', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordMetricCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color accentColor,
    required double progress,
    bool isAlert = false,
  }) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFFFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAlert ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a CircleAvatar with the patient's real image (if available)
  /// or a colored circle showing the first letter of [name].
  Widget _buildPatientAvatar(String name, String? avatarPath, double radius) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasImage = avatarPath != null && avatarPath.isNotEmpty;

    if (hasImage) {
      // Network URL
      if (avatarPath.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: NetworkImage(avatarPath),
        );
      }
      // Asset path
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(avatarPath),
      );
    }

    // No image → show initial letter
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildPatientRowCard(Map<String, dynamic> patient) {
    Color riskColor = Colors.green;
    if (patient['risk'] == 'High') riskColor = Colors.red;
    if (patient['risk'] == 'Medium') riskColor = Colors.amber.shade700;

    void openDetail() {
      final name = patient['patientName']?.toString() ?? '';
      final patientAppointments = _doctorAppointments
          .where((a) => a.patientName == name)
          .toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(
            patient: patient,
            appointments: patientAppointments,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: openDetail,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPatientAvatar(patient['patientName']?.toString() ?? '', patient['avatar']?.toString(), 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['patientName'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    Text(
                      'ID: ${patient['id']} • ${patient['age']} / ${patient['gender']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: riskColor),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${patient['risk']} Risk',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              Text(
                'Visited: ${patient['lastVisit']}',
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: openDetail,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('View Full EHR', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
             
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPatientGridItem(Map<String, dynamic> patient) {
    Color riskColor = Colors.green;
    if (patient['risk'] == 'High') riskColor = Colors.red;
    if (patient['risk'] == 'Medium') riskColor = Colors.amber.shade700;

    void openDetail() {
      final name = patient['patientName']?.toString() ?? '';
      final patientAppointments = _doctorAppointments
          .where((a) => a.patientName == name)
          .toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDetailScreen(
            patient: patient,
            appointments: patientAppointments,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: openDetail,
      child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPatientAvatar(patient['patientName']?.toString() ?? '', patient['avatar']?.toString(), 22),
          Text(
            patient['patientName'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text('${patient['age']}y • ${patient['gender']}', style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${patient['risk']} Risk',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: riskColor),
            ),
          ),
          ElevatedButton(
            onPressed: openDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 28),
              padding: EdgeInsets.zero,
              elevation: 0,
            ),
            child: const Text('Details', style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ],
      ),
    ),
    );
  }

  // ===========================================================================
  // TAB 2: E-PRESCRIPTIONS
  // ===========================================================================
  Widget _buildEPrescriptionsTab() {
    return const DoctorEPrescriptionsScreen(isEmbedded: true);
  }

  Widget _oldBuildEPrescriptionsTab() {
    // Results come directly from the API — no client-side filtering needed.
    // _apiPrescriptions already reflects the current search + status filter.
    final List<Map<String, dynamic>> results = _apiPrescriptions;

    // Counts are derived from the full unfiltered total when no filter is active,
    // otherwise show the count from the current result set.
    final bool hasFilter = _rxStatusFilter != 'All Statuses' || _rxSearchQuery.isNotEmpty;
    final int sentCount      = results.where((r) => r['status'] == 'sent').length;
    final int pharmacyCount  = results.where((r) => r['status'] == 'sent_to_pharmacy').length;
    final int dispensedCount = results.where((r) => r['status'] == 'dispensed').length;
    final int cancelledCount = results.where((r) => r['status'] == 'cancelled').length;

    return RefreshIndicator(
      onRefresh: () => _refreshPrescriptions(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + Create Prescription Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'E-Prescriptions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage, review, and authorize medication orders.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Metric Cards — live counts from API
            if (_rxIsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildRxStatCard(
                      label: 'Total Rx',
                      value: '${_apiPrescriptions.length}',
                      sub: 'All time',
                      color: AppColors.primary,
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRxStatCard(
                      label: 'Sent',
                      value: '$sentCount',
                      sub: 'Awaiting view',
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRxStatCard(
                      label: 'At Pharmacy',
                      value: '$pharmacyCount',
                      sub: 'In process',
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRxStatCard(
                      label: 'Dispensed',
                      value: '$dispensedCount',
                      sub: 'Completed',
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFDCFCE7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _rxSearchController,
                      onChanged: (val) {
                        final q = val.trim();
                        setState(() => _rxSearchQuery = q);
                        // Debounce: wait 450 ms after user stops typing, then hit API
                        _rxSearchDebounce?.cancel();
                        _rxSearchDebounce = Timer(
                          const Duration(milliseconds: 450),
                          () => _refreshPrescriptions(search: q),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search patient, Rx number, diagnosis...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: _rxSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _rxSearchController.clear();
                                  setState(() => _rxSearchQuery = '');
                                  _rxSearchDebounce?.cancel();
                                  _refreshPrescriptions(search: '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All Statuses', 'Sent', 'Sent to Pharmacy', 'Dispensed'].map((st) {
                          final isSelected = _rxStatusFilter == st;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(st),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textDark,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                              ),
                              onSelected: (_) {
                                if (!isSelected) {
                                  setState(() => _rxStatusFilter = st);
                                  // Map UI label → API param
                                  String? apiStatus;
                                  switch (st) {
                                    case 'Sent':
                                      apiStatus = 'sent';
                                      break;
                                    case 'Sent to Pharmacy':
                                      apiStatus = 'sent_to_pharmacy';
                                      break;
                                    case 'Dispensed':
                                      apiStatus = 'dispensed';
                                      break;
                                  }
                                  _refreshPrescriptions(status: apiStatus);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Results count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasFilter
                        ? '${results.length} result${results.length == 1 ? "" : "s"} for "$_rxSearchQuery"${_rxStatusFilter != "All Statuses" ? " · $_rxStatusFilter" : ""}'
                        : '${results.length} prescription${results.length == 1 ? "" : "s"} total',
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                  GestureDetector(
                    onTap: () => _refreshPrescriptions(),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Refresh', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Prescription list
              if (results.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text(
                        _apiPrescriptions.isEmpty
                            ? 'No e-prescriptions yet.\nPull down to refresh.'
                            : 'No prescriptions match your filters.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.5),
                      ),
                    ],
                  ),
                )
              else
                ...results.map((rx) => _buildPrescriptionCard(rx)),
            ],

            const SizedBox(height: 14),

            // Pharmacy Integration Footer Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF5EEAD4), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Pharmacy Integration Active', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Connected to local pharmacies. HIPAA compliant & encrypted.', style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(12)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRxStatCard({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(fontSize: 8, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildRefillQueueCard(Map<String, dynamic> item) {
    final bool isDone = item['status'] != 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['patientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(item['timeAgo'], style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${item['medication']} • ${item['priority']}',
            style: TextStyle(fontSize: 11, color: item['priority'] == 'Urgent' ? Colors.red : AppColors.textDark),
          ),
          const SizedBox(height: 8),
          if (isDone)
            Text('Action Taken: ${item['status']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => item['status'] = 'Approved');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refill approved for ${item['patientName']}')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 4), elevation: 0),
                    child: const Text('Approve', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => item['status'] = 'Denied');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refill denied for ${item['patientName']}')));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Deny', style: TextStyle(fontSize: 11, color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _fetchAndShowPrescriptionDetails(String rxId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EPrescriptionDetailScreen(prescriptionId: rxId),
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> rx) {
    final String rxId = rx['id'] ?? '';
    final String rxNo = rx['prescriptionNumber'] ?? rxId;
    final String patientName = rx['patientName'] ?? 'Patient';
    final String patientMobile = rx['patientMobile'] ?? '';
    final int? patientAge = rx['patientAge'] as int?;
    final String statusStr = (rx['status'] ?? 'sent').toString();
    final String diagnosis = (rx['diagnosis'] ?? '').toString();

    // Issued date
    String issuedDate = '';
    if (rx['issuedAt'] != null) {
      try {
        final dt = DateTime.parse(rx['issuedAt'].toString());
        issuedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    // Medication summary
    String medText = 'General Consultation';
    int medCount = 0;
    if (rx['medications'] is List) {
      final meds = rx['medications'] as List;
      medCount = meds.length;
      if (meds.isNotEmpty) {
        final firstMed = meds.first;
        if (firstMed is Map && firstMed['name'] != null) {
          medText = '${firstMed['name']}${firstMed['strength'] != null ? " ${firstMed['strength']}" : ""}';
          if (medCount > 1) medText += ' +${medCount - 1} more';
        }
      }
    }

    // Status badge colors
    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (statusStr.toLowerCase()) {
      case 'dispensed':
        statusBg = const Color(0xFFDBEAFE);
        statusColor = const Color(0xFF2563EB);
        statusLabel = 'Dispensed';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'sent_to_pharmacy':
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFD97706);
        statusLabel = 'At Pharmacy';
        statusIcon = Icons.local_pharmacy_outlined;
        break;
      case 'cancelled':
        statusBg = const Color(0xFFFEF2F2);
        statusColor = const Color(0xFFDC2626);
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_outlined;
        break;
      default: // sent
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Sent';
        statusIcon = Icons.send_outlined;
    }

    final bool hasPharmacyNotes =
        rx['pharmacyNotes'] != null && rx['pharmacyNotes'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (rxId.isNotEmpty) {
            _fetchAndShowPrescriptionDetails(rxId);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EPrescriptionDetailScreen(prescriptionData: rx),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: patient avatar + info + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (patientAge != null) ...[
                              Text(
                                '$patientAge yrs',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                              const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                            ],
                            if (patientMobile.isNotEmpty)
                              Text(
                                patientMobile,
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 3),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Divider
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              // Diagnosis
              Row(
                children: [
                  const Icon(Icons.medical_information_outlined, size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      diagnosis.isNotEmpty ? diagnosis : 'General Consultation',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Medications
              Row(
                children: [
                  const Icon(Icons.medication_outlined, size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      medText,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Pharmacy notes (if available)
              if (hasPharmacyNotes) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 13, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rx['pharmacyNotes'].toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xFFD97706)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Bottom row: Rx number + date + tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rxNo,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Row(
                    children: [
                      if (issuedDate.isNotEmpty) ...[
                        const Icon(Icons.calendar_today_outlined, size: 10, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          issuedDate,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ===========================================================================
  // TAB 3: TELEHEALTH & CONSULTATION (Adapted from Image 4)
  // ===========================================================================
  // TAB 3: TELEHEALTH & CONSULTATION
  // ===========================================================================
  Widget _buildTelehealthTab() {
    // Filter: video consultations with confirmed status only
    final videoAppointments = _doctorAppointments
        .where((a) =>
            (a.consultationType.toLowerCase() == 'video' ||
                a.consultationType.toLowerCase() == 'online' ||
                a.consultationType.toLowerCase() == 'telehealth') &&
            a.status.toLowerCase() == 'confirmed')
        .toList();

    // For display purposes — confirmed appointments shown as "upcoming"
    final activeApts = <UserAppointmentItem>[];
    final upcomingApts = videoAppointments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Telehealth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${videoAppointments.length} Confirmed',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF059669), size: 7),
                    SizedBox(width: 4),
                    Text('Video Consultations', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Scheduled Video Appointments List ────────────────────
          _buildVideoAppointmentsList(videoAppointments, activeApts, upcomingApts),
          const SizedBox(height: 20),   

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scheduled Video Appointments List
  // ---------------------------------------------------------------------------
  Widget _buildVideoAppointmentsList(
    List<UserAppointmentItem> all,
    List<UserAppointmentItem> active,
    List<UserAppointmentItem> upcoming,
  ) {
    if (all.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No confirmed video appointments',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 4),
            Text(
              'Confirmed video consultations will appear here.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary row
        Row(
          children: [
            _buildTelehealthStatPill('${all.length}', 'Confirmed', AppColors.primary, const Color(0xFFEFF6FF)),
          ],
        ),
        const SizedBox(height: 14),

        // Active / In-progress first
        if (active.isNotEmpty) ...[
          Row(
            children: const [
              Icon(Icons.circle, color: Color(0xFF059669), size: 8),
              SizedBox(width: 6),
              Text('In Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 8),
          ...active.map((apt) => _buildVideoAptCard(apt, isActive: true)),
          const SizedBox(height: 14),
        ],

        // Upcoming
        if (upcoming.isNotEmpty) ...[
          Row(
            children: const [
              Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 14),
              SizedBox(width: 6),
              Text('Upcoming', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
            ],
          ),
          const SizedBox(height: 8),
          ...upcoming.map((apt) => _buildVideoAptCard(apt, isActive: false)),
        ],

        // Other statuses (completed, cancelled, etc.) not shown here
      ],
    );
  }

  Widget _buildTelehealthStatPill(String count, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildVideoAptCard(UserAppointmentItem apt, {required bool isActive}) {
    final statusColor = isActive ? const Color(0xFF059669) : const Color(0xFF2563EB);
    final statusBg    = isActive ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF);
    final statusLabel = isActive ? 'In Progress' : apt.status[0].toUpperCase() + apt.status.substring(1).toLowerCase();
    final patientInitial = apt.patientName.isNotEmpty ? apt.patientName[0].toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0), width: isActive ? 1.5 : 1),
        boxShadow: isActive
            ? [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar circle with initial
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(patientInitial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.patientName.isNotEmpty ? apt.patientName : 'Patient',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.videocam_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          const Text('Video Consultation', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          if (apt.patientAge != null) ...[
                            const Text(' • ', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                            Text('${apt.patientAge}y', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Date / time / duration row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      apt.formattedDateTime,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                  const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('${apt.durationMinutes} min', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ],
              ),
            ),
            if (apt.symptoms != null && apt.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notes_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      apt.symptoms!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailScreen(
                          appointmentId: apt.id,
                          isForDoctor: true,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline, size: 14),
                    label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      foregroundColor: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final token = AppState().doctorToken ?? AppState().activeChatToken;
                      if (token == null || token.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please log in as a doctor to start video call')),
                        );
                        return;
                      }
                      final res = await VideoCallService.startVideoCall(appointmentId: apt.id, token: token);
                      if (!context.mounted) return;
                      if (res.success || res.videoCall != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoCallScreen(
                              appointmentId: apt.id,
                              videoCallId: res.videoCall?.id,
                              isDoctor: true,
                              peerName: apt.patientName.isNotEmpty ? apt.patientName : 'Patient',
                              peerSubtitle: '${apt.patientAge ?? 30} Yrs • ${apt.patientMobile ?? ""}',
                              peerAvatar: 'assets/d2.jpg',
                            ),
                          ),
                        );
                        _fetchDoctorDashboardData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message ?? 'Unable to start video call')),
                        );
                      }
                    },
                    icon: const Icon(Icons.videocam_rounded, size: 16, color: Colors.white),
                    label: const Text('Start Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingRoomCard(String name, String status, String time, bool isReady, String avatar) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isReady ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isReady ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundImage: AssetImage(avatar)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Text('$status • $time', style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(width: 8),
          if (isReady)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(50, 24), padding: EdgeInsets.zero),
              child: const Text('Start', style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildConditionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w600)),
    );
  }

  // ===========================================================================
  // COMMON DIALOGS & MODAL SHEETS
  // ===========================================================================
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgTint, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.trending_up, color: Colors.green.shade600, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 95,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic item) {
    String patientName = 'Patient';
    String id = '';
    String status = 'Scheduled';
    String time = '10:00 AM';
    String type = 'Video';
    String complaint = 'General Consult';

    if (item is UserAppointmentItem) {
      patientName = item.patientName.isNotEmpty ? item.patientName : 'Patient';
      id = item.id;
      status = item.status;
      time = item.formattedDateTime;
      type = item.consultationType;
      complaint = item.symptoms ?? 'General Consultation';
    } else if (item is Map) {
      patientName = item['patientName'] ?? 'Patient';
      id = item['id'] ?? '';
      status = item['status'] ?? 'Scheduled';
      final rawDate = item['appointmentDate']?.toString();
      final rawTime = (item['appointmentTime'] ?? item['time'])?.toString();
      time = UserAppointmentItem.formatDateTimeInIst(dateStr: rawDate, timeStr: rawTime);
      if (time.isEmpty) time = '10:00 AM';
      type = item['type'] ?? item['consultationType'] ?? 'Video';
      complaint = item['complaint'] ?? item['symptoms'] ?? 'General Consult';
    }

    final bool isActive = status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed';

    Color statusColor;
    Color statusBgColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        statusColor = const Color(0xFF16A34A);
        statusBgColor = const Color(0xFFDCFCE7);
        break;
      case 'pending':
        statusColor = const Color(0xFFD97706);
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      case 'completed':
        statusColor = const Color(0xFF2563EB);
        statusBgColor = const Color(0xFFDBEAFE);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        statusBgColor = const Color(0xFFFEE2E2);
        break;
      default:
        statusColor = const Color(0xFF2563EB);
        statusBgColor = const Color(0xFFDBEAFE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (id.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AppointmentDetailScreen(
                  appointmentId: id,
                  isForDoctor: true,
                ),
              ),
            ).then((_) => _fetchDoctorDashboardData());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('ID: $id', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                    child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('$time • ${type == 'video' ? '🎥 Video' : '🏥 In-Person'} • $complaint',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (id.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailScreen(
                            appointmentId: id,
                            isForDoctor: true,
                          ),
                        ),
                      ).then((_) => _fetchDoctorDashboardData());
                    }
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  label: const Text('View Details',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a cancel confirmation dialog directly from the dashboard card.
  void _showDoctorCancelDialog({required String appointmentId, required String patientName}) {
    String selectedReason = 'Emergency situation';
    final List<String> reasons = [
      'Emergency situation',
      'Conflicting schedule',
      'Doctor unavailable',
      'Patient request',
      'Other',
    ];
    final TextEditingController otherCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Cancel – $patientName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              if (selectedReason == 'Other') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: otherCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final reason = selectedReason == 'Other'
                    ? (otherCtrl.text.trim().isEmpty ? 'Emergency situation' : otherCtrl.text.trim())
                    : selectedReason;
                Navigator.pop(ctx);
                await _doCancelAppointment(appointmentId: appointmentId, reason: reason);
              },
              child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doCancelAppointment({required String appointmentId, required String reason}) async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;

    try {
      final res = await AppointmentService.cancelDoctorAppointment(
        appointmentId: appointmentId,
        cancelReason: reason,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? (res.message ?? 'Appointment cancelled successfully')
              : (res.message ?? 'Failed to cancel appointment')),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) _fetchDoctorDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Shows a reschedule dialog directly from the dashboard card.
  void _showDoctorRescheduleDialog({required String appointmentId, required String patientName}) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedReason = 'Conflicting schedule';
    final List<String> reasons = [
      'Conflicting schedule',
      'Emergency situation',
      'Doctor unavailable',
      'Patient request',
      'Other',
    ];
    final TextEditingController otherCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateStr =
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          final timeStr =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.event_repeat, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Reschedule – $patientName',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                    title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tap to change date'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                  // Time picker tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Color(0xFF2563EB)),
                    title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tap to change time'),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) setDialogState(() => selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
                    },
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: otherCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter reason...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                onPressed: () async {
                  final reason = selectedReason == 'Other'
                      ? (otherCtrl.text.trim().isEmpty ? 'Conflicting schedule' : otherCtrl.text.trim())
                      : selectedReason;
                  final newDate =
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                      'T${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00.000Z';
                  Navigator.pop(ctx);
                  await _doRescheduleAppointment(appointmentId: appointmentId, newDate: newDate, reason: reason);
                },
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _doRescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String reason,
  }) async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;

    try {
      final res = await AppointmentService.rescheduleDoctorAppointment(
        appointmentId: appointmentId,
        newDate: newDate,
        reason: reason,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? (res.message ?? 'Appointment rescheduled successfully')
              : (res.message ?? 'Failed to reschedule appointment')),
          backgroundColor: res.success ? Colors.green : Colors.red,
        ),
      );
      if (res.success) _fetchDoctorDashboardData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddPatientSheet() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final diagnosisCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Patient Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Patient Full Name')),
            const SizedBox(height: 8),
            TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age & Gender')),
            const SizedBox(height: 8),
            TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: 'Initial Diagnosis / Complaint')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _patientRecords.insert(0, {
                      'id': 'MP-${1000 + _patientRecords.length}',
                      'patientName': nameCtrl.text,
                      'age': int.tryParse(ageCtrl.text) ?? 30,
                      'gender': 'Male',
                      'lastVisit': 'Today',
                      'diagnosis': diagnosisCtrl.text.isEmpty ? 'General Consult' : diagnosisCtrl.text,
                      'risk': 'Low',
                      'specialty': 'General',
                      'avatar': 'assets/d1.jpg',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added new patient: ${nameCtrl.text}')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 42)),
              child: const Text('Save Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionDialog({String? patientName}) {
    final rxPatientCtrl = TextEditingController(text: patientName ?? '');
    final rxMedsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Write Digital E-Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: rxPatientCtrl, decoration: const InputDecoration(labelText: 'Patient Name')),
            const SizedBox(height: 10),
            TextField(
              controller: rxMedsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Medicines & Dosage',
                hintText: 'e.g., Ashwagandha 500mg - 1 tab BD after meals',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (rxPatientCtrl.text.isNotEmpty) {
                setState(() {
                  _ePrescriptions.insert(0, {
                    'id': '#PX-${8000 + _ePrescriptions.length}',
                    'patientName': rxPatientCtrl.text,
                    'medication': rxMedsCtrl.text.isEmpty ? 'General Ayush Formulation' : rxMedsCtrl.text,
                    'instructions': '30 Days Supply',
                    'dateIssued': 'Today',
                    'status': 'Sent to Pharmacy',
                    'avatar': 'assets/d2.jpg',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-Prescription issued successfully!')));
              }
            },
            child: const Text('Issue Prescription', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPatientEhrSheet(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundImage: AssetImage(patient['avatar'])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patient['patientName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('ID: ${patient['id']} • Age: ${patient['age']} • ${patient['gender']}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text('Clinical Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Primary Diagnosis: ${patient['diagnosis']}'),
            Text('Risk Profile: ${patient['risk']}'),
            Text('Last Visit: ${patient['lastVisit']}'),
            const SizedBox(height: 16),
            const Text('Recent Prescriptions History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            const ListTile(
              leading: Icon(Icons.medication, color: AppColors.primary),
              title: Text('Ashwagandha 500mg'),
              subtitle: Text('1 tab BD after meals • 30 days'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 42)),
              child: const Text('Close Record', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlobalSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search patients, medications, or records...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = 2);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 40)),
              child: const Text('Search in Patient Records', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
