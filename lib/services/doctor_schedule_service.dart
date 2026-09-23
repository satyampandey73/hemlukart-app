import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor_schedule_model.dart';

class DoctorScheduleService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/schedules';

  /// API: GET https://backend.chikitsakart.com/api/schedules/my
  static Future<DoctorSchedulesApiResponse> getMySchedules({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/my');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return DoctorSchedulesApiResponse.fromJson(body);
      } else {
        String msg = 'Failed to fetch schedules (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return DoctorSchedulesApiResponse(
          success: false,
          schedules: [],
          message: msg,
        );
      }
    } catch (e) {
      return DoctorSchedulesApiResponse(
        success: false,
        schedules: [],
        message: 'Network error fetching schedules: $e',
      );
    }
  }

  /// API: POST https://backend.chikitsakart.com/api/schedules
  static Future<DoctorScheduleMutationResponse> createSchedules({
    required String token,
    required List<DoctorScheduleItem> schedules,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final payload = {
        'schedules': schedules.map((s) => s.toJson()).toList(),
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return DoctorScheduleMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to create schedules (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return DoctorScheduleMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return DoctorScheduleMutationResponse(
        success: false,
        message: 'Network error creating schedules: $e',
      );
    }
  }

  /// API: PUT https://backend.chikitsakart.com/api/schedules
  static Future<DoctorScheduleMutationResponse> updateSchedules({
    required String token,
    required List<DoctorScheduleItem> schedules,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final payload = {
        'schedules': schedules.map((s) => s.toJson()).toList(),
      };

      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return DoctorScheduleMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to update schedules (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return DoctorScheduleMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return DoctorScheduleMutationResponse(
        success: false,
        message: 'Network error updating schedules: $e',
      );
    }
  }

  /// Helper that attempts update first (PUT) and if not found/empty falls back to create (POST),
  /// or vice versa, ensuring seamless saving regardless of existing records.
  static Future<DoctorScheduleMutationResponse> saveSchedules({
    required String token,
    required List<DoctorScheduleItem> schedules,
    bool isUpdate = false,
  }) async {
    if (isUpdate) {
      final res = await updateSchedules(token: token, schedules: schedules);
      if (res.success) return res;
      // If PUT failed (e.g. 404 / no existing schedule), try POST
      return await createSchedules(token: token, schedules: schedules);
    } else {
      final res = await createSchedules(token: token, schedules: schedules);
      if (res.success) return res;
      // If POST failed (e.g. already exists / 409), try PUT
      return await updateSchedules(token: token, schedules: schedules);
    }
  }
}
