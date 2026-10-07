import 'dart:async';
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
import '../services/product_service.dart';
import '../services/prescription_product_helper.dart';
import 'eprescription_detail_screen.dart';
import 'cart_screen.dart';

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

  bool _doctorModeFromPrefs = false;

  bool get _isDoctorView {
    if (widget.isForDoctor == true) return true;
    if (_doctorModeFromPrefs) return true;
    if (_appState.isDoctorLoggedIn) return true;
    final docToken = _appState.doctorToken;
    if (docToken != null && docToken.isNotEmpty) return true;
    return false;
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
    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('doctor_token');
      if (token != null && token.isNotEmpty && mounted) {
        setState(() {
          _doctorModeFromPrefs = true;
        });
      }
    });
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
                  Expanded(
                    child: Text('Cancel Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parsedDate = AppointmentService.parseAppointmentDate(_detail!.appointmentDate);
    DateTime selectedDate = parsedDate.isBefore(today) ? today : parsedDate;
    final timeParsed = AppointmentService.parseAppointmentHourMinute(
      timeStr: _detail!.appointmentTime,
      dateStr: _detail!.appointmentDate,
    );
    TimeOfDay selectedTime = TimeOfDay(hour: timeParsed.hour, minute: timeParsed.minute);
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
            final h12 = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
            final period = selectedTime.period == DayPeriod.pm ? 'PM' : 'AM';
            String formattedTime =
                '${h12.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $period';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.event_repeat, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Reschedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
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
                          initialDate: selectedDate.isBefore(today) ? today : selectedDate,
                          firstDate: today,
                          lastDate: today.add(const Duration(days: 365)),
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

                    final newDateTimeStr = AppointmentService.formatIstToUtcIso(
                      date: selectedDate,
                      hour: selectedTime.hour,
                      minute: selectedTime.minute,
                    );

                    final h12 = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
                    final period = selectedTime.period == DayPeriod.pm ? 'PM' : 'AM';
                    final formattedApptTime =
                        '${h12.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} $period';

                    Navigator.pop(context);
                    _handleRescheduleAppointment(
                      newDate: newDateTimeStr,
                      appointmentTime: formattedApptTime,
                      reason: reason,
                    );
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

  Future<void> _handleRescheduleAppointment({
    required String newDate,
    String? appointmentTime,
    required String reason,
  }) async {
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
        appointmentTime: appointmentTime,
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
        if (_issuedPrescription == null) {
          _loadPrescriptionForAppointment();
        }
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

  Future<void> _loadPrescriptionForAppointment() async {
    if (_isDoctorView) return; // Doctor should not see prescription card in appointment details
    try {
      final token = _appState.authToken;
      final res = await EPrescriptionService.getPatientPrescriptions(token: token, limit: 50);
      if (!mounted) return;
      if (res['success'] == true && res['prescriptions'] is List) {
        final list = List<Map<String, dynamic>>.from(res['prescriptions']);
        final match = list.firstWhere(
          (p) => (p['appointmentId'] ?? '').toString() == widget.appointmentId,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          setState(() {
            _issuedPrescription = match;
          });
        }
      }
    } catch (_) {}
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
    if (s.contains('progress') || s.contains('process') || s == 'active' || s == 'ongoing') {
      return const Color(0xFF0D9488); // Teal
    }
    switch (s) {
      case 'confirmed':
      case 'approved':
      case 'scheduled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
      case 'canceled':
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
    final bool isDoctor = _isDoctorView;
    final String statusNorm = detail.status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
    final bool isConfirmed = statusNorm == 'confirmed' || statusNorm == 'approved' || statusNorm == 'scheduled';
    final bool isInProgress = statusNorm.contains('progress') ||
        statusNorm.contains('process') ||
        statusNorm == 'active' ||
        statusNorm == 'ongoing';
    final bool isCompleted = statusNorm.contains('complet');
    final bool isPending = statusNorm.contains('pending');
    final bool isCancelled = statusNorm == 'cancelled' || statusNorm == 'canceled' || statusNorm.contains('cancel');

    // Action permission flags
    final bool canChat = !isCancelled && !isCompleted;
    final bool canComplete = isDoctor && !isCancelled && !isCompleted && !isPending;
    final bool canPrescribe = isDoctor && !isCancelled && !isPending;
    final bool canReschedule = isDoctor && !isCancelled && !isCompleted && !isInProgress;
    final bool canCancel = !isCancelled && !isCompleted;

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
                    isConfirmed
                        ? Icons.check_circle
                        : isCompleted
                            ? Icons.task_alt
                            : isInProgress
                                ? Icons.timelapse_rounded
                                : isCancelled
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
                    onBackgroundImageError: (e, s) {},
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

            if (!_isDoctorView && _issuedPrescription != null) ...[
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
                if (!isPending && !isCancelled && !isCompleted) ...[
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
                                    if (activeRes.videoCall != null && activeRes.videoCall!.status.toLowerCase() != 'ended') {
                                      callId = activeRes.videoCall?.id;
                                      if (callId != null && callId.isNotEmpty) {
                                        await VideoCallService.joinVideoCall(videoCallId: callId, token: token);
                                      }
                                    } else {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Doctor has not started the meeting yet. Please wait for doctor to initiate.'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                  } catch (_) {}

                                  if (callId == null || callId.isEmpty) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Doctor has not started the meeting yet. Please wait for doctor to initiate.'),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    return;
                                  }

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
                ] else if (isPending) ...[
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
              if (canChat) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isActionInProgress
                        ? null
                        : () {
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
              if (canPrescribe) ...[
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
              if (isDoctor && isPending) ...[
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
              ],
              if (canComplete) ...[
                if (detail.isMeetingTimeExpired && isDoctor)
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
                                  content: Text(res.message ?? 'Appointment completed successfully'),
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
                      _isCompleting ? 'Completing Appointment...' : 'Complete Appointment',
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
              // Reschedule button — visible to doctors only for pending/confirmed/in-progress appointments
              if (canReschedule) ...[
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
              if (canCancel) ...[
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

            const SizedBox(height: 36),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timeStr,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
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
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'No: $rxNo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
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
            final String? prodId = PrescriptionProductHelper.extractProductId(item);
            final bool isInStore = prodId != null && prodId.isNotEmpty;
            final bool isItemInCart = isInStore && _appState.cart.any((c) => c.product.id == prodId);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isInStore ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name'] ?? "Medicine"} ${item['strength'] ?? ""}'.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                      Expanded(
                        child: Text(
                          'Dosage: ${item['dosage'] ?? "1 tab"} • Frequency: ${item['frequency'] ?? "Daily"}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
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
                  const SizedBox(height: 8),
                  // Store Availability & Add to Cart button / Not in store badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isInStore) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 11, color: Color(0xFF16A34A)),
                              const SizedBox(width: 3),
                              Text(
                                item['productPrice'] != null ? 'In Store • ₹${item['productPrice']}' : 'In Store',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                        ),
                        if (isItemInCart) ...[
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined, size: 12, color: AppColors.primary),
                            label: const Text('View Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              final prod = await PrescriptionProductHelper.getOrFetchProduct(
                                productId: prodId,
                                fallbackName: item['name']?.toString(),
                                fallbackPrice: double.tryParse(item['productPrice']?.toString() ?? '150'),
                                fallbackImage: item['productImage']?.toString(),
                                fallbackDosageForm: item['dosageForm']?.toString(),
                              );
                              if (prod != null) {
                                await _appState.addToCart(prod, qty: 1);
                                if (!mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${prod.name} added to cart!'),
                                    backgroundColor: const Color(0xFF0F5B4C),
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
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 12, color: Colors.white),
                            label: const Text('Add to Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5B4C),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront_outlined, size: 11, color: Color(0xFF64748B)),
                              SizedBox(width: 4),
                              Text(
                                'Not in store',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Text('Custom medicine', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ],
                  ),
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
                Expanded(
                  child: Text(
                    'Follow-Up Date: ${followUp.toString().split('T').first}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Action buttons: View Full Rx & Order all available medicines
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EPrescriptionDetailScreen(
                          prescriptionData: rx,
                          isDoctorView: _isDoctorView,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.primary),
                  label: const Text('View Full Rx', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (medsList.any((m) => PrescriptionProductHelper.isMedicationInStore(m))) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      int count = 0;
                      for (final m in medsList) {
                        final pid = PrescriptionProductHelper.extractProductId(m);
                        if (pid != null && pid.isNotEmpty) {
                          final prod = await PrescriptionProductHelper.getOrFetchProduct(
                            productId: pid,
                            fallbackName: (m['name'] ?? '').toString(),
                            fallbackPrice: double.tryParse(m['productPrice']?.toString() ?? '150'),
                            fallbackImage: m['productImage']?.toString(),
                          );
                          if (prod != null) {
                            await _appState.addToCart(prod, qty: 1);
                            count++;
                          }
                        }
                      }
                      if (!mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$count medicine(s) added to cart!'),
                          backgroundColor: const Color(0xFF0F5B4C),
                        ),
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.white),
                    label: const Text('Order Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5B4C),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDialog({String? patientName, String? appointmentId, String? userId}) {
    final rxDiagnosisCtrl = TextEditingController(text: 'General Health Consultation');
    final rxFindingsCtrl = TextEditingController(text: 'Routine checkup, symptoms noted');
    final rxLabCtrl = TextEditingController();
    final rxDietCtrl = TextEditingController();
    final rxGeneralCtrl = TextEditingController();
    final rxFollowUpCtrl = TextEditingController();

    int validityDays = 30;
    int refillsAllowed = 2;

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

    List<Map<String, dynamic>> medications = [
      makeMedItem(
        name: "Ashwagandha",
        strength: "500mg",
        dosage: "1 tablet",
        instructions: "Take with warm milk or water",
        quantity: "30",
        refillable: true,
      ),
    ];

    bool isLoading = false;

    showModalBottomSheet(
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Issue E-Prescription',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Digital prescription for patient',
                                        style: TextStyle(
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
                        if (patientName != null && patientName.isNotEmpty) ...[
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
                                        patientName,
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

                                  if (!mounted || !ctx.mounted) return;
                                  if (res['success']) {
                                    final Map<String, dynamic> rxObj = (res['data'] is Map && res['data']['prescription'] is Map)
                                        ? res['data']['prescription'] as Map<String, dynamic>
                                        : (res['data'] is Map ? res['data'] as Map<String, dynamic> : {});

                                    // Only update _issuedPrescription if this is patient view (doctor does not see prescription card here)
                                    if (!_isDoctorView) {
                                      setState(() {
                                        _issuedPrescription = rxObj;
                                      });
                                    }

                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('E-Prescription ${rxObj['prescriptionNumber'] ?? ""} issued successfully!'),
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
                            isLoading ? 'Signing & Issuing...' : 'Issue E-Prescription',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            elevation: 0,
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
}
