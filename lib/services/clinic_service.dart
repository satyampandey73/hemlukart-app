import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinic_model.dart';

class ClinicService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/clinics';

  /// API: GET https://backend.chikitsakart.com/api/clinics
  /// Query parameters:
  /// - page: Optional page number
  /// - limit: Optional limit per page
  /// - search: Optional search string
  static Future<ClinicsApiResponse> getClinics({
    int? page,
    int? limit,
    String? search,
  }) async {
    Uri url = Uri.parse(baseUrl);
    final Map<String, String> queryParams = {};

    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return ClinicsApiResponse.fromJson(body);
      } else {
        return ClinicsApiResponse(
          success: false,
          clinics: [],
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ClinicsApiResponse(
        success: false,
        clinics: [],
        message: 'Failed to fetch clinics list: $e',
      );
    }
  }

  /// API: GET https://backend.chikitsakart.com/api/clinics/:id
  static Future<SingleClinicApiResponse> getClinicById(String id) async {
    if (id.trim().isEmpty) {
      return SingleClinicApiResponse(
        success: false,
        message: 'Invalid Clinic ID',
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return SingleClinicApiResponse.fromJson(body);
      } else {
        return SingleClinicApiResponse(
          success: false,
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleClinicApiResponse(
        success: false,
        message: 'Failed to fetch clinic details: $e',
      );
    }
  }
}
