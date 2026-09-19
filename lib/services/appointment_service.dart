import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_slot_model.dart';
import '../models/book_appointment_model.dart';
import '../models/my_appointments_model.dart';

class AppointmentService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/appointments';

  /// API 1: GET https://backend.chikitsakart.com/api/appointments/slots/{doctorId}?date={YYYY-MM-DD}
  /// Fetches available and booked time slots for a given doctor and date.
  static Future<AppointmentSlotsApiResponse> getAppointmentSlots({
    required String doctorId,
    required String date,
    String? token,
  }) async {
    if (doctorId.trim().isEmpty) {
      return AppointmentSlotsApiResponse(
        success: false,
        date: date,
        slots: [],
        message: 'Doctor ID is required',
      );
    }

    final String trimmedId = doctorId.trim();
    final Uri url = Uri.parse('$baseUrl/slots/$trimmedId?date=$date');

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return AppointmentSlotsApiResponse.fromJson(body);
      } else {
        return AppointmentSlotsApiResponse(
          success: false,
          date: date,
          slots: [],
          message: 'Failed with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AppointmentSlotsApiResponse(
        success: false,
        date: date,
        slots: [],
        message: 'Error fetching appointment slots: $e',
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

    String formattedDate = appointmentDate.trim();
    String formattedTime = (appointmentTime ?? '').trim();

    if (formattedDate.contains('T')) {
      try {
        final dt = DateTime.parse(formattedDate).toUtc();
        formattedDate =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        if (formattedTime.isEmpty) {
          formattedTime =
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        }
      } catch (_) {}
    }

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
