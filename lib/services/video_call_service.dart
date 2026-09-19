import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_call_model.dart';

class VideoCallService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/video-calls';

  /// Doctor Side: POST /api/video-calls/start
  /// Initializes a video call session for an appointment.
  static Future<StartVideoCallResponse> startVideoCall({
    required String appointmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/start');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> bodyData = {
      'appointmentId': appointmentId.trim(),
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return StartVideoCallResponse.fromJson(body);
      } else {
        return StartVideoCallResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Failed to start video call (${response.statusCode})',
        );
      }
    } catch (e) {
      return StartVideoCallResponse(
        success: false,
        message: 'Error starting video call: $e',
      );
    }
  }

  /// Patient Side: GET /api/video-calls/appointment/:id/active
  /// Checks if an active video call exists for an appointment.
  static Future<ActiveVideoCallResponse> getActiveVideoCall({
    required String appointmentId,
    required String token,
  }) async {
    final Uri url = Uri.parse(
      '$baseUrl/appointment/${appointmentId.trim()}/active',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ActiveVideoCallResponse.fromJson(body);
      } else {
        return ActiveVideoCallResponse(
          success: false,
          exists: false,
          message: body['message'] as String? ?? 'No active call found',
        );
      }
    } catch (e) {
      return ActiveVideoCallResponse(
        success: false,
        exists: false,
        message: 'Error checking active video call: $e',
      );
    }
  }

  /// Patient Side: PATCH /api/video-calls/:id/join
  /// Marks the patient as joined in the video call.
  static Future<bool> joinVideoCall({
    required String videoCallId,
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/${videoCallId.trim()}/join');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// When call ends: PATCH /api/video-calls/:id/end
  /// Saves call duration & history.
  static Future<bool> endVideoCall({
    required String videoCallId,
    required String token,
  }) async {
    if (videoCallId.isEmpty) return true;
    final Uri url = Uri.parse('$baseUrl/${videoCallId.trim()}/end');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
