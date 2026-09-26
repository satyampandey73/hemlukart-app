import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_appointment_model.dart';
import '../models/my_appointments_model.dart';

class AppointmentService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/appointments';

  /// Formats date to 'YYYY-MM-DD' in Indian Standard Time (IST)
  static String formatToIstDate(dynamic input) {
    if (input == null) {
      final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      return '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${nowIst.day.toString().padLeft(2, '0')}';
    }

    if (input is DateTime) {
      if (input.hour == 0 && input.minute == 0) {
        return '${input.year.toString().padLeft(4, '0')}-${input.month.toString().padLeft(2, '0')}-${input.day.toString().padLeft(2, '0')}';
      }
      final ist = input.toUtc().add(const Duration(hours: 5, minutes: 30));
      return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
    }

    final String str = input.toString().trim();
    if (str.isEmpty) {
      final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      return '${nowIst.year.toString().padLeft(4, '0')}-${nowIst.month.toString().padLeft(2, '0')}-${nowIst.day.toString().padLeft(2, '0')}';
    }

    // If already YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
      return str;
    }

    // If ISO with T
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str);
        final ist = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
        return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // If DD/MM/YYYY or DD-MM-YYYY
    if (str.contains('/') || str.contains('-')) {
      final sep = str.contains('/') ? '/' : '-';
      final parts = str.split(sep);
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        } else if (parts[2].length == 4) {
          return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    }

    return str;
  }

  /// Formats time to 'HH:MM' (24-hour IST time)
  static String formatToIstTime(String? input) {
    if (input == null || input.trim().isEmpty) return '09:00';
    final str = input.trim();

    // If ISO with T
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str);
        final ist = dt.isUtc ? dt.add(const Duration(hours: 5, minutes: 30)) : dt;
        return '${ist.hour.toString().padLeft(2, '0')}:${ist.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final isPm = str.toUpperCase().contains('PM');
    final isAm = str.toUpperCase().contains('AM');

    // Strip non-digits and colon
    final digitsAndColon = str.replaceAll(RegExp(r'[^\d:]'), '');
    final parts = digitsAndColon.split(':');

    if (parts.isNotEmpty) {
      int h = int.tryParse(parts[0]) ?? 9;
      int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      if (isPm && h < 12) {
        h += 12;
      } else if (isAm && h == 12) {
        h = 0;
      }

      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    return '09:00';
  }

  /// API: GET https://backend.chikitsakart.com/api/appointments/doctor/{doctorId}?limit=100
  /// Fetches all active appointments for a doctor so booked slots can be identified accurately.
  static Future<MyAppointmentsApiResponse> getDoctorAppointmentsByDoctorId({
    required String doctorId,
    String? token,
  }) async {
    if (doctorId.trim().isEmpty) {
      return MyAppointmentsApiResponse(
        success: false,
        appointments: [],
        message: 'Doctor ID is required',
      );
    }

    final String trimmedId = doctorId.trim();
    final Uri url = Uri.parse('$baseUrl/doctor/$trimmedId?limit=100');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MyAppointmentsApiResponse.fromJson(body);
      } else {
        return MyAppointmentsApiResponse(
          success: false,
          appointments: [],
          message: body['message'] as String? ??
              'Failed to fetch doctor appointments with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MyAppointmentsApiResponse(
        success: false,
        appointments: [],
        message: 'Error fetching doctor appointments: $e',
      );
    }
  }

  /// API 2: POST https://backend.chikitsakart.com/api/appointments/book
  /// Books an appointment for a patient with a doctor.
  static Future<BookAppointmentApiResponse> bookAppointment({
    required String doctorId,
    required String appointmentDate,
    String? appointmentTime,
    String? clinicId,
    int? durationMinutes,
    String consultationType = 'in_person',
    required String patientName,
    required String patientMobile,
    int? patientAge,
    String? symptoms,
    String? notes,
    dynamic consultationFee,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/book');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final String formattedDate = formatToIstDate(appointmentDate);
    final String formattedTime = formatToIstTime(appointmentTime);

    num? feeNum;
    if (consultationFee != null) {
      feeNum = num.tryParse(consultationFee.toString());
    }

    final Map<String, dynamic> bodyData = {
      'doctorId': doctorId.trim(),
      'appointmentDate': formattedDate,
      if (formattedTime.isNotEmpty) 'appointmentTime': formattedTime,
      if (clinicId?.isNotEmpty == true) 'clinicId': clinicId!.trim(),
      'durationMinutes': durationMinutes ?? 30,
      'consultationType': consultationType,
      'patientName': patientName.trim(),
      'patientAge': ?patientAge,
      'patientMobile': patientMobile.trim(),
      'symptoms': symptoms ?? '',
      'notes': notes ?? '',
      'consultationFee': ?feeNum,
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookAppointmentApiResponse.fromJson(body);
      } else {
        return BookAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Booking failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BookAppointmentApiResponse(
        success: false,
        message: 'Error connecting to booking service: $e',
      );
    }
  }

  /// API 3: GET https://backend.chikitsakart.com/api/appointments/my?page=1&limit=10
  /// Fetches appointments for the authenticated user.
  static Future<MyAppointmentsApiResponse> getMyAppointments({
    int page = 1,
    int limit = 10,
    String? status,
    String? token,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null &&
        status.trim().isNotEmpty &&
        status.toLowerCase() != 'all') {
      queryParams['status'] = status.trim().toLowerCase();
    }

    final Uri url = Uri.parse(
      '$baseUrl/my',
    ).replace(queryParameters: queryParams);

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return MyAppointmentsApiResponse.fromJson(body);
      } else {
        return MyAppointmentsApiResponse(
          success: false,
          appointments: [],
          message:
              body['message'] as String? ??
              'Failed to fetch appointments with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MyAppointmentsApiResponse(
        success: false,
        appointments: [],
        message: 'Error fetching my appointments: $e',
      );
    }
  }

  /// API 4: GET https://backend.chikitsakart.com/api/appointments/{id}
  /// Fetches details of a single appointment by ID.
  static Future<SingleAppointmentApiResponse> getAppointmentById({
    required String appointmentId,
    String? token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse('$baseUrl/${appointmentId.trim()}');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Failed to fetch appointment with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error fetching appointment detail: $e',
      );
    }
  }

  /// API 5: PATCH https://backend.chikitsakart.com/api/appointments/{id}/cancel
  /// Cancels an appointment given its ID and reason for cancellation.
  static Future<SingleAppointmentApiResponse> cancelAppointment({
    required String appointmentId,
    required String cancelReason,
    String? token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse('$baseUrl/${appointmentId.trim()}/cancel');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final Map<String, dynamic> bodyData = {'cancelReason': cancelReason.trim()};

    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Cancellation failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error cancelling appointment: $e',
      );
    }
  }

  /// API 6: GET https://backend.chikitsakart.com/api/appointments/doctor/my
  /// Fetches appointments for the authenticated doctor.
  static Future<MyAppointmentsApiResponse> getDoctorAppointments({
    int page = 1,
    int limit = 100,
    String? status,
    required String token,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null &&
        status.trim().isNotEmpty &&
        status.toLowerCase() != 'all') {
      queryParams['status'] = status.trim().toLowerCase();
    }

    final Uri url = Uri.parse(
      '$baseUrl/doctor/my',
    ).replace(queryParameters: queryParams);

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
        return MyAppointmentsApiResponse.fromJson(body);
      } else {
        return MyAppointmentsApiResponse(
          success: false,
          appointments: [],
          message:
              body['message'] as String? ??
              'Failed to fetch doctor appointments with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MyAppointmentsApiResponse(
        success: false,
        appointments: [],
        message: 'Error fetching doctor appointments: $e',
      );
    }
  }

  /// API 7: PATCH https://backend.chikitsakart.com/api/appointments/doctor/{id}/confirm
  /// Confirms a doctor appointment.
  static Future<SingleAppointmentApiResponse> confirmDoctorAppointment({
    required String appointmentId,
    required String token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/doctor/${appointmentId.trim()}/confirm',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Confirmation failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error confirming appointment: $e',
      );
    }
  }

  /// API: PATCH https://backend.chikitsakart.com/api/appointments/doctor/{id}/cancel
  /// Cancels a doctor appointment with a reason (doctor-auth endpoint).
  static Future<SingleAppointmentApiResponse> cancelDoctorAppointment({
    required String appointmentId,
    required String cancelReason,
    required String token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse('$baseUrl/doctor/${appointmentId.trim()}/cancel');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> bodyData = {'cancelReason': cancelReason.trim()};

    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Doctor cancellation failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error cancelling appointment (doctor): $e',
      );
    }
  }

  /// API: PATCH https://backend.chikitsakart.com/api/appointments/doctor/{id}/reschedule
  /// Reschedules a doctor appointment to a new date with an optional reason.
  static Future<SingleAppointmentApiResponse> rescheduleDoctorAppointment({
    required String appointmentId,
    required String newDate,
    String? reason,
    required String token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/doctor/${appointmentId.trim()}/reschedule',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> bodyData = {
      'newDate': newDate.trim(),
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };

    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Reschedule failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error rescheduling appointment: $e',
      );
    }
  }

  /// API 8: PATCH https://backend.chikitsakart.com/api/appointments/doctor/{id}/complete
  /// Marks a doctor appointment as completed.
  static Future<SingleAppointmentApiResponse> completeDoctorAppointment({
    required String appointmentId,
    required String token,
  }) async {
    if (appointmentId.trim().isEmpty) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Appointment ID is required',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/doctor/${appointmentId.trim()}/complete',
    );

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .patch(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SingleAppointmentApiResponse.fromJson(body);
      } else {
        return SingleAppointmentApiResponse(
          success: false,
          message:
              body['message'] as String? ??
              'Completion failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleAppointmentApiResponse(
        success: false,
        message: 'Error completing appointment: $e',
      );
    }
  }
}
