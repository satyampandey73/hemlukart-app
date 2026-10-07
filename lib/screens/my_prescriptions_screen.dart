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
  String _selectedStatus = 'All Statuses';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;

  static const List<String> _statusFilters = [
    'All Statuses',
    'viewed',
    'sent',
    'sent_to_pharmacy',
    'dispensed',
    'cancelled',
  ];

  static const Map<String, String> _statusLabels = {
    'All Statuses': 'All Statuses',
    'viewed': 'Viewed',
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

  Future<void> _loadPrescriptions({bool silent = false}) async {
    if (!mounted) return;
    final appState = AppState();
    final token = appState.activeToken ?? appState.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _prescriptions = [];
        _hasError = false;
      });
      return;
    }

    // Only show full loading state if this is the initial empty load and not silent
    if (!silent && _prescriptions.isEmpty) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    final statusParam = _selectedStatus == 'All Statuses'
        ? null
        : _selectedStatus;

    final res = await EPrescriptionService.getPatientPrescriptions(
      token: token,
      limit: 50,
      status: statusParam,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
    );

    if (!mounted) return;
    if (res['success'] == true && res['prescriptions'] is List) {
      List<Map<String, dynamic>> list =
          List<Map<String, dynamic>>.from(res['prescriptions']);

      // Apply date filters locally if selected
      if (_fromDate != null) {
        list = list.where((rx) {
          final dtStr = rx['issuedAt'] ?? rx['createdAt'];
          if (dtStr == null) return true;
          final dt = DateTime.tryParse(dtStr.toString());
          if (dt == null) return true;
          return dt.isAfter(_fromDate!.subtract(const Duration(days: 1)));
        }).toList();
      }
      if (_toDate != null) {
        list = list.where((rx) {
          final dtStr = rx['issuedAt'] ?? rx['createdAt'];
          if (dtStr == null) return true;
          final dt = DateTime.tryParse(dtStr.toString());
          if (dt == null) return true;
          return dt.isBefore(_toDate!.add(const Duration(days: 1)));
        }).toList();
      }

      setState(() {
        _prescriptions = list;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        if (_prescriptions.isEmpty) {
          _hasError = true;
          _errorMsg = res['message'] ?? 'Failed to load prescriptions.';
        }
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
      final dayStr = dt.day.toString().padLeft(2, '0');
      return '$dayStr ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  String _formatDateShort(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  _StatusMeta _statusMeta(String raw) {
    switch (raw.toLowerCase()) {
      case 'viewed':
        return const _StatusMeta(
          label: 'VIEWED',
          color: Color(0xFF0F766E),
          bg: Color(0xFFE6F7F5),
          dotColor: Color(0xFF0D9488),
        );
      case 'dispensed':
        return const _StatusMeta(
          label: 'DISPENSED',
          color: Color(0xFF2563EB),
          bg: Color(0xFFEFF6FF),
          dotColor: Color(0xFF3B82F6),
        );
      case 'sent_to_pharmacy':
        return const _StatusMeta(
          label: 'AT PHARMACY',
          color: Color(0xFFD97706),
          bg: Color(0xFFFFFBEB),
          dotColor: Color(0xFFF59E0B),
        );
      case 'cancelled':
        return const _StatusMeta(
          label: 'CANCELLED',
          color: Color(0xFFDC2626),
          bg: Color(0xFFFEF2F2),
          dotColor: Color(0xFFEF4444),
        );
      default: // sent / issued
        return const _StatusMeta(
          label: 'ACTIVE',
          color: Color(0xFF059669),
          bg: Color(0xFFECFDF5),
          dotColor: Color(0xFF10B981),
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'My Prescriptions',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF0F766E), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified e-prescriptions issued by your doctors during consultations.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter & Search Box matching Screenshot 1
              _buildFilterBox(),
              const SizedBox(height: 16),

              // Prescriptions Body
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBox() {
    final bool hasActiveFilter = _selectedStatus != 'All Statuses' ||
        _fromDate != null ||
        _toDate != null ||
        _searchQuery.trim().isNotEmpty;

    int activeCount = 0;
    if (_selectedStatus != 'All Statuses') activeCount++;
    if (_fromDate != null) activeCount++;
    if (_toDate != null) activeCount++;
    if (_searchQuery.trim().isNotEmpty) activeCount++;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _searchQuery.isNotEmpty ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                setState(() => _searchQuery = val);
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (_searchQuery == val && mounted) _loadPrescriptions();
                });
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search doctor, diagnosis, medication...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0F766E)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _loadPrescriptions();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Header Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded, size: 15, color: Color(0xFF475569)),
                  const SizedBox(width: 5),
                  const Text(
                    'Filter By',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Text(
                        '$activeCount active',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasActiveFilter)
                InkWell(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedStatus = 'All Statuses';
                      _fromDate = null;
                      _toDate = null;
                    });
                    _loadPrescriptions();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 13, color: Color(0xFFEF4444)),
                        SizedBox(width: 3),
                        Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Filters Row: Status Dropdown + Date Range
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status Dropdown
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _selectedStatus != 'All Statuses' ? const Color(0xFFE6F7F5) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedStatus != 'All Statuses' ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF0F766E)),
                    isDense: true,
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedStatus != 'All Statuses' ? const Color(0xFF0F766E) : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    items: _statusFilters.map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(_statusLabels[s] ?? s),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatus = val);
                        _loadPrescriptions();
                      }
                    },
                  ),
                ),
              ),

              // From Date Picker
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _fromDate = picked);
                    _loadPrescriptions();
                  }
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _fromDate != null ? const Color(0xFFE6F7F5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _fromDate != null ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: _fromDate != null ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _fromDate != null ? 'From: ${_formatDateShort(_fromDate!)}' : 'From Date',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _fromDate != null ? const Color(0xFF0F766E) : const Color(0xFF475569),
                        ),
                      ),
                      if (_fromDate != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() => _fromDate = null);
                            _loadPrescriptions();
                          },
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0F766E)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // To Date Picker
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _toDate = picked);
                    _loadPrescriptions();
                  }
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _toDate != null ? const Color(0xFFE6F7F5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _toDate != null ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 13,
                        color: _toDate != null ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _toDate != null ? 'To: ${_formatDateShort(_toDate!)}' : 'To Date',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _toDate != null ? const Color(0xFF0F766E) : const Color(0xFF475569),
                        ),
                      ),
                      if (_toDate != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() => _toDate = null);
                            _loadPrescriptions();
                          },
                          child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0F766E)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final appState = AppState();
    final token = appState.activeToken ?? appState.authToken;
    if (token == null || token.isEmpty) {
      return _buildLoggedOutView();
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    if (_hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 10),
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPrescriptions,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              ),
            ],
          ),
        ),
      );
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 40,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No Prescriptions Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prescriptions issued by your doctors will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) => _buildPrescriptionCard(_prescriptions[index]),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F7F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 52,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sign in to view your prescriptions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Access e-prescriptions, doctor advice, and medication schedules issued for your consultations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => _loadPrescriptions());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Widget Matching Screenshot 1 ─────────────────────────────────────

  Widget _buildPrescriptionCard(Map<String, dynamic> rx) {
    final rxNo = (rx['prescriptionNumber'] ?? rx['id'] ?? '—').toString();
    final doctorName = (rx['doctorName'] ?? 'Doctor').toString();
    final diagnosis = (rx['diagnosis'] ?? '').toString();
    final statusRaw = (rx['status'] ?? 'viewed').toString();
    final issuedAt = (rx['issuedAt'] ?? rx['createdAt'] ?? '').toString();
    final List meds = rx['medications'] is List ? rx['medications'] as List : [];
    final meta = _statusMeta(statusRaw);
    final refillsAllowed = (rx['refillsAllowed'] ?? rx['refills'] ?? 0) as int;

    void openDetail() async {
      final shouldRefresh = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EPrescriptionDetailScreen(
            prescriptionId: (rx['_id'] ?? rx['id'])?.toString(),
            prescriptionData: rx,
            isDoctorView: AppState().isDoctorLoggedIn ||
                (AppState().doctorToken != null && AppState().doctorToken!.isNotEmpty) ||
                AppState().currentUser?.role.toLowerCase() == 'doctor' ||
                AppState().currentUser?.role.toLowerCase() == 'provider' ||
                AppState().currentDoctorProfile != null,
          ),
        ),
      );
      if (shouldRefresh == true && mounted) {
        _loadPrescriptions(silent: true);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: openDetail,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Rx Badge Icon + Prescription Number & Date + Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF0F766E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rxNo.startsWith('RX') ? rxNo : 'Prescription #$rxNo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 10, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  _formatDate(issuedAt),
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: meta.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: meta.color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(color: meta.dotColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meta.label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: meta.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Doctor Information Strip (Single Line, No Column)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Diagnosis Banner (if present)
                if (diagnosis.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_information_outlined, size: 14, color: Color(0xFF15803D)),
                        const SizedBox(width: 5),
                        const Text(
                          'Diagnosis: ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            diagnosis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF14532D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Prescribed Medicines Chips
                if (meds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medication_outlined, size: 13, color: Color(0xFF0F766E)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Prescribed Medicines (${meds.length}):',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            ...meds.take(3).map((m) {
                              final mName = (m['name'] ?? 'Medication').toString();
                              final strength = (m['strength'] ?? m['dosage'] ?? '').toString();
                              final label = strength.isNotEmpty ? '$mName ($strength)' : mName;
                              final bool hasProduct = m['productId'] != null && m['productId'].toString().isNotEmpty;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: hasProduct ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: hasProduct ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasProduct ? Icons.storefront_outlined : Icons.medication_liquid_outlined,
                                      size: 11,
                                      color: hasProduct ? const Color(0xFF059669) : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 120),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: hasProduct ? const Color(0xFF065F46) : const Color(0xFF334155),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (meds.length > 3)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${meds.length - 3} more',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Bottom Divider & Actions Row (Flex-Safe & Compact)
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            refillsAllowed > 0 ? Icons.replay_circle_filled_outlined : Icons.verified_user_outlined,
                            size: 13,
                            color: refillsAllowed > 0 ? const Color(0xFFD97706) : const Color(0xFF0F766E),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              refillsAllowed > 0 ? '$refillsAllowed Refill${refillsAllowed == 1 ? "" : "s"}' : 'Verified Rx',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: refillsAllowed > 0 ? const Color(0xFFD97706) : const Color(0xFF0F766E),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _StatusMeta {
  final String label;
  final Color color;
  final Color bg;
  final Color dotColor;
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.bg,
    required this.dotColor,
  });
}
