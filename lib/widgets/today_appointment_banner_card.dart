import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/my_appointments_model.dart';
import '../screens/appointment_detail_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/video_call_screen.dart';
import '../services/video_call_service.dart';

class TodayAppointmentBannerCard extends StatefulWidget {
  final UserAppointmentItem appointment;
  final bool isDoctor;
  final VoidCallback? onRefresh;

  const TodayAppointmentBannerCard({
    super.key,
    required this.appointment,
    required this.isDoctor,
    this.onRefresh,
  });

  /// Check whether a date string corresponds to today in IST
  static bool isToday(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;
    try {
      final clean = dateStr.trim();
      final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

      // 1. Plain YYYY-MM-DD
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(clean)) {
        final todayStr =
            '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${nowIst.day.toString().padLeft(2, '0')}';
        return clean == todayStr;
      }

      // 2. DD-MM-YYYY or DD/MM/YYYY
      if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(clean)) {
        final parts = clean.contains('-') ? clean.split('-') : clean.split('/');
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        return nowIst.year == year && nowIst.month == month && nowIst.day == day;
      }

      // 3. ISO timestamp or other parsed string
      final dt = DateTime.parse(clean);
      final dtIst = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
      return dtIst.year == nowIst.year && dtIst.month == nowIst.month && dtIst.day == nowIst.day;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether an appointment has expired, ended, or is in the past today.
  /// Meeting ends after its scheduled duration (default 30 mins).
  /// Excludes completed, cancelled, rejected, ended, or expired statuses.
  static bool isExpiredOrPast(
    UserAppointmentItem apt, {
    int? customCurrentMinutes,
  }) {
    final s = normalizeStatus(apt.status);
    if (s.contains('complet') ||
        s.contains('cancel') ||
        s.contains('reject') ||
        s.contains('ended') ||
        s.contains('expire')) {
      return true;
    }

    final startMinutes = getAppointmentMinutes(apt);
    if (startMinutes == 999999) {
      return false;
    }

    final duration = apt.durationMinutes > 0 ? apt.durationMinutes : 30;
    final endMinutes = startMinutes + duration;
    final curMinutes = customCurrentMinutes ?? currentIstMinutes;

    // For in-progress appointments, grant a 15-minute grace period past scheduled end
    if (isInProgress(apt)) {
      return curMinutes >= (endMinutes + 15);
    }

    // Once the meeting window (startMinutes + duration) has passed, it has expired/ended!
    return curMinutes >= endMinutes;
  }

  /// Returns exactly ONE active upcoming/in-progress appointment for today.
  /// Excludes past, expired, completed, and cancelled appointments.
  /// Prioritizes in-progress appointments first, then earliest scheduled time.
  /// When an appointment completes or expires, the next scheduled today's appointment displays.
  static UserAppointmentItem? getNextActiveTodayAppointment(
    List<UserAppointmentItem> appointments, {
    int? customCurrentMinutes,
  }) {
    if (appointments.isEmpty) return null;

    final todayApts = appointments.where((apt) {
      if (!isToday(apt.appointmentDate)) return false;
      // Exclude past, expired, ended, completed, or cancelled appointments
      if (isExpiredOrPast(apt, customCurrentMinutes: customCurrentMinutes)) {
        return false;
      }
      return true;
    }).toList();

    if (todayApts.isEmpty) return null;

    todayApts.sort((a, b) {
      final aInProgress = isInProgress(a);
      final bInProgress = isInProgress(b);

      if (aInProgress && !bInProgress) return -1;
      if (!aInProgress && bInProgress) return 1;

      final aMinutes = getAppointmentMinutes(a);
      final bMinutes = getAppointmentMinutes(b);
      return aMinutes.compareTo(bMinutes);
    });

    return todayApts.first;
  }

  /// Parses a time string (e.g. "10:00 AM", "02:30 PM", "14:00") into minutes from midnight
  static int parseTimeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return 999999;
    try {
      final clean = timeStr.trim().toLowerCase();
      final isPm = clean.contains('pm');
      final isAm = clean.contains('am');

      final timeOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = timeOnly.split(':');
      if (parts.isEmpty) return 999999;

      int hours = int.tryParse(parts[0]) ?? 0;
      final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPm && hours < 12) {
        hours += 12;
      } else if (isAm && hours == 12) {
        hours = 0;
      }

      return hours * 60 + minutes;
    } catch (_) {
      return 999999;
    }
  }

  /// Extracts the scheduled time in minutes from midnight (IST)
  static int getAppointmentMinutes(UserAppointmentItem apt) {
    if (apt.appointmentTime != null && apt.appointmentTime!.trim().isNotEmpty) {
      final m = parseTimeToMinutes(apt.appointmentTime);
      if (m != 999999) return m;
    }
    if (apt.appointmentDate.contains('T')) {
      try {
        final dt = DateTime.parse(apt.appointmentDate);
        final ist = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
        return ist.hour * 60 + ist.minute;
      } catch (_) {}
    }
    return 999999;
  }

  /// Current IST time in minutes from midnight
  static int get currentIstMinutes {
    final nowUtc = DateTime.now().toUtc();
    final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));
    return nowIst.hour * 60 + nowIst.minute;
  }

  /// Formatted time when video call activates (10 minutes before scheduled time)
  static String getCallEnableTimeString(UserAppointmentItem apt) {
    final aptMinutes = getAppointmentMinutes(apt);
    if (aptMinutes == 999999) return '10m before';
    int enableMinutes = aptMinutes - 10;
    if (enableMinutes < 0) enableMinutes = 0;
    final h = enableMinutes ~/ 60;
    final m = enableMinutes % 60;
    final isPm = h >= 12;
    final displayH = (h % 12 == 0) ? 12 : (h % 12);
    final period = isPm ? 'PM' : 'AM';
    return '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  /// Normalizes status string for consistent comparisons
  static String normalizeStatus(String status) {
    return status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
  }

  /// Whether an appointment is confirmed/approved/scheduled
  static bool isConfirmed(UserAppointmentItem apt) {
    final s = normalizeStatus(apt.status);
    return s == 'confirmed' || s == 'approved' || s == 'scheduled';
  }

  /// Whether an appointment is currently active / in-progress
  static bool isInProgress(UserAppointmentItem apt) {
    final s = normalizeStatus(apt.status);
    return s.contains('progress') ||
        s.contains('process') ||
        s == 'active' ||
        s == 'ongoing';
  }

  /// Whether an appointment is pending confirmation
  static bool isPending(UserAppointmentItem apt) {
    return normalizeStatus(apt.status).contains('pending');
  }

  /// Whether current time is within 10 minutes of appointment or later today
  static bool isWithin10MinutesOfAppointment(
    UserAppointmentItem apt, {
    int? customCurrentMinutes,
  }) {
    if (isInProgress(apt)) return true;
    final aptMinutes = getAppointmentMinutes(apt);
    if (aptMinutes == 999999) return false;
    final curMinutes = customCurrentMinutes ?? currentIstMinutes;
    final windowStart = aptMinutes - 10;
    return curMinutes >= windowStart;
  }

  /// Chat option enables once appointment is confirmed or in-progress
  static bool canChat(UserAppointmentItem apt) {
    final s = normalizeStatus(apt.status);
    if (s.contains('cancel') ||
        s.contains('complet') ||
        s.contains('reject') ||
        s.contains('ended') ||
        s.contains('expire')) {
      return false;
    }
    return isConfirmed(apt) || isInProgress(apt);
  }

  /// Video call meeting button enables 10 minutes before scheduled time (or if in-progress)
  static bool canJoinVideoCall(
    UserAppointmentItem apt, {
    int? customCurrentMinutes,
  }) {
    final isVideo = apt.consultationType.toLowerCase().contains('video');
    if (!isVideo) return false;
    if (isInProgress(apt)) return true;
    if (!isConfirmed(apt)) return false;
    if (isExpiredOrPast(apt, customCurrentMinutes: customCurrentMinutes)) {
      return false;
    }
    return isWithin10MinutesOfAppointment(apt, customCurrentMinutes: customCurrentMinutes);
  }

  @override
  State<TodayAppointmentBannerCard> createState() =>
      _TodayAppointmentBannerCardState();
}

class _TodayAppointmentBannerCardState extends State<TodayAppointmentBannerCard> {
  Timer? _ticker;
  Timer? _callCheckTimer;
  bool _hasActiveCall = false;
  String? _activeVideoCallId;
  bool _hasShownInitiatePopup = false;
  bool _isCheckingCall = false;

  @override
  void initState() {
    super.initState();
    _startTicker();
    if (!widget.isDoctor && _isVideo) {
      _checkActiveCall();
      _startCallCheckPolling();
    }
  }

  @override
  void didUpdateWidget(covariant TodayAppointmentBannerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appointment.id != widget.appointment.id) {
      _hasActiveCall = false;
      _activeVideoCallId = null;
      _hasShownInitiatePopup = false;
      if (!widget.isDoctor && _isVideo) {
        _checkActiveCall();
      }
    }
  }

  void _startTicker() {
    // Check every 15 seconds: if the meeting expires/ends, notify parent to remove card,
    // otherwise update UI if the 10-minute call activation window was reached.
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (TodayAppointmentBannerCard.isExpiredOrPast(widget.appointment)) {
        widget.onRefresh?.call();
      } else {
        setState(() {});
      }
    });
  }

  void _startCallCheckPolling() {
    _callCheckTimer?.cancel();
    // Poll every 5 seconds for patient to detect when doctor initiates the meeting
    _callCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (TodayAppointmentBannerCard.isExpiredOrPast(widget.appointment)) {
        _callCheckTimer?.cancel();
        return;
      }
      _checkActiveCall();
    });
  }

  Future<void> _checkActiveCall() async {
    if (widget.isDoctor || !_isVideo) return;
    if (_isCheckingCall) return;

    final appState = AppState();
    final token = appState.authToken ?? '';
    if (token.isEmpty) return;

    _isCheckingCall = true;
    try {
      final res = await VideoCallService.getActiveVideoCall(
        appointmentId: widget.appointment.id,
        token: token,
      );

      if (!mounted) return;

      final bool hasCall = res.success &&
          res.videoCall != null &&
          res.videoCall!.status.toLowerCase() != 'ended';

      final bool prevHasCall = _hasActiveCall;
      _hasActiveCall = hasCall;
      if (hasCall) {
        _activeVideoCallId = res.videoCall!.id;
      }

      // If doctor just started the call, show the 2-second popup to patient
      if (!prevHasCall && hasCall && !_hasShownInitiatePopup) {
        _hasShownInitiatePopup = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDoctorInitiatedPopup();
        });
      }

      setState(() {});
    } catch (_) {
    } finally {
      _isCheckingCall = false;
    }
  }

  void _showDoctorInitiatedPopup() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        Timer? autoCloseTimer;
        // Exactly 2-second popup as requested
        autoCloseTimer = Timer(const Duration(seconds: 2), () {
          if (dialogCtx.mounted && Navigator.canPop(dialogCtx)) {
            Navigator.pop(dialogCtx);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF10B981),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Doctor Started Meeting!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.appointment.doctorName != null &&
                          widget.appointment.doctorName!.isNotEmpty
                      ? 'Dr. ${widget.appointment.doctorName} has initiated the consultation. You can now join.'
                      : 'Doctor has initiated the consultation. You can now join the meeting.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      autoCloseTimer?.cancel();
                      Navigator.pop(dialogCtx);
                      _handleStartOrJoinCall(context);
                    },
                    icon: const Icon(
                      Icons.videocam_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Join Meeting Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _callCheckTimer?.cancel();
    super.dispose();
  }

  bool get _isVideo {
    return widget.appointment.consultationType.toLowerCase().contains('video');
  }

  Future<void> _openDetails(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(
          appointmentId: widget.appointment.id,
          isForDoctor: widget.isDoctor,
        ),
      ),
    );
    widget.onRefresh?.call();
    if (!widget.isDoctor && _isVideo) {
      _checkActiveCall();
    }
  }

  void _openChat(BuildContext context) {
    if (!TodayAppointmentBannerCard.canChat(widget.appointment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat will be available once the appointment is confirmed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final recipientName = widget.isDoctor
        ? (widget.appointment.patientName.isNotEmpty
            ? widget.appointment.patientName
            : 'Patient')
        : (widget.appointment.doctorName != null &&
                widget.appointment.doctorName!.isNotEmpty
            ? 'Dr. ${widget.appointment.doctorName}'
            : 'Doctor Consultation');

    final recipientSubtitle = widget.isDoctor
        ? (widget.appointment.patientAge != null
            ? '${widget.appointment.patientAge} yrs • Patient'
            : 'Patient')
        : (widget.appointment.doctorSpecialty ?? 'Specialist');

    final recipientAvatar = widget.isDoctor
        ? null
        : widget.appointment.doctorPhoto?.profilePhoto;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          appointmentId: widget.appointment.id,
          recipientName: recipientName,
          recipientSubtitle: recipientSubtitle,
          recipientAvatar: recipientAvatar,
        ),
      ),
    ).then((_) => widget.onRefresh?.call());
  }

  void _showVideoCallNotReadyNotice(BuildContext context) {
    if (!TodayAppointmentBannerCard.isConfirmed(widget.appointment) &&
        !TodayAppointmentBannerCard.isInProgress(widget.appointment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video call will be enabled once appointment is confirmed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final enableTime =
        TodayAppointmentBannerCard.getCallEnableTimeString(widget.appointment);
    final timeLabel = widget.appointment.appointmentTime != null &&
            widget.appointment.appointmentTime!.trim().isNotEmpty
        ? widget.appointment.appointmentTime!.trim()
        : 'scheduled time';

    if (widget.isDoctor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doctor can start video call at $enableTime (10 mins before $timeLabel)'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final within10Mins =
          TodayAppointmentBannerCard.isWithin10MinutesOfAppointment(widget.appointment);
      if (within10Mins) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor has not started the meeting yet. The "Start Meeting" button will enable automatically as soon as doctor initiates the call.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Doctor can start the video call at $enableTime (10 mins before $timeLabel). You will be notified when it begins.'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleStartOrJoinCall(BuildContext context) async {
    final appState = AppState();
    final token =
        (widget.isDoctor ? appState.doctorToken : appState.authToken) ?? '';

    if (widget.isDoctor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initializing consultation video room...'),
          duration: Duration(seconds: 2),
        ),
      );
      final res = await VideoCallService.startVideoCall(
        appointmentId: widget.appointment.id,
        token: token,
      );
      final callId = res.videoCall?.id;
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              appointmentId: widget.appointment.id,
              videoCallId: callId,
              isDoctor: true,
              peerName: widget.appointment.patientName.isNotEmpty
                  ? widget.appointment.patientName
                  : 'Patient',
              patientUserId: widget.appointment.userId,
            ),
          ),
        );
        widget.onRefresh?.call();
      }
    } else {
      String? callId = _activeVideoCallId;
      try {
        final res = await VideoCallService.getActiveVideoCall(
          appointmentId: widget.appointment.id,
          token: token,
        );
        if (res.success && res.videoCall != null) {
          callId = res.videoCall!.id;
          if (callId.isNotEmpty && res.videoCall!.status.toLowerCase() != 'ended') {
            await VideoCallService.joinVideoCall(videoCallId: callId, token: token);
          }
        }
      } catch (_) {}

      if (callId == null || callId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor has not started the meeting yet. Please wait for doctor to initiate.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              appointmentId: widget.appointment.id,
              videoCallId: callId,
              isDoctor: false,
              peerName: widget.appointment.doctorName != null &&
                      widget.appointment.doctorName!.isNotEmpty
                  ? 'Dr. ${widget.appointment.doctorName}'
                  : 'Doctor Consultation',
              peerSubtitle: widget.appointment.doctorSpecialty ?? 'Ayush Specialist',
              peerAvatar: widget.appointment.displayDoctorPhoto,
            ),
          ),
        );
        widget.onRefresh?.call();
        _checkActiveCall();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = TodayAppointmentBannerCard.isInProgress(widget.appointment);
    final confirmed = TodayAppointmentBannerCard.isConfirmed(widget.appointment);
    final pending = TodayAppointmentBannerCard.isPending(widget.appointment);
    final isVideoCall = _isVideo;
    final within10Mins =
        TodayAppointmentBannerCard.isWithin10MinutesOfAppointment(widget.appointment);
    final enableTime =
        TodayAppointmentBannerCard.getCallEnableTimeString(widget.appointment);

    // Doctor can start call 10 minutes before scheduled time (or if inProgress)
    // Patient can ONLY start/join once doctor has initiated the active video call
    final callActive = widget.isDoctor
        ? TodayAppointmentBannerCard.canJoinVideoCall(widget.appointment)
        : _hasActiveCall;

    final chatActive = TodayAppointmentBannerCard.canChat(widget.appointment);

    // Video call button visibility
    final bool showVideoCallButton = isVideoCall &&
        (widget.isDoctor ? (inProgress || (confirmed && within10Mins)) : true);

    final displayName = widget.isDoctor
        ? (widget.appointment.patientName.isNotEmpty
            ? widget.appointment.patientName
            : 'Patient Consultation')
        : (widget.appointment.doctorName != null &&
                widget.appointment.doctorName!.isNotEmpty
            ? 'Dr. ${widget.appointment.doctorName}'
            : 'Doctor Consultation');

    final displaySubtitle = widget.isDoctor
        ? (widget.appointment.patientAge != null
            ? '${isVideoCall ? "Video Consultation" : "In-Person Consultation"} • ${widget.appointment.patientAge} yrs'
            : (isVideoCall ? "Video Consultation" : "In-Person Consultation"))
        : (widget.appointment.doctorSpecialty != null &&
                widget.appointment.doctorSpecialty!.isNotEmpty
            ? '${widget.appointment.doctorSpecialty} • ${isVideoCall ? "Video Consultation" : "Clinic Visit"}'
            : (isVideoCall ? "Video Consultation" : "Clinic Visit"));

    final timeLabel = widget.appointment.appointmentTime != null &&
            widget.appointment.appointmentTime!.trim().isNotEmpty
        ? widget.appointment.appointmentTime!.trim()
        : 'Today';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: inProgress
                  ? [
                      const Color(0xFF0F4C47),
                      const Color(0xFF0D5E56),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inProgress
                  ? const Color(0xFF2DD4BF)
                  : AppColors.primary.withValues(alpha: 0.35),
              width: inProgress ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: inProgress
                    ? const Color(0xFF0F4C47).withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Badges Row ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? const Color(0xFF10B981)
                          : (pending
                              ? Colors.orange.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: inProgress
                                ? Colors.white
                                : (pending ? Colors.orange : AppColors.primary),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          inProgress
                              ? 'LIVE CONSULTATION'
                              : (pending
                                  ? 'PENDING CONFIRMATION'
                                  : (confirmed
                                      ? 'CONFIRMED APPOINTMENT'
                                      : "TODAY'S APPOINTMENT")),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: inProgress
                                ? Colors.white
                                : (pending
                                    ? Colors.orange.shade800
                                    : AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scheduled Time Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: inProgress
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: inProgress
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: inProgress
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 11),

              // ── Person & Details Row ───────────────────────────────────
              Row(
                children: [
                  // Avatar Circle
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: inProgress
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: inProgress
                            ? const Color(0xFF2DD4BF)
                            : AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: widget.isDoctor
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: inProgress ? Colors.white : AppColors.primary,
                              ),
                            )
                          : (widget.appointment.doctorPhoto?.profilePhoto != null &&
                                  widget.appointment
                                      .doctorPhoto!.profilePhoto!.isNotEmpty
                              ? Image.network(
                                  widget.appointment.doctorPhoto!.profilePhoto!,
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/d1.jpg',
                                    width: 46,
                                    height: 46,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/d1.jpg',
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                )),
                    ),
                  ),

                  const SizedBox(width: 11),

                  // Name & Consultation Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: inProgress
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displaySubtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: inProgress
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Informative Notice Banner ───────────────────────────────
              if (isVideoCall) ...[
                if (_hasActiveCall && !widget.isDoctor) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF86EFAC),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Doctor has started the meeting! Tap "Start Meeting" to join.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!inProgress && !callActive) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: pending
                          ? Colors.orange.withValues(alpha: 0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: pending
                            ? Colors.orange.withValues(alpha: 0.3)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pending
                              ? Icons.info_outline_rounded
                              : (within10Mins
                                  ? Icons.hourglass_top_rounded
                                  : Icons.access_time_rounded),
                          size: 13,
                          color: pending
                              ? Colors.orange.shade800
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            pending
                                ? 'Awaiting confirmation. Call & chat activate once confirmed.'
                                : (widget.isDoctor
                                    ? (within10Mins
                                        ? 'Video call ready to start now'
                                        : 'Video call can be started at $enableTime (10m before)')
                                    : (within10Mins
                                        ? 'Waiting for doctor to start meeting. Button will enable automatically.'
                                        : 'Doctor can start meeting at $enableTime (10m before)')),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: pending
                                  ? Colors.orange.shade900
                                  : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 11),

              // ── Action Buttons Row ─────────────────────────────────────
              Row(
                children: [
                  // 1. Video Call Button (Start / Join)
                  if (showVideoCallButton) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: callActive
                            ? () => _handleStartOrJoinCall(context)
                            : () => _showVideoCallNotReadyNotice(context),
                        icon: Icon(
                          callActive
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_outlined,
                          size: 15,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            callActive
                                ? (widget.isDoctor
                                    ? 'Start Video Call'
                                    : 'Start Meeting')
                                : (!confirmed
                                    ? 'Call (Pending)'
                                    : (widget.isDoctor
                                        ? 'Call (10m before)'
                                        : (within10Mins
                                            ? 'Waiting for Doctor'
                                            : 'Call (10m before)'))),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: callActive
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: callActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                          foregroundColor: callActive
                              ? Colors.white
                              : const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          elevation: callActive ? 0 : 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // 2. Chat Button
                  if (chatActive || !showVideoCallButton) ...[
                    Expanded(
                      flex: showVideoCallButton ? 2 : 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _openChat(context),
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: chatActive
                              ? (showVideoCallButton
                                  ? (inProgress ? Colors.white : AppColors.primary)
                                  : Colors.white)
                              : const Color(0xFF94A3B8),
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            showVideoCallButton ? 'Chat' : 'Chat Now',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: chatActive
                                  ? (showVideoCallButton
                                      ? (inProgress ? Colors.white : AppColors.primary)
                                      : Colors.white)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: chatActive
                              ? (showVideoCallButton
                                  ? (inProgress
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.08))
                                  : (inProgress
                                      ? const Color(0xFF10B981)
                                      : AppColors.primary))
                              : const Color(0xFFF1F5F9),
                          foregroundColor: chatActive
                              ? (showVideoCallButton
                                  ? (inProgress ? Colors.white : AppColors.primary)
                                  : Colors.white)
                              : const Color(0xFF94A3B8),
                          side: showVideoCallButton && chatActive
                              ? BorderSide(
                                  color: inProgress
                                      ? Colors.white54
                                      : AppColors.primary.withValues(alpha: 0.3),
                                  width: 1,
                                )
                              : BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // 3. View Details Button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => _openDetails(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: inProgress
                              ? Colors.white54
                              : const Color(0xFFCBD5E1),
                        ),
                        foregroundColor:
                            inProgress ? Colors.white : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: inProgress
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 9,
                              color: inProgress
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
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

