import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/my_appointments_model.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> patient;

  /// All appointments for this patient (same name), to build history.
  final List<UserAppointmentItem> appointments;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Details',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 14),
            _buildInfoGrid(),
            const SizedBox(height: 14),
            _buildAppointmentHistory(),
          ],
        ),
      ),
    );
  }

  // ── Profile header card ──────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    Color riskColor = Colors.green;
    if (patient['risk'] == 'High') riskColor = Colors.red;
    if (patient['risk'] == 'Medium') riskColor = Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white24,
            backgroundImage: (patient['avatar'] != null &&
                    (patient['avatar'] as String).isNotEmpty)
                ? AssetImage(patient['avatar'] as String)
                : null,
            child: (patient['avatar'] == null ||
                    (patient['avatar'] as String).isEmpty)
                ? const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['patientName'] ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${patient['age']} • ${patient['gender']}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: riskColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: riskColor),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${patient['risk']} Risk',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: riskColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info grid ────────────────────────────────────────────────────────────────
  Widget _buildInfoGrid() {
    final items = [
      {'icon': Icons.phone_outlined, 'label': 'Phone', 'value': patient['phone'] ?? 'N/A'},
      {'icon': Icons.email_outlined, 'label': 'Email', 'value': patient['email'] ?? 'N/A'},
      {'icon': Icons.bloodtype_outlined, 'label': 'Blood Group', 'value': patient['bloodGroup'] ?? 'N/A'},
      {'icon': Icons.medical_information_outlined, 'label': 'Consultation', 'value': _formatConsultationType(patient['specialty']?.toString())},
      {'icon': Icons.local_hospital_outlined, 'label': 'Diagnosis', 'value': patient['diagnosis'] ?? 'N/A'},
      {'icon': Icons.access_time_outlined, 'label': 'Last Visit', 'value': patient['lastVisit'] ?? 'N/A'},
      {'icon': Icons.confirmation_number_outlined, 'label': 'Appointment ID', 'value': patient['id'] ?? 'N/A'},
      {'icon': Icons.history_outlined, 'label': 'Total Visits', 'value': '${appointments.length}'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final item = items[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['label'].toString(),
                            style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            item['value'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Appointment history ──────────────────────────────────────────────────────
  Widget _buildAppointmentHistory() {
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('No appointment history found.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Appointment History',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${appointments.length} visits',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...appointments.map((apt) => _buildAppointmentTile(apt)),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(UserAppointmentItem apt) {
    final statusColor = _statusColor(apt.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        apt.formattedDateTime,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _capitalize(apt.status),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Details row
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _infoChip(Icons.local_hospital_outlined, _formatConsultationType(apt.consultationType)),
              _infoChip(Icons.timer_outlined, '${apt.durationMinutes} min'),
              _infoChip(Icons.currency_rupee, apt.consultationFee),
              if (apt.paymentStatus.isNotEmpty)
                _infoChip(Icons.payment_outlined, _capitalize(apt.paymentStatus)),
            ],
          ),
          if (apt.symptoms != null && apt.symptoms!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sick_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Symptoms: ${apt.symptoms}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ],
          if (apt.clinicName != null && apt.clinicName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    apt.clinicName!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _formatConsultationType(String? type) {
    if (type == null || type.isEmpty) return 'N/A';
    return type.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in-progress':
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.amber.shade700;
    }
  }
}
