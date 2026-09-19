import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/eprescription_service.dart';

class EPrescriptionDetailScreen extends StatefulWidget {
  /// Pass either a pre-loaded [prescriptionData] map OR a [prescriptionId]
  /// to fetch from the API. If both are given, data is shown immediately
  /// while a background refresh happens.
  final String? prescriptionId;
  final Map<String, dynamic>? prescriptionData;

  const EPrescriptionDetailScreen({
    super.key,
    this.prescriptionId,
    this.prescriptionData,
  }) : assert(
          prescriptionId != null || prescriptionData != null,
          'Provide at least prescriptionId or prescriptionData',
        );

  @override
  State<EPrescriptionDetailScreen> createState() =>
      _EPrescriptionDetailScreenState();
}

class _EPrescriptionDetailScreenState
    extends State<EPrescriptionDetailScreen> {
  Map<String, dynamic>? _rx;
  bool _isLoading = false;
  bool _statusActionBusy = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionData != null) {
      _rx = widget.prescriptionData;
    }
    if (widget.prescriptionId != null) {
      _fetchDetails(widget.prescriptionId!);
    }
  }

  Future<void> _fetchDetails(String id) async {
    if (mounted) setState(() => _isLoading = true);
    final token = AppState().doctorToken;
    final res = await EPrescriptionService.getPrescriptionById(
      prescriptionId: id,
      token: token,
    );
    if (!mounted) return;
    if (res['success'] == true && res['prescription'] != null) {
      setState(() {
        _rx = Map<String, dynamic>.from(res['prescription']);
        _isLoading = false;
        _errorMsg = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = res['message'] ?? 'Failed to load prescription.';
      });
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      default: // sent
        return _StatusMeta(
          label: 'Sent',
          icon: Icons.send_rounded,
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFDCFCE7),
        );
    }
  }

  // ── Action handlers ───────────────────────────────────────────────────────

  Future<void> _handleUpdateStatus(String newStatus) async {
    final rxId = (_rx?['id'] ?? '').toString();
    if (rxId.isEmpty) return;

    // Collect optional pharmacy notes via dialog
    final notesCtrl = TextEditingController(
      text: (_rx?['pharmacyNotes'] ?? '').toString(),
    );

    final String? confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String label;
        Color color;
        IconData icon;
        switch (newStatus) {
          case 'sent_to_pharmacy':
            label = 'Send to Pharmacy';
            color = const Color(0xFFD97706);
            icon = Icons.local_pharmacy_rounded;
            break;
          default:
            label = 'Mark as Dispensed';
            color = const Color(0xFF2563EB);
            icon = Icons.check_circle_rounded;
        }
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update status to "${newStatus.replaceAll('_', ' ')}"?',
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 14),
              const Text('Pharmacy Notes (optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Sent to Apollo Pharmacy, Order #...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, notesCtrl.text),
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        );
      },
    );

    if (confirmed == null || !mounted) return;

    setState(() => _statusActionBusy = true);
    final token = AppState().doctorToken;
    final res = await EPrescriptionService.updatePrescriptionStatus(
      prescriptionId: rxId,
      status: newStatus,
      pharmacyNotes: confirmed,
      token: token,
    );
    if (!mounted) return;
    setState(() => _statusActionBusy = false);

    if (res['success'] == true && res['prescription'] != null) {
      setState(() => _rx = Map<String, dynamic>.from(res['prescription']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Status updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update status'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    final rxId = (_rx?['id'] ?? '').toString();
    if (rxId.isEmpty) return;

    final reasonCtrl = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 8),
            Text('Cancel Prescription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action cannot be undone. Provide a reason for cancellation.',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 14),
            const Text('Reason (optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Wrong medication prescribed...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Rx', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Rx', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _statusActionBusy = true);
    final token = AppState().doctorToken;
    final res = await EPrescriptionService.cancelPrescription(
      prescriptionId: rxId,
      reason: reasonCtrl.text,
      token: token,
    );
    if (!mounted) return;
    setState(() => _statusActionBusy = false);

    if (res['success'] == true && res['prescription'] != null) {
      setState(() => _rx = Map<String, dynamic>.from(res['prescription']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription cancelled'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to cancel prescription'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: _buildBody(),
      bottomNavigationBar: _rx != null ? _buildActionBar(_rx!) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _rx == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F6FB),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_errorMsg != null && _rx == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Prescription', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_errorMsg!, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textLight)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _fetchDetails(widget.prescriptionId ?? ''),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retry', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rx = _rx!;
    return _buildDetail(rx);
  }

  Widget _buildActionBar(Map<String, dynamic> rx) {
    final statusRaw = (rx['status'] ?? 'sent').toString().toLowerCase();
    // No actions for terminal states
    if (statusRaw == 'cancelled' || statusRaw == 'dispensed') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: _statusActionBusy
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Row(
              children: [
                // Cancel button — always shown for non-terminal statuses
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleCancel,
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Cancel Rx',
                        style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Primary action depends on current status
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => statusRaw == 'sent'
                        ? _handleUpdateStatus('sent_to_pharmacy')
                        : _handleUpdateStatus('dispensed'),
                    icon: Icon(
                      statusRaw == 'sent'
                          ? Icons.local_pharmacy_rounded
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      statusRaw == 'sent'
                          ? 'Send to Pharmacy'
                          : 'Mark Dispensed',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusRaw == 'sent'
                          ? const Color(0xFFD97706)
                          : const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetail(Map<String, dynamic> rx) {
    final rxNo        = rx['prescriptionNumber'] ?? rx['id'] ?? '—';
    final patientName = (rx['patientName'] ?? 'Patient').toString();
    final patientAge  = rx['patientAge'];
    final patientMob  = (rx['patientMobile'] ?? '').toString();
    final patientGender = (rx['patientGender'] ?? '').toString();
    final doctorName  = (rx['doctorName'] ?? 'Doctor').toString();
    final doctorSpec  = (rx['doctorSpecialization'] ?? '').toString();
    final doctorReg   = (rx['doctorRegistrationNumber'] ?? '').toString();
    final diagnosis   = (rx['diagnosis'] ?? '').toString();
    final findings    = (rx['clinicalFindings'] ?? '').toString();
    final labTests    = (rx['labTests'] ?? '').toString();
    final dietary     = (rx['dietaryInstructions'] ?? '').toString();
    final general     = (rx['generalInstructions'] ?? '').toString();
    final doctorNotes = (rx['doctorNotes'] ?? '').toString();
    final pharmacyNotes = (rx['pharmacyNotes'] ?? '').toString();
    final followUp    = (rx['followUpDate'] ?? '').toString();
    final issuedAt    = (rx['issuedAt'] ?? '').toString();
    final validUpto   = (rx['validUpto'] ?? '').toString();
    final dispensedAt = (rx['dispensedAt'] ?? '').toString();
    final refillsAllowed = rx['refillsAllowed'] ?? 0;
    final refillsUsed    = rx['refillsUsed'] ?? 0;
    final List meds   = rx['medications'] is List ? rx['medications'] as List : [];
    final statusRaw   = (rx['status'] ?? 'sent').toString();
    final meta        = _statusMeta(statusRaw);

    return CustomScrollView(
      slivers: [
        // ── Collapsible App Bar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 130,
          pinned: true,
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: 'Copy Rx Number',
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: rxNo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rx number copied'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 56),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rxNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.bg.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, size: 9, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            meta.label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SECTION: Patient & Doctor ──────────────────────────
                _sectionHeader(Icons.person_outline_rounded, 'Patient Information'),
                const SizedBox(height: 8),
                _infoCard(children: [
                  _infoRow(Icons.badge_outlined, 'Name', patientName),
                  if (patientAge != null)
                    _infoRow(Icons.cake_outlined, 'Age', '$patientAge years'),
                  if (patientGender.isNotEmpty)
                    _infoRow(Icons.wc_outlined, 'Gender', patientGender),
                  if (patientMob.isNotEmpty)
                    _infoRow(Icons.phone_outlined, 'Mobile', patientMob),
                ]),
                const SizedBox(height: 16),

                _sectionHeader(Icons.medical_services_outlined, 'Prescribing Doctor'),
                const SizedBox(height: 8),
                _infoCard(children: [
                  _infoRow(Icons.person_pin_outlined, 'Name', 'Dr. $doctorName'),
                  if (doctorSpec.isNotEmpty)
                    _infoRow(Icons.stars_outlined, 'Specialization', doctorSpec),
                  if (doctorReg.isNotEmpty)
                    _infoRow(Icons.numbers_outlined, 'Reg. Number', doctorReg),
                ]),
                const SizedBox(height: 16),

                // ── SECTION: Diagnosis ──────────────────────────────────
                _sectionHeader(Icons.biotech_outlined, 'Diagnosis & Findings'),
                const SizedBox(height: 8),
                _infoCard(children: [
                  _infoRow(Icons.sick_outlined, 'Diagnosis', diagnosis.isNotEmpty ? diagnosis : '—'),
                  if (findings.isNotEmpty)
                    _infoRow(Icons.find_in_page_outlined, 'Clinical Findings', findings),
                ]),
                const SizedBox(height: 16),

                // ── SECTION: Medications ────────────────────────────────
                _sectionHeader(Icons.medication_outlined, 'Medications  (${meds.length})'),
                const SizedBox(height: 8),
                if (meds.isEmpty)
                  _emptyChip('No medications recorded')
                else
                  ...meds.asMap().entries.map((e) => _medicationCard(e.key, e.value)),
                const SizedBox(height: 16),
                // ── SECTION: Lab Tests ──────────────────────────────────
                if (labTests.isNotEmpty) ...[
                  _sectionHeader(Icons.science_outlined, 'Lab Tests & Investigations'),
                  const SizedBox(height: 8),
                  _textBlock(labTests),
                  const SizedBox(height: 16),
                ],

                // ── SECTION: Instructions ───────────────────────────────
                if (dietary.isNotEmpty || general.isNotEmpty) ...[
                  _sectionHeader(Icons.list_alt_outlined, 'Instructions'),
                  const SizedBox(height: 8),
                  _infoCard(children: [
                    if (dietary.isNotEmpty)
                      _infoRow(Icons.restaurant_outlined, 'Dietary', dietary),
                    if (general.isNotEmpty)
                      _infoRow(Icons.info_outline_rounded, 'General', general),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ── SECTION: Notes ──────────────────────────────────────
                if (doctorNotes.isNotEmpty || pharmacyNotes.isNotEmpty) ...[
                  _sectionHeader(Icons.sticky_note_2_outlined, 'Notes'),
                  const SizedBox(height: 8),
                  _infoCard(children: [
                    if (doctorNotes.isNotEmpty)
                      _infoRow(Icons.edit_note_rounded, 'Doctor Notes', doctorNotes),
                    if (pharmacyNotes.isNotEmpty)
                      _infoRow(Icons.store_outlined, 'Pharmacy Notes', pharmacyNotes),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ── SECTION: Validity & Dates ───────────────────────────
                _sectionHeader(Icons.calendar_month_outlined, 'Validity & Timeline'),
                const SizedBox(height: 8),
                _infoCard(children: [
                  _infoRow(Icons.event_available_outlined, 'Issued On', _formatDate(issuedAt)),
                  _infoRow(Icons.event_busy_outlined, 'Valid Until', _formatDate(validUpto)),
                  if (dispensedAt.isNotEmpty && dispensedAt != 'null')
                    _infoRow(Icons.done_all_rounded, 'Dispensed On', _formatDate(dispensedAt)),
                  if (followUp.isNotEmpty && followUp != 'null')
                    _infoRow(Icons.event_repeat_outlined, 'Follow-Up', _formatDate(followUp)),
                ]),
                const SizedBox(height: 16),

                // ── SECTION: Refills ────────────────────────────────────
                _sectionHeader(Icons.replay_rounded, 'Refill Information'),
                const SizedBox(height: 8),
                _refillCard(refillsAllowed: refillsAllowed, refillsUsed: refillsUsed),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Section builder helpers ───────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title) {
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

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      const Divider(height: 1, indent: 42, color: Color(0xFFF1F5F9)),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBlock(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textDark, height: 1.6),
      ),
    );
  }

  Widget _emptyChip(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(msg, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
    );
  }

  Widget _medicationCard(int index, dynamic med) {
    final Map m = med is Map ? med : {};
    final name        = (m['name'] ?? 'Medication').toString();
    final strength    = (m['strength'] ?? '').toString();
    final dosageForm  = (m['dosageForm'] ?? 'Tablet').toString();
    final dosage      = (m['dosage'] ?? '').toString();
    final frequency   = (m['frequency'] ?? '').toString();
    final duration    = (m['duration'] ?? '').toString();
    final timing      = (m['timing'] ?? '').toString();
    final instructions = (m['instructions'] ?? '').toString();
    final qty         = m['quantity'];
    final refillable  = m['refillable'] == true;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name${strength.isNotEmpty ? "  $strength" : ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dosageForm,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _medChip(Icons.content_paste_rounded, 'Dosage', dosage),
                    const SizedBox(width: 8),
                    _medChip(Icons.repeat_rounded, 'Frequency', frequency),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _medChip(Icons.hourglass_bottom_rounded, 'Duration', duration),
                    const SizedBox(width: 8),
                    _medChip(Icons.schedule_outlined, 'Timing', timing.isNotEmpty ? timing : '—'),
                  ],
                ),
                if (qty != null || refillable) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (qty != null)
                        _medChip(Icons.numbers_rounded, 'Qty', '$qty units'),
                      if (qty != null) const SizedBox(width: 8),
                      _medChip(
                        refillable ? Icons.autorenew_rounded : Icons.block_rounded,
                        'Refillable',
                        refillable ? 'Yes' : 'No',
                        chipColor: refillable
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        labelColor: refillable
                            ? const Color(0xFF16A34A)
                            : AppColors.error,
                      ),
                    ],
                  ),
                ],
                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 13, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            instructions,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medChip(
    IconData icon,
    String label,
    String value, {
    Color chipColor = const Color(0xFFF8FAFC),
    Color labelColor = AppColors.textDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textLight),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                  ),
                  Text(
                    value.isNotEmpty ? value : '—',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _refillCard({required int refillsAllowed, required int refillsUsed}) {
    final remaining = (refillsAllowed - refillsUsed).clamp(0, refillsAllowed);
    final progress = refillsAllowed > 0 ? refillsUsed / refillsAllowed : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.replay_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '$refillsUsed of $refillsAllowed refills used',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: remaining > 0
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  remaining > 0 ? '$remaining left' : 'No refills left',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0
                        ? const Color(0xFF16A34A)
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (refillsAllowed > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > 0 ? AppColors.primary : AppColors.error,
                ),
              ),
            ),
          ],
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
