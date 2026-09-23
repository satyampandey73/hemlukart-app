import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/eprescription_service.dart';
import 'eprescription_detail_screen.dart';
import 'login_screen.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMsg = '';

  // Filter state
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _statusFilters = [
    'All',
    'sent',
    'sent_to_pharmacy',
    'dispensed',
    'cancelled',
  ];

  static const Map<String, String> _statusLabels = {
    'All': 'All',
    'sent': 'Sent',
    'sent_to_pharmacy': 'At Pharmacy',
    'dispensed': 'Dispensed',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    if (!mounted) return;
    final appState = AppState();
    if (!appState.isLoggedIn || appState.authToken == null || appState.authToken!.isEmpty) {
      setState(() {
        _isLoading = false;
        _prescriptions = [];
        _hasError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final token = appState.authToken;
    final res = await EPrescriptionService.getPatientPrescriptions(
      token: token,
      limit: 50,
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
    );

    if (!mounted) return;
    if (res['success'] == true && res['prescriptions'] is List) {
      setState(() {
        _prescriptions = List<Map<String, dynamic>>.from(res['prescriptions']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMsg = res['message'] ?? 'Failed to load prescriptions.';
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  _StatusMeta _statusMeta(String raw) {
    switch (raw.toLowerCase()) {
      case 'dispensed':
        return _StatusMeta(
          label: 'Dispensed',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFDBEAFE),
        );
      case 'sent_to_pharmacy':
        return _StatusMeta(
          label: 'At Pharmacy',
          icon: Icons.local_pharmacy_rounded,
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
        );
      case 'cancelled':
        return _StatusMeta(
          label: 'Cancelled',
          icon: Icons.cancel_rounded,
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEF2F2),
        );
      default:
        return _StatusMeta(
          label: 'Sent',
          icon: Icons.send_rounded,
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              setState(() => _searchQuery = val);
              // Debounce-style: trigger search after typing stops
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchQuery == val && mounted) _loadPrescriptions();
              });
            },
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by doctor, Rx no, or diagnosis…',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textLight),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadPrescriptions();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final isSelected = _selectedStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 10),
                  child: ChoiceChip(
                    label: Text(_statusLabels[s] ?? s),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                    onSelected: (_) {
                      if (_selectedStatus != s) {
                        setState(() => _selectedStatus = s);
                        _loadPrescriptions();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!AppState().isLoggedIn) {
      return _buildLoggedOutView();
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPrescriptions,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Prescriptions Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedStatus != 'All' || _searchQuery.isNotEmpty
                    ? 'Try clearing your filters.'
                    : 'Prescriptions issued by your doctor will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrescriptions,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _prescriptions.length,
        itemBuilder: (context, index) => _buildPrescriptionCard(_prescriptions[index]),
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
                Icons.receipt_long_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to view your prescriptions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access e-prescriptions, doctor advice, and medication schedules issued for your consultations.',
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
                  ).then((_) => _loadPrescriptions());
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

  Widget _buildPrescriptionCard(Map<String, dynamic> rx) {
    final rxNo = (rx['prescriptionNumber'] ?? rx['id'] ?? '—').toString();
    final doctorName = (rx['doctorName'] ?? 'Doctor').toString();
    final doctorSpec = (rx['doctorSpecialization'] ?? '').toString();
    final diagnosis = (rx['diagnosis'] ?? '').toString();
    final statusRaw = (rx['status'] ?? 'sent').toString();
    final issuedAt = (rx['issuedAt'] ?? '').toString();
    final validUpto = (rx['validUpto'] ?? '').toString();
    final pharmacyNotes = (rx['pharmacyNotes'] ?? '').toString();
    final List meds = rx['medications'] is List ? rx['medications'] as List : [];
    final meta = _statusMeta(statusRaw);
    final refillsAllowed = (rx['refillsAllowed'] ?? 0) as int;
    final refillsUsed = (rx['refillsUsed'] ?? 0) as int;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EPrescriptionDetailScreen(prescriptionData: rx),
          ),
        ).then((_) => _loadPrescriptions());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: meta.bg.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description_rounded, size: 18, color: meta.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rxNo,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Issued: ${_formatDate(issuedAt)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: meta.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 10, color: meta.color),
                        const SizedBox(width: 4),
                        Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: meta.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. $doctorName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (doctorSpec.isNotEmpty)
                              Text(
                                doctorSpec,
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Diagnosis
                  if (diagnosis.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.sick_outlined, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            diagnosis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Medications count + valid until
                  Row(
                    children: [
                      _infoChip(
                        Icons.medication_outlined,
                        '${meds.length} Med${meds.length == 1 ? '' : 's'}',
                      ),
                      const SizedBox(width: 6),
                      _infoChip(
                        Icons.event_available_outlined,
                        'Valid till ${_formatDate(validUpto)}',
                      ),
                      if (refillsAllowed > 0) ...[
                        const SizedBox(width: 6),
                        _infoChip(
                          Icons.replay_rounded,
                          '${refillsAllowed - refillsUsed} refill${refillsAllowed - refillsUsed == 1 ? '' : 's'}',
                          color: refillsAllowed - refillsUsed > 0
                              ? const Color(0xFF16A34A)
                              : AppColors.error,
                        ),
                      ],
                    ],
                  ),

                  // Pharmacy notes (if present)
                  if (pharmacyNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.store_outlined, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pharmacyNotes,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // View Detail footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    final textColor = color ?? AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _StatusMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatusMeta({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });
}
