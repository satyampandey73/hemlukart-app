import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper service to manage the 5-minute prescription issue/edit window after a consultation/meeting ends.
class PrescriptionWindowHelper {
  /// Allowed duration to edit or upload a prescription after consultation ends
  static const int windowMinutes = 5;
  static const int windowSeconds = windowMinutes * 60;

  // In-memory cache for fast synchronous UI checks
  static final Map<String, DateTime> _completedCache = {};
  static bool _isInitialized = false;

  /// Preload cached completion timestamps from SharedPreferences
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('consultation_completed_'));
      for (final k in keys) {
        final aptId = k.replaceFirst('consultation_completed_', '');
        final val = prefs.getString(k);
        if (val != null) {
          final dt = DateTime.tryParse(val);
          if (dt != null) {
            _completedCache[aptId] = dt;
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PrescriptionWindowHelper] init error: $e');
    }
  }

  /// Records that a consultation / meeting has been completed
  static Future<void> recordConsultationCompleted(String appointmentId, {DateTime? completedTime}) async {
    final cleanId = appointmentId.trim();
    if (cleanId.isEmpty) return;

    final time = completedTime ?? DateTime.now();
    _completedCache[cleanId] = time;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('consultation_completed_$cleanId', time.toIso8601String());
    } catch (e) {
      debugPrint('[PrescriptionWindowHelper] recordCompleted error: $e');
    }
  }

  /// Resolves the completion DateTime for an appointment
  static DateTime? getCompletionDateTime({
    required String appointmentId,
    String? completedAt,
    String? updatedAt,
    String? status,
  }) {
    final cleanId = appointmentId.trim();

    // 1. Check in-memory / local storage cache first
    if (cleanId.isNotEmpty && _completedCache.containsKey(cleanId)) {
      return _completedCache[cleanId];
    }

    // 2. Check explicit completedAt string from backend
    if (completedAt != null && completedAt.trim().isNotEmpty) {
      final dt = DateTime.tryParse(completedAt.trim());
      if (dt != null) {
        if (cleanId.isNotEmpty) _completedCache[cleanId] = dt;
        return dt;
      }
    }

    // 3. If status is completed, check updatedAt from backend
    final sLower = (status ?? '').toLowerCase().trim();
    if (sLower.contains('complet') && updatedAt != null && updatedAt.trim().isNotEmpty) {
      final dt = DateTime.tryParse(updatedAt.trim());
      if (dt != null) {
        if (cleanId.isNotEmpty) _completedCache[cleanId] = dt;
        return dt;
      }
    }

    return null;
  }

  /// Checks if status indicates consultation completion
  static bool isConsultationCompleted(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    return s.contains('complet');
  }

  /// Returns true if the consultation is still open OR completed within the 5-minute window
  static bool isWindowOpen({
    required String appointmentId,
    String? completedAt,
    String? updatedAt,
    String? status,
  }) {
    // If consultation is NOT completed (scheduled, confirmed, in-progress), doctor can prescribe
    if (!isConsultationCompleted(status)) {
      return true;
    }

    final completionTime = getCompletionDateTime(
      appointmentId: appointmentId,
      completedAt: completedAt,
      updatedAt: updatedAt,
      status: status,
    );

    // If status is completed but no completion timestamp is available,
    // default to expired for security unless recorded locally.
    if (completionTime == null) {
      return false;
    }

    final diffSeconds = DateTime.now().toUtc().difference(completionTime.toUtc()).inSeconds;
    return diffSeconds < windowSeconds;
  }

  /// Returns remaining seconds in the 5-minute window after consultation end.
  /// Returns null if consultation is not completed.
  /// Returns 0 if window has expired.
  static int? getRemainingSeconds({
    required String appointmentId,
    String? completedAt,
    String? updatedAt,
    String? status,
  }) {
    if (!isConsultationCompleted(status)) {
      return null;
    }

    final completionTime = getCompletionDateTime(
      appointmentId: appointmentId,
      completedAt: completedAt,
      updatedAt: updatedAt,
      status: status,
    );

    if (completionTime == null) return 0;

    final diffSeconds = DateTime.now().toUtc().difference(completionTime.toUtc()).inSeconds;
    final remaining = windowSeconds - diffSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Formatted countdown representation (e.g. "4m 35s" or "Expired")
  static String formatRemainingTime(int seconds) {
    if (seconds <= 0) return 'Expired';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
