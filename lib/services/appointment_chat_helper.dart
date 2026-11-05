import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import 'chat_service.dart';
import 'prescription_window_helper.dart';

/// Helper to handle chat access rules between doctor and patient:
/// 1. 10 minutes before scheduled meeting time:
///    - ONLY Doctor can initiate chat.
///    - Patient can only chat if Doctor has already sent at least 1 message.
/// 2. Once meeting time arrives (currentTime >= meetingTime):
///    - Patient can also initiate chat.
/// 3. After consultation completes (or ends/cancels):
///    - Chat option is completely removed / disabled from both Doctor & Patient sides.
class AppointmentChatHelper {
  static const int preMeetingDoctorWindowSeconds = 10 * 60; // 10 minutes

  // In-memory set of appointment IDs where the doctor has sent at least one message
  static final Set<String> _doctorSentAppointmentIds = <String>{};

  /// Checks if consultation is completed, ended, or cancelled
  static bool isConsultationCompleted(String? status) {
    if (status == null || status.trim().isEmpty) return false;
    final s = status.toLowerCase().trim().replaceAll(' ', '_').replaceAll('-', '_');
    if (s.contains('complet') ||
        s.contains('ended') ||
        s.contains('finish') ||
        s.contains('close') ||
        s.contains('cancel') ||
        s.contains('reject') ||
        s.contains('expire')) {
      return true;
    }
    return PrescriptionWindowHelper.isConsultationCompleted(status);
  }

  /// Parses scheduled meeting start datetime in IST (UTC+5:30)
  static DateTime parseMeetingStartDateTime({
    required String appointmentDate,
    String? appointmentTime,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));

    int year = nowIst.year;
    int month = nowIst.month;
    int day = nowIst.day;

    DateTime? parsedDate;
    final cleanDate = appointmentDate.trim();

    if (cleanDate.isNotEmpty) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('-');
        year = int.tryParse(parts[0]) ?? year;
        month = int.tryParse(parts[1]) ?? month;
        day = int.tryParse(parts[2]) ?? day;
      } else if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(cleanDate)) {
        final parts = cleanDate.contains('-') ? cleanDate.split('-') : cleanDate.split('/');
        day = int.tryParse(parts[0]) ?? day;
        month = int.tryParse(parts[1]) ?? month;
        year = int.tryParse(parts[2]) ?? year;
      } else {
        parsedDate = DateTime.tryParse(cleanDate);
        if (parsedDate != null) {
          final ist = parsedDate.isUtc ? parsedDate.add(const Duration(hours: 5, minutes: 30)) : parsedDate;
          year = ist.year;
          month = ist.month;
          day = ist.day;
        }
      }
    }

    int hour = 0;
    int minute = 0;

    final cleanTime = (appointmentTime ?? '').trim().toLowerCase();
    if (cleanTime.isNotEmpty) {
      final isPm = cleanTime.contains('pm');
      final isAm = cleanTime.contains('am');
      final timeOnly = cleanTime.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = timeOnly.split(':');
      if (parts.isNotEmpty) {
        hour = int.tryParse(parts[0]) ?? 0;
        minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        if (isPm && hour < 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        }
      }
    } else if (parsedDate != null && cleanDate.contains('T')) {
      final ist = parsedDate.isUtc ? parsedDate.add(const Duration(hours: 5, minutes: 30)) : parsedDate;
      hour = ist.hour;
      minute = ist.minute;
    }

    return DateTime(year, month, day, hour, minute);
  }

  /// Calculates remaining seconds until meeting scheduled start time in IST.
  /// - Positive (> 0): meeting is in the future.
  /// - 0 or Negative (<= 0): meeting scheduled time has arrived or past.
  static int getSecondsUntilMeeting({
    required String appointmentDate,
    String? appointmentTime,
  }) {
    final startIst = parseMeetingStartDateTime(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
    );
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return startIst.difference(nowIst).inSeconds;
  }

  /// Records that doctor has sent a message for this appointment
  static void recordDoctorSentMessage(String appointmentId) {
    if (appointmentId.trim().isEmpty) return;
    _doctorSentAppointmentIds.add(appointmentId.trim());
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('chat_doc_sent_${appointmentId.trim()}', true);
    }).catchError((_) {});
  }

  /// Fast synchronous check if doctor is known to have sent a message
  static bool isDoctorSentMessageCached(String appointmentId) {
    if (appointmentId.trim().isEmpty) return false;
    return _doctorSentAppointmentIds.contains(appointmentId.trim());
  }

  /// Inspects a message list (e.g. from fetchMessages or websockets) and records if doctor sent any
  static void registerMessages({
    required String appointmentId,
    required List<ChatMessageModel> messages,
  }) {
    if (appointmentId.trim().isEmpty) return;
    final hasDoc = messages.any((m) {
      final s = m.senderType.toLowerCase().trim();
      return s == 'doctor' || s.contains('doc');
    });
    if (hasDoc) {
      recordDoctorSentMessage(appointmentId);
    }
  }

  /// Asynchronously checks if doctor has sent a message, querying cache, SharedPreferences,
  /// or backend ChatService if token is provided.
  static Future<bool> checkDoctorSentMessage({
    required String appointmentId,
    String? token,
  }) async {
    final id = appointmentId.trim();
    if (id.isEmpty) return false;

    if (_doctorSentAppointmentIds.contains(id)) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('chat_doc_sent_$id') == true) {
        _doctorSentAppointmentIds.add(id);
        return true;
      }
    } catch (_) {}

    if (token != null && token.isNotEmpty) {
      try {
        final res = await ChatService.getMessages(appointmentId: id, token: token);
        if (res.success && res.messages.isNotEmpty) {
          registerMessages(appointmentId: id, messages: res.messages);
          if (_doctorSentAppointmentIds.contains(id)) return true;
        }
      } catch (e) {
        debugPrint('[AppointmentChatHelper] checkDoctorSentMessage error: $e');
      }
    }

    return false;
  }

  /// Determines if Doctor has access to chat for this appointment.
  /// - False if consultation completed or ended/cancelled.
  /// - False if more than 10 minutes before scheduled meeting.
  /// - True if within 10 minutes before meeting (10-minute doctor initiate window) or meeting started.
  static bool canDoctorAccessChat({
    required String? status,
    required String appointmentDate,
    String? appointmentTime,
  }) {
    if (isConsultationCompleted(status)) {
      return false; // Chat option removed from both sides
    }

    final s = (status ?? '').toLowerCase();
    if (s.contains('progress') || s.contains('active')) {
      return true;
    }

    final secondsUntil = getSecondsUntilMeeting(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
    );

    // Chat opens for doctor 10 minutes (600 seconds) before meeting
    return secondsUntil <= preMeetingDoctorWindowSeconds;
  }

  /// Determines if Patient has access to chat for this appointment.
  /// - False if consultation completed or ended/cancelled.
  /// - False if more than 10 minutes before meeting.
  /// - If within 10 minutes before meeting: ONLY TRUE if doctor has sent a message!
  /// - If meeting time has arrived (secondsUntil <= 0) or in-progress: TRUE.
  static bool canPatientAccessChat({
    required String? status,
    required String appointmentDate,
    String? appointmentTime,
    required String appointmentId,
    bool? hasDoctorSentMessage,
  }) {
    if (isConsultationCompleted(status)) {
      return false; // Chat option removed from both sides
    }

    final s = (status ?? '').toLowerCase();
    if (s.contains('progress') || s.contains('active')) {
      return true;
    }

    final secondsUntil = getSecondsUntilMeeting(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
    );

    // More than 10 minutes before meeting: chat not active
    if (secondsUntil > preMeetingDoctorWindowSeconds) {
      return false;
    }

    // Meeting time arrived or passed: patient can initiate chat freely
    if (secondsUntil <= 0) {
      return true;
    }

    // Within 10 minutes before meeting: patient can ONLY chat if doctor initiated
    final doctorInitiated = hasDoctorSentMessage ?? isDoctorSentMessageCached(appointmentId);
    return doctorInitiated;
  }

  /// Human-readable description/reason for chat button state
  static String getPatientChatDisabledReason({
    required String? status,
    required String appointmentDate,
    String? appointmentTime,
    required String appointmentId,
  }) {
    if (isConsultationCompleted(status)) {
      return 'Consultation completed. Chat is closed.';
    }

    final secondsUntil = getSecondsUntilMeeting(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
    );

    if (secondsUntil > preMeetingDoctorWindowSeconds) {
      final mins = (secondsUntil / 60).ceil();
      return 'Chat opens 10m before scheduled meeting (in $mins mins)';
    }

    if (secondsUntil > 0) {
      return 'Doctor has not initiated chat yet. Chat will activate once doctor sends a message or when meeting starts.';
    }

    return 'Chat is active';
  }
}
