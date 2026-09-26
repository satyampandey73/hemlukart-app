import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/my_appointments_model.dart';
import '../services/appointment_service.dart';
import '../services/video_call_service.dart';
import 'chat_screen.dart';
import 'video_call_screen.dart';
import '../services/eprescription_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final AppointmentDetailModel? initialDetail;
  final bool? isForDoctor;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.initialDetail,
    this.isForDoctor,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppState _appState = AppState();

  bool get _isDoctorView {
    if (widget.isForDoctor != null) return widget.isForDoctor!;
    return _appState.isDoctorLoggedIn;
  }
  bool _isLoading = true;
  String? _errorMessage;
  AppointmentDetailModel? _detail;
  bool _isCancelling = false;
  bool _isRescheduling = false;
  bool _isConfirming = false;
  bool _isCompleting = false;
  bool _isStartingVideoCall = false;

  bool get _isActionInProgress =>
      _isConfirming || _isCompleting || _isCancelling || _isRescheduling || _isStartingVideoCall;

  Map<String, dynamic>? _issuedPrescription;

  @override
  void initState() {
    super.initState();
    if (widget.initialDetail != null) {
      _detail = widget.initialDetail;
      _isLoading = false;
    }
    _fetchDetail();
  }

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Personal reason issue';
    final List<String> commonReasons = [
      'Personal reason issue',
      'Change of plans',
      'Feeling better / Not needed',
      'Doctor unavailable',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cancel Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please select or enter a reason for cancelling this appointment:',
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: InputDecoration(
                        labelText: 'Cancellation Reason',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: commonReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                          });
                        }
                      },
                    ),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Type your cancellation reason...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keep Appointment', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final reason = selectedReason == 'Other'
                        ? (reasonController.text.trim().isEmpty ? 'Personal reason issue' : reasonController.text.trim())
                        : selectedReason;

                    Navigator.pop(context);
                    _handleCancelAppointment(reason);
                  },
                  child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancelAppointment(String cancelReason) async {
    if (_detail == null) return;
    setState(() {
      _isCancelling = true;
    });

    try {
      final bool isDoctor = _appState.isDoctorLoggedIn;
      SingleAppointmentApiResponse response;

      if (isDoctor) {
        final token = _appState.doctorToken;
        if (token == null || token.isEmpty) {
          setState(() => _isCancelling = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor session expired. Please log in again.'), backgroundColor: Colors.red),
          );
          return;
        }
        response = await AppointmentService.cancelDoctorAppointment(
          appointmentId: _detail!.id,
          cancelReason: cancelReason,
          token: token,
        );
      } else {
        response = await _appState.cancelAppointment(
          appointmentId: _detail!.id,
          cancelReason: cancelReason,
        );
      }

      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      if (response.success && response.appointment != null) {
        setState(() {
          _detail = response.appointment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to cancel appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCancelling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRescheduleDialog() {
    if (_detail == null) return;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Conflicting schedule';
    final List<String> commonReasons = [
      'Conflicting schedule',
      'Emergency situation',
      'Doctor unavailable',
      'Patient request',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formattedDate =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
            String formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.event_repeat, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text('Reschedule ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a new date and time for this appointment:',
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 14),

                    // Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF2563EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: AppColors.textLight),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Time picker
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF2563EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: Color(0xFF2563EB), size: 18),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: AppColors.textLight),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reason dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      decoration: InputDecoration(
                        labelText: 'Reason for Rescheduling',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: commonReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedReason = val);
                      },
                    ),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Type your reason...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final reason = selectedReason == 'Other'
                        ? (reasonController.text.trim().isEmpty ? 'Conflicting schedule' : reasonController.text.trim())
                        : selectedReason;

                    // Build ISO 8601 datetime string
                    final newDateTimeStr =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                        'T${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00.000Z';

                    Navigator.pop(context);
                    _handleRescheduleAppointment(newDate: newDateTimeStr, reason: reason);
                  },
                  child: const Text('Confirm Reschedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRescheduleAppointment({required String newDate, required String reason}) async {
    if (_detail == null) return;
    final token = _appState.doctorToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor session expired. Please log in again.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isRescheduling = true);

    try {
      final response = await AppointmentService.rescheduleDoctorAppointment(
        appointmentId: _detail!.id,
        newDate: newDate,
        reason: reason,
        token: token,
      );

      if (!mounted) return;
      setState(() => _isRescheduling = false);

      if (response.success && response.appointment != null) {
        setState(() => _detail = response.appointment);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Appointment rescheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to reschedule appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRescheduling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _fetchDetail() async {
    if (_detail == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = _appState.authToken ?? _appState.doctorToken;
      final response = await AppointmentService.getAppointmentById(
        appointmentId: widget.appointmentId,
        token: token,
      );

      if (!mounted) return;

      if (response.success && response.appointment != null) {
        setState(() {
          _detail = response.appointment;
          _isLoading = false;
        });
      } else {
        if (_detail == null) {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load appointment details.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (_detail == null) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(isoStr);
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
      return isoStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null && _detail == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchDetail,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final statusColor = _getStatusColor(detail.status);
    final bool isDoctor = _appState.isDoctorLoggedIn;
    final bool isCancelled = detail.status.toLowerCase() == 'cancelled';

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    detail.status.toLowerCase() == 'confirmed'
                        ? Icons.check_circle
                        : detail.status.toLowerCase() == 'cancelled'
                            ? Icons.cancel
                            : Icons.access_time,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${detail.status.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Payment: ${detail.paymentStatus.toUpperCase()}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Doctor view + Cancelled: show ONLY cancellation reason ──
            if (isDoctor && isCancelled) ...[
              const SizedBox(height: 16),
              if (detail.cancelReason?.isNotEmpty == true)
                _buildCard(
                  title: 'Cancellation Details',
                  icon: Icons.cancel_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason for Cancellation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail.cancelReason!,
                        style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Text(
                    'No cancellation reason provided.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ),
            ] else ...[

            const SizedBox(height: 16),

            // Doctor Info Card
            _buildCard(
              title: 'Doctor Information',
              icon: Icons.medical_services_outlined,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: detail.displayDoctorPhoto.isNotEmpty
                        ? NetworkImage(detail.displayDoctorPhoto) as ImageProvider
                        : const AssetImage('assets/doctor_profile.png'),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.doctorName?.isNotEmpty == true
                              ? 'Dr. ${detail.doctorName}'
                              : 'Specialist Doctor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (detail.doctorSpecialty?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            detail.doctorSpecialty!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (detail.doctorMobile?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Phone: ${detail.doctorMobile}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                          ),
                        ],
                        if (detail.doctorEmail?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Email: ${detail.doctorEmail}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                          ),
                        ],
                        if (detail.clinicName?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Clinic: ${detail.clinicName}',
                            style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Appointment Date & Schedule Card
            _buildCard(
              title: 'Schedule Details',
              icon: Icons.calendar_today_outlined,
              child: Column(
                children: [
                  _buildDetailItem(Icons.event, 'Appointment Date', detail.formattedDateTime),
                  const SizedBox(height: 10),
                  _buildDetailItem(
                    detail.isVideoConsultation ? Icons.videocam : Icons.location_on,
                    'Consultation Mode',
                    detail.isVideoConsultation ? 'Video Consultation' : 'In-Person Visit',
                  ),
                  const SizedBox(height: 10),
                  _buildDetailItem(Icons.timer, 'Duration', '${detail.durationMinutes} Minutes'),
                  const SizedBox(height: 10),
                  _buildDetailItem(Icons.payments_outlined, 'Consultation Fee', '₹${detail.consultationFee}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Patient Info Card
            _buildCard(
              title: 'Patient Details',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _buildDetailItem(Icons.person, 'Patient Name', detail.patientName),
                  // Hide patient mobile from doctor
                  if (!isDoctor && detail.patientMobile?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildDetailItem(Icons.phone, 'Mobile Number', detail.patientMobile!),
                  ],
                  if (detail.patientAge != null) ...[
                    const SizedBox(height: 10),
                    _buildDetailItem(Icons.cake, 'Age', '${detail.patientAge} years'),
                  ],
                  if (detail.symptoms?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildDetailItem(Icons.sick_outlined, 'Symptoms', detail.symptoms!),
                  ],
                  if (detail.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildDetailItem(Icons.note_outlined, 'Notes', detail.notes!),
                  ],
                  // Hide booked-by account & user ID from doctor
                  if (!isDoctor && (detail.userName?.isNotEmpty == true || detail.userMobile?.isNotEmpty == true)) ...[
                    const Divider(height: 20),
                    _buildDetailItem(Icons.account_box_outlined, 'Booked By Account', '${detail.userName ?? "User"} ${detail.userMobile != null ? "(${detail.userMobile})" : ""}'),
                  ],
                  if (!isDoctor && detail.userId?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _buildDetailItem(Icons.fingerprint, 'User ID', detail.userId!),
                  ],
                ],
              ),
            ),

            if (detail.cancelReason?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Cancellation Details',
                icon: Icons.cancel_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason for Cancellation:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.cancelReason!,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],

            if (_issuedPrescription != null) ...[
              const SizedBox(height: 16),
              _buildPrescriptionCard(_issuedPrescription!),
            ],

            const SizedBox(height: 16),

            // Timeline Timestamps Card
            _buildCard(
              title: 'Appointment Timeline',
              icon: Icons.history,
              child: Column(
                children: [
                  _buildTimelineItem('Booked At', _formatTimestamp(detail.bookedAt), isFirst: true),
                  if (detail.confirmedAt != null)
                    _buildTimelineItem('Confirmed At', _formatTimestamp(detail.confirmedAt)),
                  if (detail.completedAt != null)
                    _buildTimelineItem('Completed At', _formatTimestamp(detail.completedAt)),
                  if (detail.cancelledAt != null)
                    _buildTimelineItem('Cancelled At', _formatTimestamp(detail.cancelledAt), isLast: true),
                ],
              ),
            ),

            ], // end of non-cancelled-doctor block

            if (detail.status.toLowerCase() != 'cancelled') ...[
              const SizedBox(height: 20),
              if (detail.isVideoConsultation) ...[
                if (!detail.status.toLowerCase().contains('pending') &&
                    (detail.status.toLowerCase().contains('confirm') ||
                     detail.status.toLowerCase().contains('progress') ||
                     detail.status.toLowerCase() == 'approved' ||
                     detail.status.toLowerCase() == 'active')) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActionInProgress
                          ? null
                          : () async {
                              setState(() => _isStartingVideoCall = true);
                              try {
                                if (_isDoctorView) {
                                  String? token = _appState.doctorToken ?? _appState.activeChatToken;
                                  if (token == null || token.isEmpty) {
                                    final prefs = await SharedPreferences.getInstance();
                                    token = prefs.getString('doctor_token') ?? prefs.getString('auth_token');
                                  }
                                  if (token == null || token.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in as a doctor to start video call')),
                                    );
                                    return;
                                  }
                                  final res = await VideoCallService.startVideoCall(appointmentId: detail.id, token: token);
                                  if (!mounted) return;
                                  if (res.success || res.videoCall != null) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VideoCallScreen(
                                          appointmentId: detail.id,
                                          videoCallId: res.videoCall?.id,
                                          isDoctor: true,
                                          peerName: detail.patientName.isNotEmpty ? detail.patientName : 'Patient',
                                          peerSubtitle: '${detail.patientAge ?? 30} Yrs • ${detail.patientMobile ?? ""}',
                                          peerAvatar: 'assets/d2.jpg',
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      await _fetchDetail();
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res.message ?? 'Unable to start video call')),
                                    );
                                  }
                                } else {
                                  String? token = _appState.authToken ?? _appState.activeChatToken;
                                  if (token == null || token.isEmpty) {
                                    final prefs = await SharedPreferences.getInstance();
                                    token = prefs.getString('auth_token') ?? prefs.getString('doctor_token');
                                  }
                                  if (token == null || token.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please log in to your patient account to join video call')),
                                    );
                                    return;
                                  }
                                  String? callId;
                                  try {
                                    final activeRes = await VideoCallService.getActiveVideoCall(appointmentId: detail.id, token: token);
                                    if (activeRes.videoCall != null) {
                                      callId = activeRes.videoCall?.id;
                                      if (callId != null && activeRes.videoCall!.status.toLowerCase() != 'ended') {
                                        await VideoCallService.joinVideoCall(videoCallId: callId, token: token);
                                      }
                                    }
                                  } catch (_) {}

                                  if (!mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoCallScreen(
                                        appointmentId: detail.id,
                                        videoCallId: callId,
                                        isDoctor: false,
                                        peerName: detail.doctorName != null && detail.doctorName!.isNotEmpty ? 'Dr. ${detail.doctorName}' : 'Doctor Consultation',
                                        peerSubtitle: detail.doctorSpecialty ?? 'Ayush Specialist',
                                        peerAvatar: detail.displayDoctorPhoto,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    await _fetchDetail();
                                  }
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to start video call: $e'), backgroundColor: Colors.red),
                                );
                              } finally {
                                if (mounted) setState(() => _isStartingVideoCall = false);
                              }
                            },
                      icon: _isStartingVideoCall
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.videocam_rounded, color: Colors.white),
                      label: Text(
                        _isStartingVideoCall
                            ? (_isDoctorView ? 'Starting Video Call...' : 'Joining Video Call...')
                            : (_isDoctorView ? 'Start Video Call' : 'Join Video Call'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        disabledBackgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else if (detail.status.toLowerCase().contains('pending')) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: Icon(Icons.videocam_off_outlined, color: Colors.grey.shade400),
                      label: Text(
                        'Join Call (Pending Doctor Confirmation)',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (detail.status.toLowerCase() == 'confirmed' || detail.status.toLowerCase() == 'approved') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isActionInProgress
                        ? null
                        : () {
                            final bool isDoctor = _appState.isDoctorLoggedIn;
                            final String recipientName = isDoctor
                                ? (detail.patientName.isNotEmpty ? detail.patientName : 'Patient')
                                : (detail.doctorName != null && detail.doctorName!.isNotEmpty ? 'Dr. ${detail.doctorName}' : 'Doctor');
                            final String recipientSubtitle = isDoctor
                                ? 'Patient (${detail.patientAge ?? "N/A"} Yrs)'
                                : (detail.doctorSpecialty ?? 'Ayush Specialist');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  appointmentId: detail.id,
                                  recipientName: recipientName,
                                  recipientSubtitle: recipientSubtitle,
                                  recipientAvatar: detail.displayDoctorPhoto,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                    label: const Text('Chat Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_isDoctorView) ...[
                if (detail.status.toLowerCase() == 'confirmed' || detail.status.toLowerCase() == 'approved' || detail.status.toLowerCase() == 'completed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActionInProgress
                          ? null
                          : () => _showPrescriptionDialog(
                                patientName: detail.patientName,
                                appointmentId: detail.id,
                                userId: detail.userId,
                              ),
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                      label: const Text('Write Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5B4C),
                        disabledBackgroundColor: const Color(0xFF0F5B4C).withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (detail.status.toLowerCase() == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActionInProgress
                          ? null
                          : () async {
                              setState(() => _isConfirming = true);
                              try {
                                final res = await _appState.confirmDoctorAppointment(detail.id);
                                if (!mounted) return;
                                if (res.success && res.appointment != null) {
                                  setState(() => _detail = res.appointment);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message ?? 'Appointment confirmed successfully'),
                                    backgroundColor: res.success ? Colors.green : Colors.red,
                                  ),
                                );
                                await _fetchDetail();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to confirm appointment: $e'), backgroundColor: Colors.red),
                                );
                              } finally {
                                if (mounted) setState(() => _isConfirming = false);
                              }
                            },
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _isConfirming ? 'Confirming Appointment...' : 'Confirm Appointment',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else if (detail.status.toLowerCase() == 'confirmed') ...[
                  if (detail.isMeetingTimeExpired && _isDoctorView)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scheduled meeting time has expired. Doctor can mark this consultation as completed.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isActionInProgress
                          ? null
                          : () async {
                              setState(() => _isCompleting = true);
                              try {
                                final res = await _appState.completeDoctorAppointment(detail.id);
                                if (!mounted) return;
                                if (res.success && res.appointment != null) {
                                  setState(() => _detail = res.appointment);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message ?? 'Appointment marked as completed'),
                                    backgroundColor: res.success ? Colors.green : Colors.red,
                                  ),
                                );
                                await _fetchDetail();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to complete appointment: $e'), backgroundColor: Colors.red),
                                );
                              } finally {
                                if (mounted) setState(() => _isCompleting = false);
                              }
                            },
                      icon: _isCompleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.task_alt, color: Colors.white),
                      label: Text(
                        _isCompleting ? 'Marking as Completed...' : 'Mark as Completed',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              // Reschedule button — visible to doctors only for pending/confirmed appointments
              if (_isDoctorView && (detail.status.toLowerCase() == 'pending' || detail.status.toLowerCase() == 'confirmed' || detail.status.toLowerCase() == 'approved')) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isActionInProgress ? null : _showRescheduleDialog,
                    icon: _isRescheduling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.event_repeat, color: Colors.white),
                    label: Text(
                      _isRescheduling ? 'Rescheduling...' : 'Reschedule Appointment',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (detail.status.toLowerCase() == 'pending' || detail.status.toLowerCase() == 'confirmed' || detail.status.toLowerCase() == 'approved') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isActionInProgress ? null : _showCancelDialog,
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: Text(
                      _isCancelling ? 'Cancelling...' : 'Cancel Appointment',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,  
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String label, String timeStr, {bool isFirst = false, bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Text(
            timeStr,
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> rx) {
    final rxNo = rx['prescriptionNumber'] ?? rx['id'] ?? 'RX-PENDING';
    final diagnosis = rx['diagnosis'] ?? 'N/A';
    final clinicalFindings = rx['clinicalFindings'];
    final List medsList = rx['medications'] is List ? rx['medications'] as List : [];
    final labTests = rx['labTests'];
    final dietary = rx['dietaryInstructions'];
    final general = rx['generalInstructions'];
    final followUp = rx['followUpDate'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIGITAL E-PRESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'No: $rxNo',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'ISSUED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.medical_information_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 6),
              const Text('Diagnosis: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Expanded(
                child: Text(
                  diagnosis,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13),
                ),
              ),
            ],
          ),
          if (clinicalFindings != null && clinicalFindings.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Clinical Findings: $clinicalFindings',
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Prescribed Medications',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          ...medsList.map((m) {
            final Map item = m is Map ? m : {};
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['name'] ?? "Medicine"} ${item['strength'] ?? ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['dosageForm'] ?? 'Tablet',
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Dosage: ${item['dosage'] ?? "1 tab"} • Frequency: ${item['frequency'] ?? "Daily"}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  if (item['timing'] != null || item['instructions'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Timing: ${item['timing'] ?? ""} ${item['instructions'] != null ? "(${item['instructions']})" : ""}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (labTests != null && labTests.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Lab Tests & Investigations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text(labTests.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
          if (dietary != null && dietary.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Dietary Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text(dietary.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
          if (general != null && general.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('General Advice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            Text(general.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
          if (followUp != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_repeat, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Follow-Up Date: ${followUp.toString().split('T').first}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPrescriptionDialog({String? patientName, String? appointmentId, String? userId}) {
    final rxDiagnosisCtrl = TextEditingController(text: 'Hypertension Stage 2');
    final rxFindingsCtrl = TextEditingController(text: 'BP: 160/100 mmHg, No other complications');
    final rxLabCtrl = TextEditingController(text: 'Blood pressure monitoring daily\nLipid Profile after 1 month');
    final rxDietCtrl = TextEditingController(text: 'Low salt diet\nAvoid processed foods');
    final rxGeneralCtrl = TextEditingController(text: 'Monitor BP twice daily\nExercise 30 minutes daily');
    final rxFollowUpCtrl = TextEditingController(text: '2026-08-25');

    int validityDays = 30;
    int refillsAllowed = 2;

    List<Map<String, dynamic>> medications = [
      {
        "name": TextEditingController(text: "Amlodipine"),
        "strength": TextEditingController(text: "5mg"),
        "dosageForm": "Tablet",
        "dosage": TextEditingController(text: "1 tablet"),
        "frequency": "Once daily",
        "duration": TextEditingController(text: "30 days"),
        "timing": "After breakfast",
        "instructions": TextEditingController(text: "Take with water, avoid grapefruit"),
        "quantity": TextEditingController(text: "30"),
        "refillable": true,
      },
      {
        "name": TextEditingController(text: "Losartan"),
        "strength": TextEditingController(text: "50mg"),
        "dosageForm": "Tablet",
        "dosage": TextEditingController(text: "1 tablet"),
        "frequency": "Once daily",
        "duration": TextEditingController(text: "30 days"),
        "timing": "Evening",
        "instructions": TextEditingController(text: "Take with water"),
        "quantity": TextEditingController(text: "30"),
        "refillable": true,
      },
    ];

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Create Digital E-Prescription',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (patientName != null && patientName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Patient: $patientName',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Diagnosis
                        TextField(
                          controller: rxDiagnosisCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Diagnosis *',
                            hintText: 'e.g., Hypertension Stage 2',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Clinical Findings
                        TextField(
                          controller: rxFindingsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Clinical Findings',
                            hintText: 'e.g., BP: 160/100 mmHg',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Medications Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prescribed Medications',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setStateModal(() {
                                  medications.add({
                                    "name": TextEditingController(),
                                    "strength": TextEditingController(text: "500mg"),
                                    "dosageForm": "Tablet",
                                    "dosage": TextEditingController(text: "1 tablet"),
                                    "frequency": "Twice daily",
                                    "duration": TextEditingController(text: "7 days"),
                                    "timing": "After meals",
                                    "instructions": TextEditingController(),
                                    "quantity": TextEditingController(text: "14"),
                                    "refillable": false,
                                  });
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Medicine'),
                            ),
                          ],
                        ),

                        ...medications.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> med = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Medication #${index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                    ),
                                    if (medications.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        onPressed: () {
                                          setStateModal(() {
                                            medications.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: med['name'] as TextEditingController,
                                  decoration: const InputDecoration(labelText: 'Medicine Name *', isDense: true, border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: med['strength'] as TextEditingController,
                                  decoration: const InputDecoration(labelText: 'Strength (e.g. 5mg, 500mg)', isDense: true, border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: med['dosageForm'] as String,
                                  decoration: const InputDecoration(labelText: 'Dosage Form', isDense: true, border: OutlineInputBorder()),
                                  items: ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment', 'Drops'].map((f) {
                                    return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setStateModal(() => med['dosageForm'] = val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: med['frequency'] as String,
                                  decoration: const InputDecoration(labelText: 'Frequency', isDense: true, border: OutlineInputBorder()),
                                  items: ['Once daily', 'Twice daily', 'Thrice daily', 'Four times daily', 'As needed'].map((f) {
                                    return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setStateModal(() => med['frequency'] = val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: med['timing'] as String,
                                  decoration: const InputDecoration(labelText: 'Timing', isDense: true, border: OutlineInputBorder()),
                                  items: ['After breakfast', 'Before meals', 'After meals', 'Evening', 'At bedtime'].map((t) {
                                    return DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setStateModal(() => med['timing'] = val);
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: med['duration'] as TextEditingController,
                                  decoration: const InputDecoration(labelText: 'Duration (e.g. 30 days)', isDense: true, border: OutlineInputBorder()),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: med['instructions'] as TextEditingController,
                                  decoration: const InputDecoration(labelText: 'Instructions', hintText: 'e.g. Take with water, avoid grapefruit', isDense: true, border: OutlineInputBorder()),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),
                        // Lab Tests
                        TextField(
                          controller: rxLabCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Lab Tests / Investigations',
                            hintText: 'Blood pressure monitoring daily',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dietary & General Advice
                        TextField(
                          controller: rxDietCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dietary Instructions',
                            hintText: 'Low salt diet, avoid processed foods',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: rxGeneralCtrl,
                          decoration: const InputDecoration(
                            labelText: 'General Advice / Instructions',
                            hintText: 'Monitor BP twice daily, exercise 30 mins',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Follow-up Date & Refills
                        TextField(
                          controller: rxFollowUpCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Follow-Up Date',
                            hintText: 'YYYY-MM-DD',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: refillsAllowed,
                          decoration: const InputDecoration(labelText: 'Refills Allowed', border: OutlineInputBorder()),
                          items: [0, 1, 2, 3, 5].map((r) {
                            return DropdownMenuItem(value: r, child: Text('$r Refills'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setStateModal(() => refillsAllowed = val);
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
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

                            if (appointmentId == null || userId == null) {
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

                              return {
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
                            }).toList();

                            final res = await EPrescriptionService.createPrescription(
                              appointmentId: appointmentId,
                              userId: userId,
                              diagnosis: rxDiagnosisCtrl.text.trim(),
                              clinicalFindings: rxFindingsCtrl.text.trim(),
                              medications: medsPayload,
                              labTests: rxLabCtrl.text.trim(),
                              dietaryInstructions: rxDietCtrl.text.trim(),
                              generalInstructions: rxGeneralCtrl.text.trim(),
                              followUpDate: rxFollowUpCtrl.text.trim(),
                              validityDays: validityDays,
                              refillsAllowed: refillsAllowed,
                              token: _appState.doctorToken,
                            );

                            setStateModal(() => isLoading = false);

                            if (!mounted) return;
                            if (res['success']) {
                              final Map<String, dynamic> rxObj = (res['data'] is Map && res['data']['prescription'] is Map)
                                  ? res['data']['prescription'] as Map<String, dynamic>
                                  : (res['data'] is Map ? res['data'] as Map<String, dynamic> : {});

                              setState(() {
                                _issuedPrescription = rxObj;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('E-Prescription ${rxObj['prescriptionNumber'] ?? ""} created successfully!'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              Navigator.pop(ctx);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${res['message']}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    icon: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      isLoading ? 'Syncing to Server...' : 'Issue E-Prescription',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
