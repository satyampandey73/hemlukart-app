import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_helper.dart';

class EPrescriptionService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/e-prescriptions';

  static Future<Map<String, dynamic>> createPrescription({
    required String appointmentId,
    required String userId,
    required String diagnosis,
    required List<Map<String, dynamic>> medications,
    String? generalInstructions,
    String? clinicalFindings,
    String? labTests,
    String? dietaryInstructions,
    String? followUpDate,
    int? validityDays,
    int? refillsAllowed,
    String? token,
  }) async {
    final Uri url = Uri.parse(baseUrl);

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final Map<String, dynamic> bodyData = {
      'appointmentId': appointmentId.trim(),
      'userId': userId.trim(),
      'diagnosis': diagnosis.trim(),
      'medications': medications,
      if (generalInstructions != null && generalInstructions.isNotEmpty)
        'generalInstructions': generalInstructions.trim(),
      if (clinicalFindings != null && clinicalFindings.isNotEmpty)
        'clinicalFindings': clinicalFindings.trim(),
      if (labTests != null && labTests.isNotEmpty) 'labTests': labTests.trim(),
      if (dietaryInstructions != null && dietaryInstructions.isNotEmpty)
        'dietaryInstructions': dietaryInstructions.trim(),
      if (followUpDate != null && followUpDate.isNotEmpty)
        'followUpDate': followUpDate.trim(),
      if (validityDays != null) 'validityDays': validityDays,
      if (refillsAllowed != null) 'refillsAllowed': refillsAllowed,
    };

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message':
              body['message'] ?? 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to create prescription',
        ),
      };
    }
  }

  /// GET /e-prescriptions/doctor
  /// Supports server-side filtering via [search], [status], [sortBy], [sortOrder].
  /// - [search]     : patient name, Rx number, diagnosis, or mobile
  /// - [status]     : 'sent' | 'sent_to_pharmacy' | 'dispensed'
  /// - [sortBy]     : field to sort by (e.g. 'issuedAt', 'patientName')
  /// - [sortOrder]  : 'asc' | 'desc'
  static Future<Map<String, dynamic>> getDoctorPrescriptions({
    String? token,
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? sortBy,
    String? sortOrder,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (sortBy != null && sortBy.trim().isNotEmpty) 'sortBy': sortBy.trim(),
      if (sortOrder != null && sortOrder.trim().isNotEmpty)
        'sortOrder': sortOrder.trim(),
    };

    final Uri url = Uri.parse(
      '$baseUrl/doctor',
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
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'prescriptions': body['prescriptions'] ?? [],
          'pagination': body['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to load doctor prescriptions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to load doctor prescriptions',
        ),
      };
    }
  }

  static Future<Map<String, dynamic>> getPrescriptionById({
    required String prescriptionId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$prescriptionId');

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
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'prescription': body['prescription']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to fetch prescription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch prescription',
        ),
      };
    }
  }

  /// PATCH /e-prescriptions/:id/status
  /// Updates [status] ('sent_to_pharmacy' | 'dispensed') and optional [pharmacyNotes].
  static Future<Map<String, dynamic>> updatePrescriptionStatus({
    required String prescriptionId,
    required String status,
    String? pharmacyNotes,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$prescriptionId/status');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final Map<String, dynamic> bodyData = {
      'status': status,
      if (pharmacyNotes != null && pharmacyNotes.isNotEmpty)
        'pharmacyNotes': pharmacyNotes.trim(),
    };
    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic> resp = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': resp['message'] ?? 'Status updated',
          'prescription': resp['prescription'],
        };
      } else {
        return {
          'success': false,
          'message': resp['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update status',
        ),
      };
    }
  }

  /// GET /e-prescriptions/patient
  /// Fetches all prescriptions for the currently authenticated patient.
  /// Supports filtering by [status], [search], [page], [limit].
  static Future<Map<String, dynamic>> getPatientPrescriptions({
    String? token,
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    final Uri url = Uri.parse(
      '$baseUrl/patient',
    ).replace(queryParameters: queryParams);

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'prescriptions': body['prescriptions'] ?? [],
          'pagination': body['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to load prescriptions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to load prescriptions',
        ),
      };
    }
  }

  /// POST /e-prescriptions/:id/cancel
  /// Cancels the prescription with an optional [reason].
  static Future<Map<String, dynamic>> cancelPrescription({
    required String prescriptionId,
    String? reason,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$prescriptionId/cancel');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final Map<String, dynamic> bodyData = {
      if (reason != null && reason.isNotEmpty) 'reason': reason.trim(),
    };
    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(bodyData))
          .timeout(const Duration(seconds: 30));
      final Map<String, dynamic> resp = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': resp['message'] ?? 'Prescription cancelled',
          'prescription': resp['prescription'],
        };
      } else {
        return {
          'success': false,
          'message': resp['message'] ?? 'Failed to cancel prescription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to cancel prescription',
        ),
      };
    }
  }
}
