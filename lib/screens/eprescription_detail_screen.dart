import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/eprescription_service.dart';
import '../services/prescription_product_helper.dart';
import 'cart_screen.dart';

class EPrescriptionDetailScreen extends StatefulWidget {
  final String? prescriptionId;
  final Map<String, dynamic>? prescriptionData;
  final bool isDoctorView;

  const EPrescriptionDetailScreen({
    super.key,
    this.prescriptionId,
    this.prescriptionData,
    this.isDoctorView = false,
  }) : assert(
          prescriptionId != null || prescriptionData != null,
          'Provide at least prescriptionId or prescriptionData',
        );

  @override
  State<EPrescriptionDetailScreen> createState() =>
      _EPrescriptionDetailScreenState();
}

class _EPrescriptionDetailScreenState extends State<EPrescriptionDetailScreen> {
  Map<String, dynamic>? _rx;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionData != null) {
      _rx = widget.prescriptionData;
    }
    final targetId = widget.prescriptionId ??
        _rx?['_id']?.toString() ??
        _rx?['id']?.toString();
    if (targetId != null && targetId.isNotEmpty) {
      _fetchDetails(targetId);
    }
  }

  Future<void> _fetchDetails(String id) async {
    if (_rx == null) {
      if (mounted) setState(() => _isLoading = true);
    }
    final token = AppState().activeToken ??
        AppState().authToken ??
        AppState().doctorToken;
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
        if (_rx == null) {
          _errorMsg = res['message'] ?? 'Failed to load prescription.';
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'viewed':
        return const Color(0xFF0F766E);
      case 'sent':
      case 'issued':
        return const Color(0xFF2563EB);
      case 'sent_to_pharmacy':
        return const Color(0xFFD97706);
      case 'dispensed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'viewed':
        return const Color(0xFFE6F7F5);
      case 'sent':
      case 'issued':
        return const Color(0xFFEFF6FF);
      case 'sent_to_pharmacy':
        return const Color(0xFFFFFBEB);
      case 'dispensed':
        return const Color(0xFFF0FDF4);
      case 'cancelled':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFE6F7F5);
    }
  }

  bool _isMedInCart(Map m) {
    final pid = PrescriptionProductHelper.extractProductId(m);
    if (pid == null) return false;
    return AppState().cart.any((item) => item.product.id == pid);
  }

  Future<void> _addAllInStoreToCart(List inStoreMeds) async {
    int addedCount = 0;
    for (final m in inStoreMeds) {
      final prod = await PrescriptionProductHelper.getProductFromMed(m);
      if (prod != null) {
        await AppState().addToCart(prod, qty: 1);
        addedCount++;
      }
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$addedCount medicine(s) added to cart!'),
        backgroundColor: const Color(0xFF0F766E),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.amber,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _addSingleMedToCart(Map m) async {
    final prod = await PrescriptionProductHelper.getProductFromMed(m);
    if (prod != null) {
      await AppState().addToCart(prod, qty: 1);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${prod.name} added to cart!'),
          backgroundColor: const Color(0xFF0F766E),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.amber,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _rx == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'E-Prescription Details',
            style: TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0F766E)),
        ),
      );
    }

    if (_errorMsg != null && _rx == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 52, color: AppColors.error),
                const SizedBox(height: 12),
                Text(_errorMsg!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final id = widget.prescriptionId ?? _rx?['id'];
                    if (id != null) _fetchDetails(id.toString());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rx = _rx ?? {};
    final rxNo = (rx['prescriptionNumber'] ?? rx['id'] ?? '—').toString();
    final doctorName = (rx['doctorName'] ?? 'Doctor').toString();
    final doctorSpec = (rx['doctorSpecialization'] ?? 'Ayurvedic Physician').toString();
    final issuedAt = (rx['issuedAt'] ?? rx['createdAt'] ?? '').toString();
    final status = (rx['status'] ?? 'VIEWED').toString().toUpperCase();
    final diagnosis = (rx['diagnosis'] ?? 'General Consultation').toString();
    final findings = (rx['clinicalFindings'] ?? rx['findings'] ?? '').toString();
    final labTests = (rx['labTests'] ?? rx['tests'] ?? '').toString();
    final generalInstructions = (rx['generalInstructions'] ?? rx['instructions'] ?? '').toString();
    final List meds = rx['medications'] is List ? rx['medications'] as List : [];

    final bool isDoctor = widget.isDoctorView ||
        AppState().isDoctorLoggedIn ||
        (AppState().doctorToken != null && AppState().doctorToken!.isNotEmpty) ||
        AppState().currentUser?.role.toLowerCase() == 'doctor' ||
        AppState().currentUser?.role.toLowerCase() == 'provider' ||
        AppState().currentDoctorProfile != null;

    // Filter in-store meds
    final inStoreMeds = meds.where((m) => PrescriptionProductHelper.isMedicationInStore(m)).toList();
    final bool allInCart = inStoreMeds.isNotEmpty && inStoreMeds.every((m) => _isMedInCart(m));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'E-Prescription Details',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              rxNo.startsWith('RX') ? rxNo : 'Prescription #$rxNo',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (!isDoctor)
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F172A), size: 22),
                  if (AppState().cart.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F766E),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${AppState().cart.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      bottomNavigationBar: (!isDoctor && inStoreMeds.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF0F766E)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${inStoreMeds.length} in-store medicine${inStoreMeds.length == 1 ? "" : "s"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            allInCart ? 'All items in your cart' : 'Ready for direct checkout',
                            style: TextStyle(
                              fontSize: 11,
                              color: allInCart ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (allInCart) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        } else {
                          _addAllInStoreToCart(inStoreMeds);
                        }
                      },
                      icon: Icon(
                        allInCart ? Icons.shopping_bag_outlined : Icons.add_shopping_cart_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        allInCart ? 'Go to Cart' : 'Add All to Cart',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP DOCTOR & CONSULTATION CARD ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Doctor Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0F766E)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctorSpec.isNotEmpty ? doctorSpec : 'Ayurvedic Physician',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F766E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(status).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _statusColor(status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),

                  // Metadata Row: Issued Date & Prescription Code
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Issued: ${_formatDate(issuedAt)}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 12, color: Color(0xFF0F766E)),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified E-Rx',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── CLINICAL SUMMARY CARD (Diagnosis & Findings) ────────────────
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Row(
                    children: [
                      Icon(Icons.medical_information_outlined, size: 16, color: Color(0xFF0F766E)),
                      SizedBox(width: 6),
                      Text(
                        'Clinical Summary',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Diagnosis Block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.healing_rounded, size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Primary Diagnosis',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                diagnosis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Clinical Findings Block (if present)
                  if (findings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description_outlined, size: 15, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Observations & Clinical Findings',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  findings,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── PRESCRIBED MEDICATIONS SECTION ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.medication_rounded, size: 18, color: Color(0xFF0F766E)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Prescribed Medications (${meds.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDoctor && inStoreMeds.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () => _addAllInStoreToCart(inStoreMeds),
                    icon: const Icon(Icons.add_shopping_cart, size: 13, color: Color(0xFF0F766E)),
                    label: const Text(
                      'Add All',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            if (meds.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No medications prescribed.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              )
            else
              ...meds.map((entry) {
                final m = entry is Map ? entry : {};
                final name = (m['name'] ?? 'Medication').toString();
                final strength = (m['strength'] ?? m['dosage'] ?? '').toString();
                final dosage = (m['dosage'] ?? '1 tablet').toString();
                final dosageForm = (m['dosageForm'] ?? 'Tablet').toString();
                final frequency = (m['frequency'] ?? 'Once daily').toString();
                final duration = (m['duration'] ?? '30 days').toString();
                final instructions = (m['instructions'] ?? m['timing'] ?? '').toString();
                final inStore = PrescriptionProductHelper.isMedicationInStore(m);
                final inCart = _isMedInCart(m);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: inStore ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                      width: inStore ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header: Medicine Name + Availability Tag
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: inStore ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: inStore ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                Icons.medication_liquid_outlined,
                                size: 18,
                                color: inStore ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (strength.isNotEmpty && strength != dosage) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      strength,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // In-Store / Not in store pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: inStore ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: inStore ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inStore ? Icons.storefront_rounded : Icons.info_outline_rounded,
                                    size: 11,
                                    color: inStore ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    inStore ? 'In Store' : 'Not in Store',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: inStore ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dosage, Frequency, Duration Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _medBadge(Icons.grain_rounded, '$dosage · $dosageForm'),
                            _medBadge(Icons.schedule_rounded, frequency),
                            _medBadge(Icons.timelapse_rounded, duration),
                          ],
                        ),

                        // Instructions / Timing Note
                        if (instructions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFD97706)),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    instructions,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Footer Action (Only for patient)
                        if (!isDoctor) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
                          if (inStore) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (inCart)
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CartScreen()),
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF0F766E)),
                                    label: const Text(
                                      'Item in Cart (View)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF0F766E)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: () => _addSingleMedToCart(m),
                                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 13, color: Colors.white),
                                    label: const Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            const Row(
                              children: [
                                Icon(Icons.store_outlined, size: 12, color: Color(0xFF94A3B8)),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Available at your local medical pharmacy store.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              }),

            // ── LAB TESTS CARD ──────────────────────────────────────────────
            if (labTests.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.biotech_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'Prescribed Diagnostic & Lab Tests',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labTests,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],

            // ── GENERAL INSTRUCTIONS CARD ───────────────────────────────────
            if (generalInstructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFD97706)),
                        SizedBox(width: 6),
                        Text(
                          'Doctor Advice & General Instructions',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      generalInstructions,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _medBadge(IconData icon, String text) {
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
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

