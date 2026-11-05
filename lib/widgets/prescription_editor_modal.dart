import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_state.dart';
import '../services/eprescription_service.dart';
import '../services/product_service.dart';
import '../services/prescription_product_helper.dart';
import '../services/prescription_window_helper.dart';

/// Opens the E-Prescription Editor / Creator Modal Bottom Sheet.
/// Supports both creating a new prescription and editing an existing one (PUT /api/e-prescriptions/:id).
Future<void> showPrescriptionEditorModal(
  BuildContext context, {
  String? patientName,
  String? appointmentId,
  String? userId,
  Map<String, dynamic>? existingPrescription,
  String? prescriptionId,
  Function(Map<String, dynamic> prescription)? onPrescriptionSaved,
}) async {
  final String effectiveRxId = (prescriptionId != null && prescriptionId.isNotEmpty)
      ? prescriptionId
      : (existingPrescription?['id']?.toString() ??
          existingPrescription?['_id']?.toString() ??
          '');
  final bool isEditing = effectiveRxId.isNotEmpty;

  final String effectiveAptId = (appointmentId != null && appointmentId.isNotEmpty)
      ? appointmentId
      : (existingPrescription?['appointmentId']?.toString() ?? '');

  if (effectiveAptId.isNotEmpty && !PrescriptionWindowHelper.isWindowOpen(appointmentId: effectiveAptId)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing
            ? 'Prescription editing is only allowed within 5 minutes of consultation end.'
            : 'Prescription can only be issued within 5 minutes of consultation end.'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
    return;
  }

  final rxDiagnosisCtrl = TextEditingController(
    text: existingPrescription?['diagnosis']?.toString() ?? 'General Health Consultation',
  );
  final rxFindingsCtrl = TextEditingController(
    text: existingPrescription?['clinicalFindings']?.toString() ??
        existingPrescription?['findings']?.toString() ??
        'Routine checkup, symptoms noted',
  );
  final rxLabCtrl = TextEditingController(
    text: existingPrescription?['labTests']?.toString() ??
        existingPrescription?['tests']?.toString() ??
        '',
  );
  final rxDietCtrl = TextEditingController(
    text: existingPrescription?['dietaryInstructions']?.toString() ?? '',
  );
  final rxGeneralCtrl = TextEditingController(
    text: existingPrescription?['generalInstructions']?.toString() ??
        existingPrescription?['instructions']?.toString() ??
        '',
  );
  final rxFollowUpCtrl = TextEditingController(
    text: existingPrescription?['followUpDate']?.toString() ?? '',
  );

  int validityDays = existingPrescription?['validityDays'] is int
      ? existingPrescription!['validityDays'] as int
      : (int.tryParse(existingPrescription?['validityDays']?.toString() ?? '') ?? 30);
  int refillsAllowed = existingPrescription?['refillsAllowed'] is int
      ? existingPrescription!['refillsAllowed'] as int
      : (int.tryParse(existingPrescription?['refillsAllowed']?.toString() ?? '') ?? 2);

  Map<String, dynamic> makeMedItem({
    String name = '',
    String strength = '500mg',
    String dosageForm = 'Tablet',
    String dosage = '1 tab',
    String frequency = 'Twice daily',
    String duration = '7 days',
    String timing = 'After meals',
    String instructions = 'Take with water',
    String quantity = '14',
    bool refillable = false,
    String? productId,
    Product? product,
  }) {
    return {
      "name": TextEditingController(text: name),
      "strength": TextEditingController(text: strength),
      "dosageForm": dosageForm,
      "dosage": TextEditingController(text: dosage),
      "frequency": frequency,
      "duration": TextEditingController(text: duration),
      "timing": timing,
      "instructions": TextEditingController(text: instructions),
      "quantity": TextEditingController(text: quantity),
      "refillable": refillable,
      "productId": productId,
      "selectedProduct": product,
      "searchCtrl": TextEditingController(text: name),
      "searchResults": <Product>[],
      "isSearching": false,
      "showSuggestions": false,
      "debounceTimer": null as Timer?,
    };
  }

  List<Map<String, dynamic>> medications = [];
  if (existingPrescription != null && existingPrescription['medications'] is List) {
    final rawMeds = existingPrescription['medications'] as List;
    for (final m in rawMeds) {
      if (m is Map) {
        final pId = PrescriptionProductHelper.extractProductId(m);
        medications.add(makeMedItem(
          name: m['name']?.toString() ?? '',
          strength: m['strength']?.toString() ?? '500mg',
          dosageForm: m['dosageForm']?.toString() ?? 'Tablet',
          dosage: m['dosage']?.toString() ?? '1 tab',
          frequency: m['frequency']?.toString() ?? 'Twice daily',
          duration: m['duration']?.toString() ?? '7 days',
          timing: m['timing']?.toString() ?? 'After meals',
          instructions: m['instructions']?.toString() ?? '',
          quantity: m['quantity']?.toString() ?? '14',
          refillable: m['refillable'] == true,
          productId: pId,
        ));
      }
    }
  }
  if (medications.isEmpty) {
    medications = [
      makeMedItem(
        name: "Ashwagandha",
        strength: "500mg",
        dosage: "1 tablet",
        instructions: "Take with warm milk or water",
        quantity: "30",
        refillable: true,
      ),
    ];
  }

  bool isLoading = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setStateModal) {
        void onMedSearchChanged(Map<String, dynamic> med, String query) {
          (med['debounceTimer'] as Timer?)?.cancel();
          if (query.trim().isEmpty) {
            setStateModal(() {
              med['searchResults'] = <Product>[];
              med['isSearching'] = false;
              med['showSuggestions'] = false;
            });
            return;
          }

          setStateModal(() {
            med['isSearching'] = true;
            med['showSuggestions'] = true;
          });

          med['debounceTimer'] = Timer(const Duration(milliseconds: 300), () async {
            try {
              final res = await ProductService.getProducts(search: query.trim(), limit: 8);
              if (res.success) {
                final prods = res.products.map((p) => p.toProduct()).toList();
                setStateModal(() {
                  med['searchResults'] = prods;
                  med['isSearching'] = false;
                });
              } else {
                setStateModal(() {
                  med['searchResults'] = <Product>[];
                  med['isSearching'] = false;
                });
              }
            } catch (_) {
              setStateModal(() {
                med['searchResults'] = <Product>[];
                med['isSearching'] = false;
              });
            }
          });
        }

        void selectProduct(Map<String, dynamic> med, Product prod) {
          PrescriptionProductHelper.cacheProduct(prod);
          setStateModal(() {
            med['productId'] = prod.id;
            med['selectedProduct'] = prod;
            (med['name'] as TextEditingController).text = prod.name;
            (med['searchCtrl'] as TextEditingController).text = prod.name;
            med['showSuggestions'] = false;
            med['searchResults'] = <Product>[];
            if (prod.potency.isNotEmpty && prod.potency != 'Standard') {
              (med['strength'] as TextEditingController).text = prod.potency;
            }
          });
        }

        void selectCustomMedicine(Map<String, dynamic> med, String customName) {
          setStateModal(() {
            med['productId'] = null;
            med['selectedProduct'] = null;
            (med['name'] as TextEditingController).text = customName.trim();
            (med['searchCtrl'] as TextEditingController).text = customName.trim();
            med['showSuggestions'] = false;
            med['searchResults'] = <Product>[];
          });
        }

        void unlinkProduct(Map<String, dynamic> med) {
          setStateModal(() {
            med['productId'] = null;
            med['selectedProduct'] = null;
            (med['searchCtrl'] as TextEditingController).clear();
            med['showSuggestions'] = false;
            med['searchResults'] = <Product>[];
          });
        }

        final effectivePatient = patientName ?? existingPrescription?['patientName']?.toString();

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Handle & Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF0F766E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'Edit E-Prescription' : 'Issue E-Prescription',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      isEditing ? 'Update medicines and patient advice' : 'Digital prescription for patient',
                                      style: const TextStyle(
                                        fontSize: 11,
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
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            for (final m in medications) {
                              (m['debounceTimer'] as Timer?)?.cancel();
                            }
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Summary Banner
                      if (effectivePatient != null && effectivePatient.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, size: 16, color: Color(0xFF15803D)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effectivePatient,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF14532D),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (appointmentId != null && appointmentId.isNotEmpty)
                                      Text(
                                        'Consultation #$appointmentId',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF15803D),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    else if (effectiveRxId.isNotEmpty)
                                      Text(
                                        'Rx ID: $effectiveRxId',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF15803D),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── SECTION 1: CLINICAL ASSESSMENT ────────────────
                      Row(
                        children: [
                          const Icon(Icons.health_and_safety_outlined, size: 16, color: Color(0xFF0F766E)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '1. Clinical Assessment',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Diagnosis
                      TextField(
                        controller: rxDiagnosisCtrl,
                        decoration: InputDecoration(
                          labelText: 'Diagnosis *',
                          hintText: 'e.g., Acid Peptic Disorder, Joint Pain, Hypertension',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Clinical Findings
                      TextField(
                        controller: rxFindingsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Clinical Findings / Symptoms',
                          hintText: 'e.g., BP 120/80 mmHg, pulse normal, symptoms duration 5 days',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── SECTION 2: MEDICATIONS ─────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.medication_outlined, size: 16, color: Color(0xFF0F766E)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '2. Medications (Rx)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              setStateModal(() {
                                medications.add(makeMedItem());
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: Color(0xFF0F766E)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add Medicine',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Medication Cards
                      ...medications.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> med = entry.value;
                        final bool hasLinkedProduct = med['productId'] != null && med['productId'].toString().isNotEmpty;
                        final Product? selProduct = med['selectedProduct'] as Product?;
                        final bool showSug = med['showSuggestions'] == true;
                        final List<Product> results = (med['searchResults'] as List<Product>?) ?? [];
                        final bool isSearching = med['isSearching'] == true;
                        final String searchTxt = (med['searchCtrl'] as TextEditingController).text.trim();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasLinkedProduct ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                              width: hasLinkedProduct ? 1.5 : 1,
                            ),
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
                              // Card Top: Pill Index + Status + Remove
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F766E),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Med #${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (hasLinkedProduct)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle, size: 11, color: Color(0xFF15803D)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'STORE PRODUCT',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CUSTOM ITEM',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (medications.length > 1)
                                    InkWell(
                                      onTap: () {
                                        setStateModal(() {
                                          (med['debounceTimer'] as Timer?)?.cancel();
                                          medications.removeAt(index);
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Product search & Store linking
                              if (hasLinkedProduct) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          selProduct?.image ?? '',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Image.asset('assets/p1.png', width: 40, height: 40, fit: BoxFit.cover),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selProduct?.name ?? (med['name'] as TextEditingController).text,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (selProduct != null)
                                              Text(
                                                '₹${selProduct.price} • ${selProduct.brand}',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w500),
                                              ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => unlinkProduct(med),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        child: const Text('Change', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ] else ...[
                                TextField(
                                  controller: med['searchCtrl'] as TextEditingController,
                                  decoration: InputDecoration(
                                    labelText: 'Search Product in Store Catalog',
                                    hintText: 'e.g. Ashwagandha, Triphala, Brahmi...',
                                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF0F766E)),
                                    suffixIcon: isSearching
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2),
                                            ),
                                          )
                                        : (searchTxt.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16),
                                                onPressed: () {
                                                  setStateModal(() {
                                                    (med['searchCtrl'] as TextEditingController).clear();
                                                    med['searchResults'] = <Product>[];
                                                    med['showSuggestions'] = false;
                                                  });
                                                },
                                              )
                                            : null),
                                    isDense: true,
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                                  onChanged: (val) => onMedSearchChanged(med, val),
                                ),

                                // Dropdown Suggestions
                                if (showSug && searchTxt.isNotEmpty) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: ListView(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      children: [
                                        ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.edit_note, size: 20, color: Color(0xFF64748B)),
                                          title: Text(
                                            'Use Custom: "$searchTxt"',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                          ),
                                          subtitle: const Text('Not in store (patient sees "Not in store")', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                          onTap: () => selectCustomMedicine(med, searchTxt),
                                        ),
                                        const Divider(height: 1),

                                        if (results.isEmpty && !isSearching)
                                          const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text('No store products matching this name.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                          ),

                                        ...results.map((prod) {
                                          return ListTile(
                                            dense: true,
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                prod.image,
                                                width: 34,
                                                height: 34,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Image.asset('assets/p1.png', width: 34, height: 34, fit: BoxFit.cover),
                                              ),
                                            ),
                                            title: Text(prod.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            subtitle: Text('${prod.brand} • ₹${prod.price}', style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                                            trailing: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('Link', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                            ),
                                            onTap: () => selectProduct(med, prod),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                              ],

                              // Medicine Name
                              TextField(
                                controller: med['name'] as TextEditingController,
                                decoration: InputDecoration(
                                  labelText: 'Medicine Name *',
                                  hintText: 'e.g. Ashwagandha Churna',
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: hasLinkedProduct
                                      ? const Tooltip(
                                          message: 'Linked to store product',
                                          child: Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                                        )
                                      : const Tooltip(
                                          message: 'Custom medicine',
                                          child: Icon(Icons.info_outline, color: Color(0xFF64748B), size: 18),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Row 1: Strength + Dosage Form
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: med['strength'] as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'Strength',
                                        hintText: '500mg, 10ml',
                                        isDense: true,
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: med['dosageForm'] as String,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                                      decoration: InputDecoration(
                                        labelText: 'Dosage Form',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: ['Tablet', 'Capsule', 'Syrup', 'Churna', 'Vati', 'Oil', 'Powder', 'Drops', 'Ointment', 'Injection'].map((f) {
                                        return DropdownMenuItem(
                                          value: f,
                                          child: Text(f, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setStateModal(() => med['dosageForm'] = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Row 2: Dosage + Frequency
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: med['dosage'] as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'Dosage',
                                        hintText: '1 tab, 5ml',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: med['frequency'] as String,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                                      decoration: InputDecoration(
                                        labelText: 'Frequency',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: ['Once daily', 'Twice daily', 'Thrice daily', 'Four times daily', 'As needed'].map((f) {
                                        return DropdownMenuItem(
                                          value: f,
                                          child: Text(f, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setStateModal(() => med['frequency'] = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Row 3: Timing + Duration
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: med['timing'] as String,
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                                      decoration: InputDecoration(
                                        labelText: 'Timing',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: ['After meals', 'Before meals', 'After breakfast', 'At bedtime', 'Morning & Evening'].map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setStateModal(() => med['timing'] = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: med['duration'] as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: 'Duration',
                                        hintText: '7 days, 1 month',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Row 4: Quantity + Refillable
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: med['quantity'] as TextEditingController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Quantity (units)',
                                        hintText: '30',
                                        isDense: true,
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setStateModal(() => med['refillable'] = !(med['refillable'] == true)),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              med['refillable'] == true ? Icons.check_box : Icons.check_box_outline_blank,
                                              size: 18,
                                              color: med['refillable'] == true ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            const Flexible(
                                              child: Text(
                                                'Refillable',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Instructions
                              TextField(
                                controller: med['instructions'] as TextEditingController,
                                decoration: InputDecoration(
                                  labelText: 'Patient Instructions',
                                  hintText: 'e.g. Take with warm water or milk after food',
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // ── SECTION 3: ADVICE & FOLLOW-UP ─────────────────
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF0F766E)),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '3. Advice & Follow-Up',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Lab Tests
                      TextField(
                        controller: rxLabCtrl,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Lab Tests / Investigations',
                          hintText: 'e.g., Blood sugar fasting, Lipid profile, CBC',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Dietary Instructions
                      TextField(
                        controller: rxDietCtrl,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Dietary Instructions',
                          hintText: 'e.g., Low salt & low oil diet, drink 3L water daily',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // General Advice
                      TextField(
                        controller: rxGeneralCtrl,
                        maxLines: 1,
                        decoration: InputDecoration(
                          labelText: 'General Advice & Lifestyle Instructions',
                          hintText: 'e.g., Daily 30 min brisk walk, avoid late night eating',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Follow-up Date + Refills Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rxFollowUpCtrl,
                              readOnly: false,
                              decoration: InputDecoration(
                                labelText: 'Follow-Up Date',
                                hintText: 'YYYY-MM-DD',
                                filled: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF0F766E)),
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: now.add(const Duration(days: 7)),
                                      firstDate: now,
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      rxFollowUpCtrl.text =
                                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: refillsAllowed,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              decoration: InputDecoration(
                                labelText: 'Refills Allowed',
                                filled: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: [0, 1, 2, 3, 5].map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text('$r Refill${r == 1 ? "" : "s"}', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 1),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setStateModal(() => refillsAllowed = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              for (final m in medications) {
                                (m['debounceTimer'] as Timer?)?.cancel();
                              }
                              Navigator.pop(ctx);
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (rxDiagnosisCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a diagnosis.')),
                                  );
                                  return;
                                }

                                if (!isEditing && (appointmentId == null || userId == null)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Missing appointment ID or User ID.')),
                                  );
                                  return;
                                }

                                setStateModal(() => isLoading = true);

                                List<Map<String, dynamic>> medsPayload = medications.map((m) {
                                  final nameCtrl = m['name'] as TextEditingController;
                                  final strCtrl = m['strength'] as TextEditingController;
                                  final dosCtrl = m['dosage'] as TextEditingController;
                                  final durCtrl = m['duration'] as TextEditingController;
                                  final instCtrl = m['instructions'] as TextEditingController;
                                  final qtyCtrl = m['quantity'] as TextEditingController;
                                  final String? prodId = m['productId'];
                                  final Product? selProd = m['selectedProduct'];

                                  final payload = {
                                    "name": nameCtrl.text.isEmpty ? "Medication" : nameCtrl.text.trim(),
                                    "strength": strCtrl.text.trim(),
                                    "dosageForm": m['dosageForm'],
                                    "dosage": dosCtrl.text.trim(),
                                    "frequency": m['frequency'],
                                    "duration": durCtrl.text.trim(),
                                    "timing": m['timing'],
                                    "instructions": instCtrl.text.trim(),
                                    "quantity": int.tryParse(qtyCtrl.text.trim()) ?? 30,
                                    "refillable": m['refillable'] ?? true,
                                  };
                                  if (prodId != null && prodId.isNotEmpty) {
                                    payload["productId"] = prodId;
                                  }
                                  if (selProd != null) {
                                    payload["productPrice"] = selProd.price;
                                    payload["productImage"] = selProd.image;
                                    payload["productBrand"] = selProd.brand;
                                  }
                                  return payload;
                                }).toList();

                                final doctorToken = AppState().doctorToken;

                                if (effectiveAptId.isNotEmpty && !PrescriptionWindowHelper.isWindowOpen(appointmentId: effectiveAptId)) {
                                  setStateModal(() => isLoading = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing
                                          ? 'Prescription editing window expired (5 minutes after consultation end).'
                                          : 'Prescription issuance window expired (5 minutes after consultation end).'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final res = isEditing && effectiveRxId.isNotEmpty
                                    ? await EPrescriptionService.updatePrescription(
                                        prescriptionId: effectiveRxId,
                                        diagnosis: rxDiagnosisCtrl.text.trim(),
                                        clinicalFindings: rxFindingsCtrl.text.trim(),
                                        medications: medsPayload,
                                        dietaryInstructions: rxDietCtrl.text.trim(),
                                        generalInstructions: rxGeneralCtrl.text.trim(),
                                        labTests: rxLabCtrl.text.trim(),
                                        followUpDate: rxFollowUpCtrl.text.trim(),
                                        validityDays: validityDays,
                                        refillsAllowed: refillsAllowed,
                                        token: doctorToken,
                                      )
                                    : await EPrescriptionService.createPrescription(
                                        appointmentId: appointmentId!,
                                        userId: userId!,
                                        diagnosis: rxDiagnosisCtrl.text.trim(),
                                        clinicalFindings: rxFindingsCtrl.text.trim(),
                                        medications: medsPayload,
                                        labTests: rxLabCtrl.text.trim(),
                                        dietaryInstructions: rxDietCtrl.text.trim(),
                                        generalInstructions: rxGeneralCtrl.text.trim(),
                                        followUpDate: rxFollowUpCtrl.text.trim(),
                                        validityDays: validityDays,
                                        refillsAllowed: refillsAllowed,
                                        token: doctorToken,
                                      );

                                setStateModal(() => isLoading = false);

                                if (!ctx.mounted) return;
                                if (res['success'] == true) {
                                  final Map<String, dynamic> rxObj = (res['data'] is Map && res['data']['prescription'] is Map)
                                      ? res['data']['prescription'] as Map<String, dynamic>
                                      : (res['data'] is Map ? res['data'] as Map<String, dynamic> : {});

                                  final Map<String, dynamic> finalRx = rxObj.isNotEmpty ? rxObj : (res['prescription'] is Map ? res['prescription'] as Map<String, dynamic> : {});

                                  onPrescriptionSaved?.call(finalRx);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing
                                          ? 'E-Prescription updated successfully!'
                                          : 'E-Prescription ${finalRx['prescriptionNumber'] ?? ""} issued successfully!'),
                                      backgroundColor: const Color(0xFF16A34A),
                                    ),
                                  );
                                  for (final m in medications) {
                                    (m['debounceTimer'] as Timer?)?.cancel();
                                  }
                                  Navigator.pop(ctx);
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${res['message']}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        label: Text(
                          isLoading
                              ? (isEditing ? 'Updating...' : 'Signing & Issuing...')
                              : (isEditing ? 'Update Prescription' : 'Issue E-Prescription'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
