import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'my_prescriptions_screen.dart';
import 'my_appointments_screen.dart';
import 'my_orders_screen.dart';
import 'wishlist_screen.dart';
import 'shipping_addresses_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingProfile = false;

  // Profile section expansion states (collapsed by default)
  bool _isPersonalExpanded = false;
  bool _isAddressExpanded = false;
  bool _isAccountExpanded = false;

  // Settings toggles
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _biometrics = true;
  bool _twoFactor = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final appState = AppState();
    if (appState.authToken != null && appState.authToken!.isNotEmpty) {
      if (mounted) setState(() => _isLoadingProfile = true);
      await appState.fetchUserProfile();
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return isoString;
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: const [],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _buildProfileHeader(user),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Profile'),
                Tab(icon: Icon(Icons.settings_rounded, size: 18), text: 'Settings'),
              ],
            ),
          ),
        ],
        body: ColoredBox(
          color: const Color(0xFFF3F6FB),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(user),
              _buildSettingsTab(user),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile header (SliverAppBar background) ─────────────────────────────

  Widget _buildProfileHeader(UserModel? user) {
    final initials = (user != null && user.fullName.isNotEmpty)
        ? user.fullName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'P';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    backgroundImage: (user?.profileImage != null &&
                            user!.profileImage!.startsWith('http'))
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: (user?.profileImage == null ||
                            !user!.profileImage!.startsWith('http'))
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 26,
                            ),
                          )
                        : null,
                  ),
                  if (user?.isMobileVerified ?? false)
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Color(0xFF10B981), size: 18),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.fullName ?? 'Patient Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.email ?? 'No email',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user != null && user.mobile.isNotEmpty
                          ? '+91 ${user.mobile}'
                          : 'No phone number',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _headerBadge((user?.role ?? 'PATIENT').toUpperCase()),
                        const SizedBox(width: 6),
                        _headerBadge(
                          (user?.isActive ?? true) ? '● ACTIVE' : '● INACTIVE',
                          color: (user?.isActive ?? true)
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : Colors.red.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBadge(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── PROFILE TAB ──────────────────────────────────────────────────────────

  Widget _buildProfileTab(UserModel? user) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Edit Profile Banner ───────────────────────────────────────
            GestureDetector(
              onTap: () => _showEditProfileDialog(context, user),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF14B8A6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Update your name, photo, address & more',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),

            // ── Personal Information ──────────────────────────────────────
            _buildExpandableSection(
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Personal Information',
              subtitle: user != null && user.fullName.isNotEmpty
                  ? user.fullName
                  : 'Name, email, mobile & gender',
              isExpanded: _isPersonalExpanded,
              onToggle: () =>
                  setState(() => _isPersonalExpanded = !_isPersonalExpanded),
              children: [
                _infoRow(
                  icon: Icons.person_outline,
                  iconColor: const Color(0xFF2563EB),
                  label: 'Full Name',
                  value: user?.fullName ?? 'N/A',
                ),
                _infoRow(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Email',
                  value: user?.email ?? 'N/A',
                ),
                _infoRow(
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFF059669),
                  label: 'Mobile',
                  value: user != null && user.mobile.isNotEmpty
                      ? '+91 ${user.mobile}'
                      : 'N/A',
                ),
                _infoRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF16A34A),
                  label: 'WhatsApp',
                  value: user != null && user.whatsappNumber.isNotEmpty
                      ? '+91 ${user.whatsappNumber}'
                      : 'N/A',
                ),
                // Date of Birth — hidden
                // Gender — hidden
              ],
            ),

            // ── Address Details — commented out ───────────────────────────
            // _buildExpandableSection(
            //   icon: Icons.location_on_outlined,
            //   iconColor: const Color(0xFFEA580C),
            //   title: 'Address',
            //   subtitle: ...,
            //   isExpanded: _isAddressExpanded,
            //   onToggle: () => setState(() => _isAddressExpanded = !_isAddressExpanded),
            //   children: [ address, city, state, pincode rows ],
            //   bottomAction: 'Edit Profile Details' button,
            // ),


            // ── Account Details ───────────────────────────────────────────
            _buildExpandableSection(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF7C3AED),
              title: 'Account Details',
              subtitle: (user?.isMobileVerified ?? false)
                  ? 'Active & Mobile Verified'
                  : 'Verification & account status',
              isExpanded: _isAccountExpanded,
              onToggle: () =>
                  setState(() => _isAccountExpanded = !_isAccountExpanded),
              children: [
                _infoRow(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFFEA580C),
                  label: 'Patient ID',
                  value: user != null && user.id.length > 12
                      ? '${user.id.substring(0, 12)}…'
                      : (user?.id ?? 'N/A'),
                  onCopy: user?.id,
                ),
                _infoRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: AppColors.primary,
                  label: 'Mobile Verified',
                  value:
                      (user?.isMobileVerified ?? false) ? 'Verified' : 'Pending',
                  valueColor: (user?.isMobileVerified ?? false)
                      ? const Color(0xFF059669)
                      : Colors.amber.shade700,
                ),
                _infoRow(
                  icon: Icons.access_time_outlined,
                  iconColor: const Color(0xFF64748B),
                  label: 'Last Login',
                  value: _formatDate(user?.lastLoginAt),
                ),
                _infoRow(
                  icon: Icons.calendar_today_outlined,
                  iconColor: const Color(0xFF0284C7),
                  label: 'Member Since',
                  value: _formatDate(user?.createdAt),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Health Records ────────────────────────────────────────────
            _sectionLabel(Icons.folder_shared_outlined, 'Health Records'),
            const SizedBox(height: 8),
            _navCard(
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primary,
              title: 'My Prescriptions',
              subtitle: 'View prescriptions issued by your doctors',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyPrescriptionsScreen())),
            ),
            const SizedBox(height: 8),
            _navCard(
              icon: Icons.calendar_month_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'My Appointments',
              subtitle: 'View past and upcoming consultations',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyAppointmentsScreen())),
            ),
            const SizedBox(height: 20),

            // ── Shopping ──────────────────────────────────────────────────
            _sectionLabel(Icons.shopping_bag_outlined, 'Shopping'),
            const SizedBox(height: 8),
            _navCard(
              icon: Icons.shopping_cart_outlined,
              iconColor: const Color(0xFF0284C7),
              title: 'My Orders',
              subtitle: 'Track and manage your product orders',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
            ),
            const SizedBox(height: 8),
            _navCard(
              icon: Icons.favorite_border_rounded,
              iconColor: const Color(0xFFE11D48),
              title: 'My Wishlist',
              subtitle: 'Saved products and doctors',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen())),
            ),
            const SizedBox(height: 8),
            _navCard(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFEA580C),
              title: 'Saved Addresses',
              subtitle: 'Manage shipping and delivery addresses',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShippingAddressesScreen())),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── SETTINGS TAB ─────────────────────────────────────────────────────────

  Widget _buildSettingsTab(UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Notifications ─────────────────────────────────────────────
          _sectionLabel(Icons.notifications_outlined, 'Notification Preferences'),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDecoration(),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    activeThumbColor: AppColors.primary,
                    secondary: _settingIcon(Icons.notifications_active_outlined, AppColors.primary),
                    title: const Text('Push Notifications',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    subtitle: const Text('Real-time updates for appointments & orders',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    activeThumbColor: AppColors.primary,
                    secondary: _settingIcon(Icons.mark_email_unread_outlined, const Color(0xFF3B82F6)),
                    title: const Text('Email & Health Tips',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    subtitle: const Text('Seasonal care guides and promo codes',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    value: _emailUpdates,
                    onChanged: (val) => setState(() => _emailUpdates = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Security ──────────────────────────────────────────────────
          _sectionLabel(Icons.lock_outline_rounded, 'Security & Authentication'),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDecoration(),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    activeThumbColor: AppColors.primary,
                    secondary: _settingIcon(Icons.fingerprint_rounded, const Color(0xFF8B5CF6)),
                    title: const Text('Biometric / Face ID',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    subtitle: const Text('Use biometrics for fast and secure login',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    value: _biometrics,
                    onChanged: (val) => setState(() => _biometrics = val),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    activeThumbColor: AppColors.primary,
                    secondary: _settingIcon(Icons.security_rounded, const Color(0xFF10B981)),
                    title: const Text('Two-Factor Authentication',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    subtitle: const Text('Require SMS verification code on login',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    value: _twoFactor,
                    onChanged: (val) => setState(() => _twoFactor = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── App Info ──────────────────────────────────────────────────
          _sectionLabel(Icons.info_outline_rounded, 'App Info'),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDecoration(),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.verified_outlined,
                    iconColor: const Color(0xFF0284C7),
                    label: 'App Version',
                    value: '1.0.0',
                  ),
                  _infoRow(
                    icon: Icons.person_pin_outlined,
                    iconColor: const Color(0xFF64748B),
                    label: 'Account Role',
                    value: (user?.role ?? 'Patient').toUpperCase(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sign Out ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200.withValues(alpha: 0.5)),
            ),
            child: Material(
              color: Colors.red.shade50.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _handleSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sign Out of Account',
                                style: TextStyle(fontSize: 14, color: AppColors.error, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            const Text('Log out of your patient session',
                                style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _buildExpandableSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
    Widget? bottomAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: (isExpanded ? iconColor : const Color(0xFF64748B))
                            .withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? iconColor : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ...children
                    .asMap()
                    .entries
                    .map((e) => Column(
                          children: [
                            e.value,
                            if (e.key < children.length - 1)
                              const Divider(
                                height: 1,
                                indent: 52,
                                color: Color(0xFFF1F5F9),
                              ),
                          ],
                        )),
                if (bottomAction != null) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: bottomAction,
                  ),
                ],
              ],
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    String? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: onCopy));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textLight),
            ),
          ],
        ],
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your patient account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AppState().logout();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, UserModel? user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          user: user,
          onSaved: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Screen
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileScreen extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onSaved;

  const _EditProfileScreen({this.user, this.onSaved});

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  String _selectedGender = 'male';
  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl    = TextEditingController(text: u?.fullName ?? '');
    _emailCtrl   = TextEditingController(text: u?.email ?? '');
    _mobileCtrl  = TextEditingController(text: u?.mobile ?? '');
    _dobCtrl     = TextEditingController(text: u?.dateOfBirth ?? '');
    _addressCtrl = TextEditingController(text: u?.address ?? '');
    _cityCtrl    = TextEditingController(text: u?.city ?? '');
    _stateCtrl   = TextEditingController(text: u?.state ?? '');
    _pincodeCtrl = TextEditingController(text: u?.pincode ?? '');
    _selectedGender = u?.gender ?? 'male';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Profile Photo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked != null && mounted) {
        setState(() => _pickedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime(1990, 1, 1);
    if (_dobCtrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobCtrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _dobCtrl.text = formatted);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final appState = AppState();
    final res = await appState.updateUserProfile(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      gender: _selectedGender,
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
      profileImage: _pickedImage,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message),
        backgroundColor: res.success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (res.success) {
      widget.onSaved?.call();
      Navigator.pop(context);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final initials = (user != null && user.fullName.isNotEmpty)
        ? user.fullName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile picture ──────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : (user?.profileImage != null &&
                                  user!.profileImage!.startsWith('http'))
                              ? NetworkImage(user.profileImage!)
                              : null,
                      child: (_pickedImage == null &&
                              (user?.profileImage == null ||
                                  !user!.profileImage!.startsWith('http')))
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Tap the camera icon to change photo',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 24),

              // ── Personal Information ─────────────────────────────────────
              _editSectionLabel(Icons.person_outline_rounded, 'Personal Information'),
              const SizedBox(height: 12),
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _mobileCtrl,
                label: 'Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Mobile is required';
                  if (v.trim().length != 10) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Date of Birth — removed
              // Gender — removed


              // ── Address ──────────────────────────────────────────────────
              _editSectionLabel(Icons.location_on_outlined, 'Address Details'),
              const SizedBox(height: 12),
              _buildField(
                controller: _addressCtrl,
                label: 'Address',
                icon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _cityCtrl,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _stateCtrl,
                      label: 'State',
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _pincodeCtrl,
                label: 'Pincode',
                icon: Icons.markunread_mailbox_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(height: 32),

              // ── Save Button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: Text(
                    _isSaving ? 'Saving Changes...' : 'Save Changes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editSectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        counterText: '',
      ),
    );
  }
}
