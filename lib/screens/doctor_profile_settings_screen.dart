import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_model.dart';
import '../services/doctor_auth_service.dart';
import 'login_screen.dart';
import 'doctor_manage_schedules_screen.dart';
import 'doctor_my_clinics_screen.dart';

class DoctorProfileSettingsScreen extends StatefulWidget {
  /// When [embeddedMode] is true the screen is rendered inside the doctor
  /// dashboard's bottom-nav tab — no separate AppBar is shown.
  final bool embeddedMode;
  const DoctorProfileSettingsScreen({super.key, this.embeddedMode = false});

  @override
  State<DoctorProfileSettingsScreen> createState() =>
      _DoctorProfileSettingsScreenState();
}

class _DoctorProfileSettingsScreenState
    extends State<DoctorProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  ApiDoctor? _doctor;

  late TabController _tabController;
  final List<String> _tabs = [
    'Personal',
    'Professional',
    'Expertise',
    'Bank',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Doctor session not found. Please login again.';
      });
      return;
    }
    try {
      final res = await DoctorAuthService.getProfile(token: token);
      if (!mounted) return;
      if (res.success && res.doctor != null) {
        setState(() {
          _doctor = res.doctor;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = res.message.isNotEmpty
              ? res.message
              : 'Failed to load profile.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Network error: $e';
      });
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);
      case 'pending':
        return const Color(0xFFD97706);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return AppColors.textLight;
    }
  }

  Color _statusBg(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return const Color(0xFFECFDF5);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: widget.embeddedMode
          ? null
          : AppBar(
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'My Profile',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refresh Profile',
                  onPressed: _fetchProfile,
                ),
              ],
              bottom: _doctor != null
                  ? TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    )
                  : null,
            ),
      body: widget.embeddedMode ? _buildEmbeddedBody() : _buildBody(),
    );
  }

  /// Embedded version: renders header + tab bar + tabs all inside the body
  /// (used when the screen is placed directly in the dashboard's bottom nav).
  Widget _buildEmbeddedBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading your profile...',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }
    if (_doctor == null) return const SizedBox();

    return Column(
      children: [
        _buildProfileHeaderCard(),
        Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalTab(),
              _buildProfessionalTab(),
              _buildExpertiseTab(),
              _buildBankTab(),
              _buildDocumentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading your profile...',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }
    if (_doctor == null) return const SizedBox();

    return Column(
      children: [
        _buildProfileHeaderCard(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalTab(),
              _buildProfessionalTab(),
              _buildExpertiseTab(),
              _buildBankTab(),
              _buildDocumentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROFILE HEADER CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProfileHeaderCard() {
    final doc = _doctor!;
    final name = doc.fullName.isNotEmpty ? doc.fullName : 'Doctor';
    final photoUrl = doc.documents?.profilePhoto ?? '';
    final status = doc.registrationStatus ?? 'pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8)
              ],
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  doc.ayushSystem ?? doc.currentDesignation ?? 'Ayush Practitioner',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                              radius: 3,
                              backgroundColor: _statusColor(status)),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _statusColor(status)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (doc.isMobileVerified == true)
                      const Tooltip(
                        message: 'Mobile Verified',
                        child: Icon(Icons.verified_rounded,
                            color: Color(0xFF6EE7B7), size: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1 – PERSONAL INFO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPersonalTab() {
    final doc = _doctor!;
    return _tabScroll([
      // Practice & Clinic Quick Access Banner
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Practice & Availability Setup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Set your weekly consultation timings, fees, and manage clinic locations.',
              style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorManageSchedulesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('My Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F766E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorMyClinicsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_hospital_rounded, size: 16),
                    label: const Text('My Clinics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _sectionCard('Contact Details', Icons.person_outline, [
        _infoRow(Icons.person_rounded, 'Full Name', doc.fullName, const Color(0xFF2563EB)),
        _infoRow(Icons.phone_android_rounded, 'Mobile', doc.mobile ?? 'N/A', const Color(0xFF059669)),
        _infoRow(Icons.email_outlined, 'Email', doc.email ?? 'N/A', const Color(0xFF7C3AED)),
        _infoRow(
          doc.isMobileVerified == true
              ? Icons.verified_rounded
              : Icons.pending_rounded,
          'Mobile Verified',
          doc.isMobileVerified == true ? 'Yes' : 'No',
          doc.isMobileVerified == true
              ? const Color(0xFF059669)
              : const Color(0xFFD97706),
        ),
      ]),
      const SizedBox(height: 14),
      _sectionCard('Personal Details', Icons.badge_outlined, [
        _infoRow(Icons.wc_rounded, 'Gender',
            _capitalize(doc.gender ?? 'N/A'), const Color(0xFFEC4899)),
        _infoRow(Icons.cake_rounded, 'Date of Birth',
            _formatDate(doc.dateOfBirth), const Color(0xFFEA580C)),
        _infoRow(Icons.work_rounded, 'Experience',
            '${doc.totalExperience ?? 'N/A'} Years', AppColors.primary),
        _infoRow(Icons.local_hospital_outlined, 'Current Hospital/Clinic',
            doc.currentClinicOrHospital ?? 'N/A', const Color(0xFF0EA5E9)),
        _infoRow(Icons.assignment_ind_outlined, 'Designation',
            doc.currentDesignation ?? 'N/A', const Color(0xFF8B5CF6)),
      ]),
      const SizedBox(height: 14),
      _sectionCard('Address', Icons.location_on_outlined, [
        _infoRow(Icons.home_outlined, 'Address', doc.address ?? 'N/A', const Color(0xFFEA580C)),
        _infoRow(Icons.location_city_outlined, 'City', doc.city ?? 'N/A', const Color(0xFF0284C7)),
        _infoRow(Icons.map_outlined, 'State', doc.state ?? 'N/A', const Color(0xFF059669)),
        _infoRow(Icons.pin_outlined, 'Pin Code', doc.pinCode ?? 'N/A', const Color(0xFF7C3AED)),
      ]),
      const SizedBox(height: 14),
      _sectionCard('Account Activity', Icons.access_time_outlined, [
        _infoRow(Icons.login_rounded, 'Last Login', _formatDate(doc.lastLoginAt), const Color(0xFF64748B)),
        _infoRow(Icons.calendar_today_rounded, 'Registered On', _formatDate(doc.createdAt), const Color(0xFF64748B)),
        _infoRow(Icons.update_rounded, 'Profile Updated', _formatDate(doc.updatedAt), const Color(0xFF64748B)),
      ]),
      const SizedBox(height: 24),
      // ── Logout Button ──────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmLogout(),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            label: const Text(
              'Logout Doctor Account',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ]);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from your doctor account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppState().clearDoctorSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2 – PROFESSIONAL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProfessionalTab() {
    final doc = _doctor!;
    final grad = doc.graduationDetails;
    final highest = doc.highestQualification;

    return _tabScroll([
      _sectionCard('AYUSH System', Icons.medical_services_outlined, [
        _infoRow(Icons.medical_information_outlined, 'AYUSH System',
            doc.ayushSystem ?? 'N/A', AppColors.primary),
        _infoRow(Icons.numbers_rounded, 'Registration Number',
            doc.registrationNumber ?? 'N/A', const Color(0xFF2563EB)),
        _infoRow(Icons.account_balance_outlined, 'State AYUSH Council',
            doc.stateAyushCouncil ?? 'N/A', const Color(0xFF059669)),
      ]),
      const SizedBox(height: 14),
      _sectionCard('Graduation Details', Icons.school_outlined, [
        _infoRow(Icons.school_rounded, 'University',
            grad?.universityName ?? 'N/A', const Color(0xFF7C3AED)),
        _infoRow(Icons.calendar_month_rounded, 'Year of Passing',
            grad?.yearOfPassing?.toString() ?? 'N/A', const Color(0xFFD97706)),
      ]),
      const SizedBox(height: 14),
      if (highest != null)
        _sectionCard('Highest Qualification', Icons.workspace_premium_outlined, [
          _infoRow(Icons.military_tech_outlined, 'Degree',
              highest.degree ?? 'N/A', const Color(0xFF2563EB)),
          _infoRow(Icons.science_outlined, 'Specialization',
              highest.specialization ?? 'N/A', AppColors.primary),
          _infoRow(Icons.account_balance_outlined, 'University',
              highest.universityName ?? 'N/A', const Color(0xFF7C3AED)),
          _infoRow(Icons.calendar_month_rounded, 'Year of Passing',
              highest.yearOfPassing?.toString() ?? 'N/A', const Color(0xFFD97706)),
        ]),
      const SizedBox(height: 14),
      if ((doc.about ?? '').isNotEmpty)
        _textCard('About', Icons.info_outline_rounded, doc.about!, const Color(0xFF0EA5E9)),
      const SizedBox(height: 14),
      if ((doc.consultationPhilosophy ?? '').isNotEmpty)
        _textCard('Consultation Philosophy', Icons.psychology_outlined,
            doc.consultationPhilosophy!, const Color(0xFF8B5CF6)),
      const SizedBox(height: 14),
      if ((doc.achievements ?? '').isNotEmpty)
        _textCard('Achievements', Icons.emoji_events_outlined,
            doc.achievements!, const Color(0xFFD97706)),
    ]);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3 – EXPERTISE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildExpertiseTab() {
    final expertise = _doctor!.expertise;
    final areas = expertise?.areasOfExpertise ?? [];
    final langs = expertise?.consultationLanguages ?? [];

    return _tabScroll([
      _sectionCard('Areas of Expertise', Icons.stars_rounded, []),
      const SizedBox(height: 4),
      if (areas.isEmpty)
        _emptyChip('No expertise areas added')
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: areas
                .map((a) => _expertiseChip(a, AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.1)))
                .toList(),
          ),
        ),
      const SizedBox(height: 20),
      _sectionCard('Consultation Languages', Icons.translate_rounded, []),
      const SizedBox(height: 4),
      if (langs.isEmpty)
        _emptyChip('No languages added')
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: langs
                .map((l) => _expertiseChip(l, const Color(0xFF0284C7),
                    const Color(0xFFE0F2FE)))
                .toList(),
          ),
        ),
    ]);
  }

  Widget _expertiseChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _emptyChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(label,
          style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 4 – BANK DETAILS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBankTab() {
    final bank = _doctor!.bankDetails;
    if (bank == null) {
      return _tabScroll([
        const SizedBox(height: 60),
        const Center(
          child: Column(
            children: [
              Icon(Icons.account_balance_outlined,
                  size: 48, color: AppColors.textLight),
              SizedBox(height: 12),
              Text('No bank details found',
                  style: TextStyle(color: AppColors.textLight, fontSize: 14)),
            ],
          ),
        )
      ]);
    }
    return _tabScroll([
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bank details are encrypted and used only for payment settlements.',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFF92400E), height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _sectionCard('Bank Account Details', Icons.account_balance_rounded, [
        _infoRow(Icons.person_outline, 'Account Holder',
            bank.accountHolderName ?? 'N/A', const Color(0xFF2563EB)),
        _infoRow(Icons.account_balance_outlined, 'Bank Name',
            bank.bankName ?? 'N/A', AppColors.primary),
        _infoRow(Icons.numbers_rounded, 'Account Number',
            _maskAccount(bank.accountNumber), const Color(0xFF7C3AED)),
        _infoRow(Icons.qr_code_rounded, 'IFSC Code',
            bank.ifscCode ?? 'N/A', const Color(0xFF059669)),
        _infoRow(Icons.credit_card_rounded, 'PAN Number',
            _maskPan(bank.panNumber), const Color(0xFFEA580C)),
      ]),
    ]);
  }

  String _maskAccount(String? acNum) {
    if (acNum == null || acNum.length < 4) return acNum ?? 'N/A';
    return '${'*' * (acNum.length - 4)}${acNum.substring(acNum.length - 4)}';
  }

  String _maskPan(String? pan) {
    if (pan == null || pan.length < 4) return pan ?? 'N/A';
    return '${pan.substring(0, 2)}${'*' * (pan.length - 4)}${pan.substring(pan.length - 2)}';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 5 – DOCUMENTS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDocumentsTab() {
    final docs = _doctor!.documents;
    if (docs == null) {
      return _tabScroll([
        const SizedBox(height: 60),
        const Center(
          child: Column(
            children: [
              Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textLight),
              SizedBox(height: 12),
              Text('No documents found',
                  style: TextStyle(color: AppColors.textLight, fontSize: 14)),
            ],
          ),
        )
      ]);
    }

    final docEntries = <_DocEntry>[
      _DocEntry('Profile Photo', Icons.person_rounded, docs.profilePhoto,
          const Color(0xFF2563EB)),
      _DocEntry('Aadhaar Front', Icons.credit_card_rounded, docs.aadhaarFront,
          const Color(0xFF059669)),
      _DocEntry('Aadhaar Back', Icons.credit_card_outlined, docs.aadhaarBack,
          const Color(0xFF0D9488)),
      _DocEntry('PAN Card', Icons.badge_rounded, docs.panCard,
          const Color(0xFF7C3AED)),
      _DocEntry('Registration Certificate', Icons.workspace_premium_rounded,
          docs.registrationCertificate, const Color(0xFFD97706)),
      _DocEntry('Cancelled Cheque', Icons.account_balance_rounded,
          docs.cancelledCheque, const Color(0xFFEA580C)),
    ];

    return _tabScroll([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uploaded Documents',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            ...docEntries.map((e) => _docTile(e)),
            if ((docs.degreeCertificates ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Degree Certificates',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              ...docs.degreeCertificates!.asMap().entries.map((entry) =>
                  _docTile(_DocEntry(
                      'Degree Certificate ${entry.key + 1}',
                      Icons.school_rounded,
                      entry.value,
                      const Color(0xFF8B5CF6)))),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _docTile(_DocEntry entry) {
    final hasDoc = entry.url != null && entry.url!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasDoc
                ? entry.color.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, color: entry.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(
                  hasDoc ? 'Uploaded ✓' : 'Not uploaded',
                  style: TextStyle(
                      fontSize: 11,
                      color: hasDoc
                          ? const Color(0xFF059669)
                          : AppColors.textLight,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (hasDoc)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text('Verified',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669))),
                ],
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Missing',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _tabScroll(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _sectionCard(
      String title, IconData icon, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard(
      String title, IconData icon, String content, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;
}

class _DocEntry {
  final String name;
  final IconData icon;
  final String? url;
  final Color color;
  const _DocEntry(this.name, this.icon, this.url, this.color);
}
