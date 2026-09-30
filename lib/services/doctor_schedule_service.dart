import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor_schedule_model.dart';
import 'api_helper.dart';

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
          .timeout(const Duration(seconds: 30));

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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch schedules',
        ),
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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return DoctorScheduleMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to create schedules (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
            msg = body['message'].toString();
          } else if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
            msg = body['error'].toString();
          } else if (body['msg'] != null && body['msg'].toString().trim().isNotEmpty) {
            msg = body['msg'].toString();
          }
        } catch (_) {}
        return DoctorScheduleMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return DoctorScheduleMutationResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to create schedules',
        ),
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
          .timeout(const Duration(seconds: 30));

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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update schedules',
        ),
      );
    }
  }

  /// Saves schedules by trying PUT if updating existing schedules, or POST if creating fresh.
  /// Falls back to the alternative method if the first attempt fails.
  static Future<DoctorScheduleMutationResponse> saveSchedules({
    required String token,
    required List<DoctorScheduleItem> schedules,
    bool isUpdate = false,
  }) async {
    if (isUpdate) {
      final putRes = await updateSchedules(token: token, schedules: schedules);
      if (putRes.success) return putRes;

      final postRes = await createSchedules(token: token, schedules: schedules);
      if (postRes.success) return postRes;

      return putRes;
    } else {
      final postRes = await createSchedules(token: token, schedules: schedules);
      if (postRes.success) return postRes;

      final putRes = await updateSchedules(token: token, schedules: schedules);
      if (putRes.success) return putRes;

      return putRes;
    }
  }

  /// API: PUT https://backend.chikitsakart.com/api/schedules/:id
  static Future<DoctorScheduleMutationResponse> updateScheduleById({
    required String token,
    required String scheduleId,
    required DoctorScheduleItem schedule,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$scheduleId');
    try {
      final payload = {
        'startTime': DoctorScheduleItem.formatToIstTime(schedule.startTime),
        'endTime': DoctorScheduleItem.formatToIstTime(schedule.endTime),
        'slotDuration': schedule.slotDuration,
        'consultationType': schedule.consultationType,
        'consultationFee': schedule.consultationFee.toString(),
        'isAvailable': schedule.isAvailable,
      };
      if (schedule.clinicId != null && schedule.clinicId!.trim().isNotEmpty) {
        payload['clinicId'] = schedule.clinicId!.trim();
      }

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
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return DoctorScheduleMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to update schedule (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null && body['message'].toString().trim().isNotEmpty) {
            msg = body['message'].toString();
          } else if (body['error'] != null && body['error'].toString().trim().isNotEmpty) {
            msg = body['error'].toString();
          } else if (body['msg'] != null && body['msg'].toString().trim().isNotEmpty) {
            msg = body['msg'].toString();
          }
        } catch (_) {}
        return DoctorScheduleMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return DoctorScheduleMutationResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update schedule',
        ),
      );
    }
  }

  /// API: DELETE https://backend.chikitsakart.com/api/schedules/:id
  static Future<DoctorScheduleMutationResponse> deleteScheduleById({
    required String token,
    required String scheduleId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$scheduleId');
    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        String msg = 'Schedule deleted successfully';
        try {
          if (response.body.isNotEmpty) {
            final Map<String, dynamic> body = jsonDecode(response.body);
            if (body['message'] != null) msg = body['message'].toString();
          }
        } catch (_) {}
        return DoctorScheduleMutationResponse(
          success: true,
          message: msg,
        );
      } else {
        String msg = 'Failed to delete schedule (Status: ${response.statusCode})';
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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to delete schedule',
        ),
      );
    }
  }
}
