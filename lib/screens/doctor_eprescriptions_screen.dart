import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/eprescription_service.dart';
import 'eprescription_detail_screen.dart';

class DoctorEPrescriptionsScreen extends StatefulWidget {
  final bool isEmbedded;

  const DoctorEPrescriptionsScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<DoctorEPrescriptionsScreen> createState() =>
      _DoctorEPrescriptionsScreenState();
}

class _DoctorEPrescriptionsScreenState
    extends State<DoctorEPrescriptionsScreen> {
  final TextEditingController _rxSearchController = TextEditingController();
  Timer? _rxSearchDebounce;

  String _rxStatusFilter = 'All Statuses';
  String _rxSearchQuery = '';
  bool _isLoading = false;

  List<Map<String, dynamic>> _allPrescriptions = [];
  List<Map<String, dynamic>> _filteredPrescriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  @override
  void dispose() {
    _rxSearchController.dispose();
    _rxSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrescriptions({bool showSpinner = true}) async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;

    if (showSpinner && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final rxRes = await EPrescriptionService.getDoctorPrescriptions(
        token: token,
        limit: 100,
      );

      if (!mounted) return;

      if (rxRes['success'] == true && rxRes['prescriptions'] is List) {
        final list = List<Map<String, dynamic>>.from(rxRes['prescriptions']);
        setState(() {
          _allPrescriptions = list;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _rxSearchQuery.toLowerCase().trim();

    final filtered = _allPrescriptions.where((rx) {
      // 1. Status Filter
      if (_rxStatusFilter != 'All Statuses') {
        final status = (rx['status'] ?? '').toString().toLowerCase();
        switch (_rxStatusFilter) {
          case 'Sent':
            if (status != 'sent') return false;
            break;
          case 'Sent to Pharmacy':
            if (status != 'sent_to_pharmacy') return false;
            break;
          case 'Dispensed':
            if (status != 'dispensed') return false;
            break;
          case 'Cancelled':
            if (status != 'cancelled') return false;
            break;
        }
      }

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final patientName =
            (rx['patientName'] ?? '').toString().toLowerCase();
        final rxNo = (rx['prescriptionNumber'] ?? rx['id'] ?? '')
            .toString()
            .toLowerCase();
        final diagnosis = (rx['diagnosis'] ?? '').toString().toLowerCase();
        final mobile = (rx['patientMobile'] ?? '').toString().toLowerCase();

        String medsText = '';
        if (rx['medications'] is List) {
          medsText = (rx['medications'] as List)
              .map((m) => m is Map ? (m['name'] ?? '').toString() : '')
              .join(' ')
              .toLowerCase();
        }

        final matches = patientName.contains(query) ||
            rxNo.contains(query) ||
            diagnosis.contains(query) ||
            mobile.contains(query) ||
            medsText.contains(query);

        if (!matches) return false;
      }

      return true;
    }).toList();

    _filteredPrescriptions = filtered;
  }

  void _onStatusFilterSelected(String status) {
    setState(() {
      _rxStatusFilter = status;
      _applyFilters();
    });
  }

  void _onSearchChanged(String val) {
    setState(() {
      _rxSearchQuery = val;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: () => _fetchPrescriptions(showSpinner: false),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Metric Cards — always visible, derived instantly
            _buildMetricsRow(),
            const SizedBox(height: 10),

            // Search & Status Filter Bar — ALWAYS VISIBLE & REACTIVE
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search patient, Rx number, diagnosis...',
                      prefixIcon: const Icon(Icons.search,
                          size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _rxSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                _rxSearchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status filter chips with INSTANT UI CHANGE
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All Statuses',
                        'Sent',
                        'Sent to Pharmacy',
                        'Dispensed'
                      ].map((st) {
                        final isSelected = _rxStatusFilter == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(st),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFCBD5E1),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                _onStatusFilterSelected(st);
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

            if (_isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: Color(0xFFE2E8F0),
                minHeight: 2,
              ),
            ],

            const SizedBox(height: 12),

            // Results count row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _rxStatusFilter != 'All Statuses' ||
                          _rxSearchQuery.isNotEmpty
                      ? '${_filteredPrescriptions.length} result${_filteredPrescriptions.length == 1 ? "" : "s"}${_rxSearchQuery.isNotEmpty ? " for \"$_rxSearchQuery\"" : ""}${_rxStatusFilter != "All Statuses" ? " · $_rxStatusFilter" : ""}'
                      : '${_allPrescriptions.length} prescription${_allPrescriptions.length == 1 ? "" : "s"} total',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
                GestureDetector(
                  onTap: () => _fetchPrescriptions(showSpinner: true),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Refresh',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Prescription list
            if (_filteredPrescriptions.isEmpty)
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
                    Icon(Icons.receipt_long_outlined,
                        size: 44, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      _allPrescriptions.isEmpty
                          ? 'No e-prescriptions yet.\nPull down to refresh.'
                          : 'No prescriptions match your filters.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          height: 1.5),
                    ),
                  ],
                ),
              )
            else
              ..._filteredPrescriptions
                  .map((rx) => _buildPrescriptionCard(rx)),

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
                  const Icon(Icons.local_pharmacy_rounded,
                      color: Color(0xFF5EEAD4), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Pharmacy Integration Active',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(height: 2),
                        Text(
                            'Connected to local pharmacies. HIPAA compliant & encrypted.',
                            style: TextStyle(
                                color: Color(0xFFCCFBF1), fontSize: 10)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'E-Prescriptions',
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
      body: SafeArea(child: body),
    );
  }

  Widget _buildMetricsRow() {
    final int sentCount =
        _allPrescriptions.where((r) => r['status'] == 'sent').length;
    final int pharmacyCount = _allPrescriptions
        .where((r) => r['status'] == 'sent_to_pharmacy')
        .length;
    final int dispensedCount =
        _allPrescriptions.where((r) => r['status'] == 'dispensed').length;

    return Row(
      children: [
        Expanded(
          child: _buildRxStatCard(
            label: 'Total Rx',
            value: '${_allPrescriptions.length}',
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
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(sub,
              style: const TextStyle(fontSize: 8, color: AppColors.textLight)),
        ],
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
          medText =
              '${firstMed['name']}${firstMed['strength'] != null ? " ${firstMed['strength']}" : ""}';
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

    final bool hasPharmacyNotes = rx['pharmacyNotes'] != null &&
        rx['pharmacyNotes'].toString().isNotEmpty;

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EPrescriptionDetailScreen(prescriptionId: rxId),
              ),
            );
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
                      patientName.isNotEmpty
                          ? patientName[0].toUpperCase()
                          : 'P',
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
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight),
                              ),
                              const Text(' • ',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textLight)),
                            ],
                            if (patientMobile.isNotEmpty)
                              Text(
                                patientMobile,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              // Diagnosis
              Row(
                children: [
                  const Icon(Icons.medical_information_outlined,
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      diagnosis.isNotEmpty ? diagnosis : 'General Consultation',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500),
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
                  const Icon(Icons.medication_outlined,
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      medText,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
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
                    const Icon(Icons.store_outlined,
                        size: 13, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rx['pharmacyNotes'].toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFD97706)),
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
                        const Icon(Icons.calendar_today_outlined,
                            size: 10, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          issuedDate,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8)),
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
                      const Icon(Icons.chevron_right,
                          size: 14, color: AppColors.primary),
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
}
