import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor_model.dart';
import 'api_helper.dart';
import 'doctor_auth_service.dart';

class DoctorService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/doctors';

  /// API 1: GET https://backend.chikitsakart.com/api/doctors/all
  /// Query Parameters:
  /// - page: Optional page number (int)
  /// - limit: Optional limit per page (int)
  /// - search: Optional search string
  /// - system: Optional system filter (Ayurveda, Homeopathy, Unani, etc.)
  /// - status: Optional registration status filter (approved, pending, etc.)
  static Future<DoctorsListApiResponse> getAllDoctors({
    int? page,
    int? limit,
    String? search,
    String? system,
    String? status,
  }) async {
    Uri url = Uri.parse('$baseUrl/all');
    final Map<String, String> queryParams = {};

    final effectiveStatus = (status != null && status.trim().isNotEmpty)
        ? status.trim()
        : 'approved';
    queryParams['status'] = effectiveStatus;

    if (limit != null) {
      queryParams['limit'] = limit.toString();
    } else {
      queryParams['limit'] = '1000';
    }
    if (page != null) queryParams['page'] = page.toString();

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (system != null && system.trim().isNotEmpty && system != 'All') {
      queryParams['system'] = system.trim();
    }

    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final apiRes = DoctorsListApiResponse.fromJson(body);

        if (effectiveStatus.toLowerCase() == 'approved') {
          final approvedOnly = apiRes.doctors.where((doc) {
            final regStatus = doc.registrationStatus?.toLowerCase();
            return regStatus == null || regStatus == 'approved';
          }).toList();

          return DoctorsListApiResponse(
            success: apiRes.success,
            doctors: approvedOnly,
            pagination: apiRes.pagination,
            message: apiRes.message,
          );
        }

        return apiRes;
      } else {
        return DoctorsListApiResponse(
          success: false,
          doctors: [],
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return DoctorsListApiResponse(
        success: false,
        doctors: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch doctors list',
        ),
      );
    }
  }

  /// API 2: GET https://backend.chikitsakart.com/api/doctors/:id
  static Future<SingleDoctorApiResponse> getDoctorById(String id) async {
    if (id.trim().isEmpty) {
      return SingleDoctorApiResponse(
        success: false,
        message: 'Invalid Doctor ID',
      );
    }

    final Uri url = Uri.parse('$baseUrl/${id.trim()}');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return SingleDoctorApiResponse.fromJson(body);
      } else {
        return SingleDoctorApiResponse(
          success: false,
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleDoctorApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch doctor details',
        ),
      );
    }
  }

  /// Enriches a list of [ApiDoctor] items by calling [getDoctorById] for each doctor in parallel.
  /// This ensures that full details (including dynamic consultationFees and schedules) are populated.
  static Future<List<ApiDoctor>> enrichDoctorsWithDetails(
    List<ApiDoctor> doctors,
  ) async {
    if (doctors.isEmpty) return doctors;
    return await Future.wait(
      doctors.map((doc) async {
        if (doc.id.trim().isNotEmpty) {
          try {
            final res = await getDoctorById(doc.id);
            if (res.success && res.doctor != null) {
              return res.doctor!;
            }
          } catch (_) {}
        }
        return doc;
      }),
    );
  }

  /// API 3: GET https://backend.chikitsakart.com/api/doctors/profile
  static Future<SingleDoctorApiResponse> getDoctorProfile(String token) {
    return DoctorAuthService.getProfile(token: token);
  }
}
