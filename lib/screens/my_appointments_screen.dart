import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/my_appointments_model.dart';
import '../models/chat_model.dart';
import '../services/video_call_service.dart';
import '../services/appointment_service.dart';
import 'login_screen.dart';
import 'appointment_detail_screen.dart';
import 'chat_screen.dart';
import 'video_call_screen.dart';
import '../services/appointment_chat_helper.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AppState _appState = AppState();
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];
  int _currentPage = 1;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _appState.addListener(_onAppStateChanged);

    if (_appState.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAppointments();
      });
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadAppointments() async {
    await _appState.fetchMyAppointments(
      page: _currentPage,
      limit: _limit,
      status: null,
    );
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await _loadAppointments();
  }

  void _showCancelDialog(UserAppointmentItem apt) {
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Cannot make it to the appointment';
    final List<String> commonReasons = [
      'Cannot make it to the appointment',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Cancel Appointment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are you sure you want to cancel appointment with ${apt.doctorName != null && apt.doctorName!.isNotEmpty ? 'Dr. ${apt.doctorName!}' : 'the doctor'}?',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedReason,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Cancellation Reason',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return commonReasons.map<Widget>((String reason) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                reason,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList();
                        },
                        items: commonReasons.map((reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(
                              reason,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cancellations at least 2 hours before the appointment are eligible for 100% refund. Cancellations within 2 hours are non-refundable.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Keep Appointment',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final reason = selectedReason == 'Other'
                        ? (reasonController.text.trim().isEmpty
                              ? 'Cannot make it to the appointment'
                              : reasonController.text.trim())
                        : selectedReason;

                    Navigator.pop(context);
                    _handleCancelAppointment(apt.id, reason);
                  },
                  child: const Text(
                    'Cancel Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCancelAppointment(
    String appointmentId,
    String cancelReason,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Cancelling appointment...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    final response = await _appState.cancelAppointment(
      appointmentId: appointmentId,
      cancelReason: cancelReason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.success) {
      final refundMsg = response.refundMessage;
      final baseMsg = response.message ?? 'Appointment cancelled successfully';
      final displayMsg = (refundMsg != null && refundMsg.isNotEmpty)
          ? '$baseMsg\n$refundMsg'
          : baseMsg;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: response.refundEligible == false ? Colors.orange.shade800 : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to cancel appointment'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showRescheduleDialog(UserAppointmentItem apt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final parsedDate = AppointmentService.parseAppointmentDate(apt.appointmentDate);
    DateTime selectedDate = parsedDate.isBefore(today) ? today : parsedDate;
    final timeParsed = AppointmentService.parseAppointmentHourMinute(
      timeStr: apt.appointmentTime,
      dateStr: apt.appointmentDate,
    );
    TimeOfDay selectedTime = TimeOfDay(hour: timeParsed.hour, minute: timeParsed.minute);
    final TextEditingController reasonController = TextEditingController();
    String selectedReason = 'Personal emergency, need to reschedule';
    final List<String> commonReasons = [
      'Personal emergency, need to reschedule',
      'Conflicting schedule',
      'Doctor unavailable',
      'Health condition changed',
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
                    child: Text('Reschedule Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                                SizedBox(width: 6),
                                Text(
                                  'Reschedule Policy',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '• Maximum 2 reschedules allowed per booking.\n• Free rescheduling is only allowed up to 2 hours before the appointment.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.3),
                            ),
                            if (apt.rescheduleCount != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Reschedules used: ${apt.rescheduleCount}/2',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Text(
                        'Select a new date and time:',
                        style: TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),

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
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Reason for Rescheduling',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return commonReasons.map<Widget>((String reason) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                reason,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList();
                        },
                        items: commonReasons.map((reason) {
                          return DropdownMenuItem<String>(
                            value: reason,
                            child: Text(
                              reason,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                        ? (reasonController.text.trim().isEmpty ? 'Personal emergency, need to reschedule' : reasonController.text.trim())
                        : selectedReason;

                    final dateFormatted =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                    final time24 =
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                    Navigator.pop(context);
                    _handleRescheduleAppointment(
                      apt.id,
                      dateFormatted,
                      time24,
                      reason,
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

  Future<void> _handleRescheduleAppointment(
    String appointmentId,
    String newAppointmentDate,
    String newAppointmentTime,
    String reason,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Rescheduling appointment...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    final response = await _appState.rescheduleAppointment(
      appointmentId: appointmentId,
      newAppointmentDate: newAppointmentDate,
      newAppointmentTime: newAppointmentTime,
      reason: reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.success) {
      final infoMsg = response.rescheduleInfo?.message;
      final baseMsg = response.message ?? 'Appointment rescheduled successfully';
      final displayMsg = (infoMsg != null && infoMsg.isNotEmpty)
          ? '$baseMsg\n$infoMsg'
          : baseMsg;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Failed to reschedule appointment'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _joinPatientVideoCall(UserAppointmentItem apt) async {
    final s = apt.status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    if (s.contains('pending')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Appointment is pending doctor confirmation. You can join once confirmed.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? token = _appState.authToken ?? _appState.activeChatToken;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token') ?? prefs.getString('doctor_token');
    }
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to your patient account to join the video call'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    String? callId;
    try {
      final activeRes = await VideoCallService.getActiveVideoCall(
        appointmentId: apt.id,
        token: token,
      );
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
          appointmentId: apt.id,
          videoCallId: callId,
          isDoctor: false,
          peerName: apt.doctorName != null && apt.doctorName!.isNotEmpty
              ? 'Dr. ${apt.doctorName}'
              : 'Doctor Consultation',
          peerSubtitle: apt.doctorSpecialty ?? 'Ayush Doctor',
          peerAvatar: apt.displayDoctorPhoto,
        ),
      ),
    );
    if (mounted) {
      _refresh();
    }
  }

  void _showPatientChatThreadsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<ChatThreadsApiResponse>(
              future: _appState.fetchChatThreads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final rawThreads = snapshot.data?.threads ?? [];
                final threads = rawThreads.where((t) {
                  final matched = _appState.myAppointments.firstWhere(
                    (a) => a.id == t.appointmentId,
                    orElse: () => UserAppointmentItem(
                      id: '',
                      appointmentDate: '',
                      durationMinutes: 0,
                      consultationType: '',
                      status: '',
                      paymentStatus: '',
                      consultationFee: '',
                      patientName: '',
                    ),
                  );
                  if (matched.id.isNotEmpty &&
                      AppointmentChatHelper.isConsultationCompleted(matched.status)) {
                    return false;
                  }
                  return true;
                }).toList();
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Doctor Consultations',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          if (_appState.unreadChatCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_appState.unreadChatCount} Unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: threads.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No doctor chats found',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: threads.length,
                              separatorBuilder: (_, index) =>
                                  const Divider(height: 1, indent: 64),
                              itemBuilder: (context, index) {
                                final item = threads[index];
                                final bool hasUnread = item.unreadCount > 0;
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE2E8F0),
                                    backgroundImage: AssetImage(
                                      'assets/d1.jpg',
                                    ),
                                  ),
                                  title: Text(
                                    item.doctorName != null &&
                                            item.doctorName!.isNotEmpty
                                        ? 'Dr. ${item.doctorName}'
                                        : 'Doctor Consultation',
                                    style: TextStyle(
                                      fontWeight: hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.lastMessage ?? 'Tap to open chat',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: hasUnread
                                          ? AppColors.textDark
                                          : AppColors.textLight,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: hasUnread
                                      ? Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${item.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: AppColors.textLight,
                                        ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          appointmentId: item.appointmentId,
                                          recipientName:
                                              item.doctorName != null &&
                                                  item.doctorName!.isNotEmpty
                                              ? 'Dr. ${item.doctorName}'
                                              : 'Doctor',
                                          recipientSubtitle:
                                              'Doctor Consultation',
                                          recipientAvatar: 'assets/d1.jpg',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim().replaceAll(' ', '_')) {
      case 'confirmed':
      case 'approved':
      case 'scheduled':
        return Colors.green;
      case 'in_progress':
      case 'inprogress':
      case 'in-progress':
      case 'active':
        return const Color(0xFF0D9488);
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

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withOpacity(0.12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'Refresh Appointments',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: _showPatientChatThreadsSheet,
                tooltip: 'Doctor Messages',
              ),
              if (_appState.unreadChatCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_appState.unreadChatCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          onTap: (index) {
            setState(() {});
          },
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: !_appState.isLoggedIn
          ? _buildLoggedOutView()
          : _appState.isLoadingMyAppointments
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : TabBarView(
                  key: ValueKey(
                    'tabview_${_tabController.index}_${_appState.myAppointments.length}',
                  ),
                  controller: _tabController,
                  children: _tabs.map((tab) {
                    return _buildAppointmentsList(tab);
                  }).toList(),
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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sign in to view your appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep track of your scheduled consultations, doctor visits, and appointment history.',
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
                  );
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

  Widget _buildAppointmentsList(String filterTab) {
    final list = _appState.myAppointments.where((apt) {
      if (filterTab == 'All') return true;
      final s = apt.status
          .toLowerCase()
          .trim()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      if (filterTab == 'Confirmed') {
        // Confirmed tab shows BOTH confirmed and in-progress appointments
        return s.contains('confirm') ||
            s.contains('progress') ||
            s == 'approved' ||
            s == 'scheduled' ||
            s == 'active';
      }
      if (filterTab == 'Pending') {
        return s.contains('pending');
      }
      if (filterTab == 'Completed') {
        return s.contains('complete');
      }
      if (filterTab == 'Cancelled') {
        return s.contains('cancel');
      }
      return s == filterTab.toLowerCase();
    }).toList();

    if (list.isEmpty) {
      return RefreshIndicator(
        key: ValueKey('empty_${filterTab}_${_appState.myAppointments.length}'),
        onRefresh: _refresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 64,
                  color: AppColors.textLight.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  filterTab == 'All'
                      ? 'No appointments found'
                      : 'No $filterTab appointments',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pull down to refresh or check back later.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: ValueKey('list_${filterTab}_${list.length}'),
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final apt = list[index];
          return _buildAppointmentCard(apt);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(UserAppointmentItem apt) {
    final statusColor = _getStatusColor(apt.status);
    final statusBg = _getStatusBgColor(apt.status);
    final statusNorm = apt.status
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    final isPending = statusNorm.contains('pending');
    final canJoinCall = apt.isVideoConsultation &&
        !isPending &&
        (statusNorm.contains('confirm') ||
            statusNorm.contains('progress') ||
            statusNorm == 'approved' ||
            statusNorm == 'active');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(
              appointmentId: apt.id,
              isForDoctor: false,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Consultation Type & Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        apt.consultationType == 'video'
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        apt.consultationType == 'video'
                            ? 'Video Consultation'
                            : 'In-Person Visit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      apt.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Card Info: Doctor & Clinic Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: apt.displayDoctorPhoto.isNotEmpty
                            ? NetworkImage(apt.displayDoctorPhoto)
                                  as ImageProvider
                            : const AssetImage('assets/doctor_profile.png'),
                        onBackgroundImageError: (_, __) {},
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt.doctorName != null &&
                                      apt.doctorName!.isNotEmpty
                                  ? 'Dr. ${apt.doctorName}'
                                  : 'Doctor Consultation',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            if (apt.doctorSpecialty?.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                apt.doctorSpecialty!,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (apt.clinicName?.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Clinic: ${apt.clinicName}',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Appointment Date, Patient Name & Fee info
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          apt.formattedDateTime,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '₹${apt.consultationFee}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  if (apt.formattedBookedAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Booked At: ${apt.formattedBookedAt}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (apt.rescheduleCount != null && apt.rescheduleCount! > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_repeat,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rescheduled: ${apt.rescheduleCount} time(s)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (apt.cancelReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 14,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cancelled: ${apt.cancelReason}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (apt.patientName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Patient: ${apt.patientName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (apt.symptoms?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notes,
                            size: 14,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Symptoms: ${apt.symptoms}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (apt.cancelReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cancel Reason: ${apt.cancelReason}',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],

                  // Show action buttons unless appointment is cancelled
                  if (!statusNorm.contains('cancel')) ...[
                    const Divider(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        // ── Video call join (only for non-cancelled, non-completed) ──
                        if (!statusNorm.contains('cancel') && !statusNorm.contains('complet')) ...[
                          if (apt.isVideoConsultation) ...[
                            if (canJoinCall)
                              ElevatedButton.icon(
                                onPressed: () => _joinPatientVideoCall(apt),
                                icon: const Icon(
                                  Icons.videocam_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Join Call',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              )
                            else if (isPending)
                              ElevatedButton.icon(
                                onPressed: null, // Inactive / disabled for pending status
                                icon: Icon(
                                  Icons.videocam_off_outlined,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                                label: Text(
                                  'Join Call',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor: const Color(0xFFF1F5F9),
                                  disabledForegroundColor: const Color(0xFF94A3B8),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                          ],
                        ],

                        // ── Chat Now — ONLY for active / non-completed consultations ──
                        if (!AppointmentChatHelper.isConsultationCompleted(apt.status))
                          Builder(
                            builder: (context) {
                              final bool canPatientChat = AppointmentChatHelper.canPatientAccessChat(
                                status: apt.status,
                                appointmentDate: apt.appointmentDate,
                                appointmentTime: apt.appointmentTime,
                                appointmentId: apt.id,
                              );

                              if (canPatientChat) {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          appointmentId: apt.id,
                                          recipientName: apt.doctorName != null && apt.doctorName!.isNotEmpty
                                              ? 'Dr. ${apt.doctorName}'
                                              : 'Doctor',
                                          recipientSubtitle: apt.doctorSpecialty ?? 'Ayush Specialist',
                                          recipientAvatar: apt.displayDoctorPhoto,
                                          appointmentDate: apt.appointmentDate,
                                          appointmentTime: apt.appointmentTime,
                                          appointmentStatus: apt.status,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Chat Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              } else {
                                // Before meeting time & doctor hasn't sent message yet
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    final reason = AppointmentChatHelper.getPatientChatDisabledReason(
                                      status: apt.status,
                                      appointmentDate: apt.appointmentDate,
                                      appointmentTime: apt.appointmentTime,
                                      appointmentId: apt.id,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(reason),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  label: Text(
                                    AppointmentChatHelper.getSecondsUntilMeeting(
                                              appointmentDate: apt.appointmentDate,
                                              appointmentTime: apt.appointmentTime,
                                            ) >
                                            600
                                        ? 'Chat (Opens 10m)'
                                        : 'Doctor initiating...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                        // ── Reschedule — for active, pending, confirmed appointments ──
                        if (!statusNorm.contains('cancel') &&
                            !statusNorm.contains('complet') &&
                            !statusNorm.contains('reject') &&
                            !statusNorm.contains('progress'))
                          OutlinedButton.icon(
                            onPressed: () => _showRescheduleDialog(apt),
                            icon: const Icon(
                              Icons.event_repeat,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            label: const Text(
                              'Reschedule',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                        // ── Cancel — only for pending / confirmed / in-progress ──
                        if (!statusNorm.contains('cancel') &&
                            !statusNorm.contains('complet') &&
                            !statusNorm.contains('reject'))
                          OutlinedButton.icon(
                            onPressed: () => _showCancelDialog(apt),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              size: 14,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
