import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/book_appointment_model.dart';
import '../models/my_appointments_model.dart';
import '../services/appointment_service.dart';

class AppointmentConfirmedScreen extends StatefulWidget {
  final String appointmentId;
  final BookedAppointment? bookedAppointment;
  final Doctor? doctor;

  const AppointmentConfirmedScreen({
    super.key,
    required this.appointmentId,
    this.bookedAppointment,
    this.doctor,
  });

  @override
  State<AppointmentConfirmedScreen> createState() =>
      _AppointmentConfirmedScreenState();
}

class _AppointmentConfirmedScreenState
    extends State<AppointmentConfirmedScreen> {
  final AppState _appState = AppState();
  final List<String> _uploadedFiles = [];
  bool _isLoading = true;
  AppointmentDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.appointmentId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await AppointmentService.getAppointmentById(
        appointmentId: widget.appointmentId,
        token: _appState.authToken,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.appointment != null) {
            _detail = response.appointment;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(String? isoDateStr) {
    if (isoDateStr == null || isoDateStr.isEmpty) return 'Scheduled Date';
    try {
      final dt = DateTime.parse(isoDateStr).toUtc();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
      if (hour == 0 && min == '00' && !isoDateStr.contains('T')) {
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} at ${formattedHour.toString().padLeft(2, '0')}:$min $period';
    } catch (_) {
      return isoDateStr;
    }
  }
  String _formatIstTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '';
    try {
      DateTime dt = DateTime.parse(isoTimestamp);
      if (dt.isUtc) {
        dt = dt.add(const Duration(hours: 5, minutes: 30));
      } else {
        dt = dt.toUtc().add(const Duration(hours: 5, minutes: 30));
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour;
      final min = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = (hour % 12 == 0) ? 12 : (hour % 12);
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} at ${formattedHour.toString().padLeft(2, '0')}:$min $period IST';
    } catch (_) {
      return isoTimestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String aptId = _detail?.id ?? widget.bookedAppointment?.id ?? widget.appointmentId;
    final String docName = _detail?.doctorName != null && _detail!.doctorName!.isNotEmpty
        ? 'Dr. ${_detail!.doctorName}'
        : (widget.doctor?.name ?? 'Doctor Consultation');
    final String docSpecialty = _detail?.doctorSpecialty ?? widget.doctor?.specialty ?? 'Ayush Specialist';
    final String photoUrl = _detail?.displayDoctorPhoto ?? widget.doctor?.image ?? '';
    final String rawType = _detail?.consultationType ?? widget.bookedAppointment?.consultationType ?? 'in_person';
    final String modeLabel = (rawType == 'video' || rawType == 'online') ? 'Video Consultation' : 'In-Person Visit';
    final String feeStr = _detail?.consultationFee ?? widget.bookedAppointment?.consultationFee ?? widget.doctor?.consultationFee.toInt().toString() ?? '500';
    final String dateStr = _formatDateTime(_detail?.appointmentDate ?? widget.bookedAppointment?.appointmentDate);
    final String statusStr = (_detail?.status ?? widget.bookedAppointment?.status ?? 'pending').toUpperCase();

    final String rawBookedAt = _detail?.bookedAt ?? widget.bookedAppointment?.bookedAt ?? '';
    final String bookedAtIst = _formatIstTimestamp(rawBookedAt);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Appointment Confirmed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Success Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFD1FAE5),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.secondary,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Appointment Scheduled',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your $modeLabel has been successfully scheduled.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Appointment Details
                        _buildDetailRow('APPOINTMENT ID', aptId, modeLabel: modeLabel),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              backgroundImage: photoUrl.startsWith('http://') || photoUrl.startsWith('https://')
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : (photoUrl.isNotEmpty ? AssetImage(photoUrl) : const AssetImage('assets/doctor_profile.png')),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    docSpecialty,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildIconDetailRow(Icons.calendar_today_outlined, dateStr),
                        if (bookedAtIst.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildIconDetailRow(Icons.access_time_filled, 'Booked At: $bookedAtIst'),
                        ],
                        const SizedBox(height: 10),
                        _buildIconDetailRow(Icons.payments_outlined, 'Consultation Fee: ₹$feeStr'),
                        const SizedBox(height: 10),
                        _buildIconDetailRow(
                          (rawType == 'video' || rawType == 'online')
                              ? Icons.video_camera_back_outlined
                              : Icons.location_on_outlined,
                          (rawType == 'video' || rawType == 'online')
                              ? 'Secure Video Meeting Link'
                              : 'Clinic Address / On-Site Consultation',
                        ),

                        const SizedBox(height: 24),

                        if (rawType == 'video' || rawType == 'online') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Join button will activate 10 minutes prior to session.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.video_call,
                                color: AppColors.textLight,
                              ),
                              label: const Text(
                                'Join Video Session',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.border.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'The join button will be active 10 minutes before the session starts.',
                            style: TextStyle(fontSize: 10, color: AppColors.textLight),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload Medical Documents
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Medical Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Upload your past reports, prescriptions, or files to assist your doctor.',
                          style: TextStyle(color: AppColors.textLight, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedFiles.add(
                                'patient_report_${_uploadedFiles.length + 1}.pdf',
                              );
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Medical record attached successfully!',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Medical Reports & Prescriptions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to select files (Max 10MB each)',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_uploadedFiles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'RECENTLY UPLOADED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _uploadedFiles.map((file) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        file,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _uploadedFiles.remove(file)),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Dynamic Next Steps
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNextStepRow(
                          Icons.check_circle,
                          'Appointment Reserved',
                          'Booking registered in system',
                          isDone: true,
                        ),
                        _buildNextStepRow(
                          Icons.upload_file,
                          'Upload Medical Records',
                          'Helps $docName prepare for your consultation',
                          isDone: false,
                        ),
                        _buildNextStepRow(
                          Icons.description,
                          'Pre-consultation Form',
                          'Describe any symptoms prior to visit',
                          isDone: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Return to Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required String modeLabel}) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textLight,
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                modeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepRow(
    IconData icon,
    String title,
    String desc, {
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDone ? AppColors.secondary : AppColors.textLight,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
