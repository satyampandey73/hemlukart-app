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

  /// API: GET https://backend.chikitsakart.com/api/clinics/my/clinics
  /// Fetches clinics owned/managed by the authenticated doctor.
  static Future<MyClinicsApiResponse> getMyClinics({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/my/clinics');
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
        return MyClinicsApiResponse.fromJson(body);
      } else {
        String msg = 'Failed to fetch doctor clinics (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return MyClinicsApiResponse(
          success: false,
          clinics: [],
          message: msg,
        );
      }
    } catch (e) {
      return MyClinicsApiResponse(
        success: false,
        clinics: [],
        message: 'Network error fetching doctor clinics: $e',
      );
    }
  }

  /// API: POST https://backend.chikitsakart.com/api/clinics
  /// Doctor creates / registers a new clinic. Supports multipart for images.
  static Future<ClinicMutationResponse> createClinic({
    required String token,
    required String clinicName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String registrationNo,
    String? about,
    List<String>? imagePaths,
    List<List<int>>? imageBytesList,
    List<String>? imageFileNames,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['clinicName'] = clinicName.trim();
      request.fields['phone'] = phone.trim();
      request.fields['email'] = email.trim();
      request.fields['address'] = address.trim();
      request.fields['city'] = city.trim();
      request.fields['state'] = state.trim();
      request.fields['pincode'] = pincode.trim();
      request.fields['registrationNo'] = registrationNo.trim();
      if (about != null && about.trim().isNotEmpty) {
        request.fields['about'] = about.trim();
      }

      // Add image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final p = imagePaths[i];
          if (p.isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('images', p));
          }
        }
      } else if (imageBytesList != null && imageBytesList.isNotEmpty) {
        for (int i = 0; i < imageBytesList.length; i++) {
          final bytes = imageBytesList[i];
          final fname = (imageFileNames != null && imageFileNames.length > i)
              ? imageFileNames[i]
              : 'clinic_img_$i.jpg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: fname,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(responseBody);
        return ClinicMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to register clinic (Status: ${streamedResponse.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(responseBody);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return ClinicMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return ClinicMutationResponse(
        success: false,
        message: 'Network error registering clinic: $e',
      );
    }
  }

  /// API: PUT https://backend.chikitsakart.com/api/clinics/:id
  /// Doctor updates an existing clinic.
  static Future<ClinicMutationResponse> updateClinic({
    required String token,
    required String clinicId,
    required String clinicName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String registrationNo,
    String? about,
    bool? isActive,
    List<String>? imagePaths,
    List<List<int>>? imageBytesList,
    List<String>? imageFileNames,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$clinicId');
    try {
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['clinicName'] = clinicName.trim();
      request.fields['phone'] = phone.trim();
      request.fields['email'] = email.trim();
      request.fields['address'] = address.trim();
      request.fields['city'] = city.trim();
      request.fields['state'] = state.trim();
      request.fields['pincode'] = pincode.trim();
      request.fields['registrationNo'] = registrationNo.trim();
      if (about != null) {
        request.fields['about'] = about.trim();
      }
      if (isActive != null) {
        request.fields['isActive'] = isActive.toString();
      }

      // Add image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final p = imagePaths[i];
          if (p.isNotEmpty) {
            request.files.add(await http.MultipartFile.fromPath('images', p));
          }
        }
      } else if (imageBytesList != null && imageBytesList.isNotEmpty) {
        for (int i = 0; i < imageBytesList.length; i++) {
          final bytes = imageBytesList[i];
          final fname = (imageFileNames != null && imageFileNames.length > i)
              ? imageFileNames[i]
              : 'clinic_img_$i.jpg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: fname,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(responseBody);
        return ClinicMutationResponse.fromJson(body);
      } else {
        String msg = 'Failed to update clinic (Status: ${streamedResponse.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(responseBody);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return ClinicMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return ClinicMutationResponse(
        success: false,
        message: 'Network error updating clinic: $e',
      );
    }
  }

  /// API: DELETE https://backend.chikitsakart.com/api/clinics/:id
  static Future<ClinicMutationResponse> deleteClinic({
    required String token,
    required String clinicId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$clinicId');
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return ClinicMutationResponse.fromJson(body);
        } catch (_) {
          return ClinicMutationResponse(
            success: true,
            message: 'Clinic deleted successfully',
          );
        }
      } else {
        String msg = 'Failed to delete clinic (Status: ${response.statusCode})';
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['message'] != null) msg = body['message'].toString();
        } catch (_) {}
        return ClinicMutationResponse(
          success: false,
          message: msg,
        );
      }
    } catch (e) {
      return ClinicMutationResponse(
        success: false,
        message: 'Network error deleting clinic: $e',
      );
    }
  }

  /// API: POST https://backend.chikitsakart.com/api/clinics/:id/doctors
  /// Add doctor / staff doctor to clinic.
  static Future<Map<String, dynamic>> addDoctorToClinic({
    required String token,
    required String clinicId,
    required String doctorId,
    required String role,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$clinicId/doctors');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'doctorId': doctorId.trim(),
              'role': role.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201 || (body['success'] == true),
        'message': body['message'] ?? (response.statusCode == 200 ? 'Doctor added successfully' : 'Failed to add doctor'),
        'data': body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error adding doctor to clinic: $e',
      };
    }
  }
}
