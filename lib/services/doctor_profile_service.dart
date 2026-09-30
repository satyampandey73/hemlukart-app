import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/doctor_model.dart';
import '../constants/app_state.dart';
import 'api_helper.dart';

class DoctorProfileService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/doctors';

  static String _resolveFilename(String key, String filePath) {
    final base = p.basename(filePath).trim();
    final ext = p.extension(filePath).toLowerCase();
    if (ext.isEmpty || ext == '.tmp') {
      return '$key.jpg';
    }
    if (!['.jpg', '.jpeg', '.png', '.webp', '.pdf'].contains(ext)) {
      final nameWithoutExt = p.basenameWithoutExtension(filePath);
      return nameWithoutExt.isNotEmpty ? '$nameWithoutExt.jpg' : '$key.jpg';
    }
    return base.isNotEmpty ? base : '$key.jpg';
  }

  static MediaType _resolveMediaType(String filenameOrPath) {
    final ext = p.extension(filenameOrPath).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Endpoint: Get Doctor Profile
  /// API: GET https://backend.chikitsakart.com/api/doctors/profile
  static Future<SingleDoctorApiResponse> getProfile({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/profile');
    try {
      final cleanToken = token.trim();
      final authHeader = cleanToken.toLowerCase().startsWith('bearer ')
          ? cleanToken
          : 'Bearer $cleanToken';

      debugPrint('\n========== [DOCTOR GET PROFILE REQUEST] ==========');
      debugPrint('GET: $url');
      debugPrint('Authorization: ${authHeader.length > 25 ? "${authHeader.substring(0, 20)}..." : authHeader}');
      debugPrint('==================================================');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': authHeader,
        },
      ).timeout(const Duration(seconds: 30));

      debugPrint('\n========== [DOCTOR GET PROFILE RESPONSE] ==========');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('===================================================');

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        return SingleDoctorApiResponse(
          success: false,
          message: 'Server returned invalid response (${response.statusCode})',
        );
      }

      if (body is Map<String, dynamic>) {
        return SingleDoctorApiResponse.fromJson(body);
      }

      return SingleDoctorApiResponse(
        success: false,
        message: 'Invalid profile data received',
      );
    } catch (e) {
      debugPrint('\n========== [DOCTOR GET PROFILE ERROR] ==========');
      debugPrint('Error: $e');
      debugPrint('================================================');
      return SingleDoctorApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch doctor profile',
        ),
      );
    }
  }

  /// Endpoint: Update Doctor Profile
  /// API: PATCH https://backend.chikitsakart.com/api/doctors/profile
  static Future<SingleDoctorApiResponse> updateProfile({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final Uri url = Uri.parse('$baseUrl/profile');
    try {
      final cleanToken = token.trim();
      final authHeader = cleanToken.toLowerCase().startsWith('bearer ')
          ? cleanToken
          : 'Bearer $cleanToken';

      final encodedData = jsonEncode(data);
      debugPrint('\n========== [DOCTOR UPDATE PROFILE REQUEST] ==========');
      debugPrint('PATCH: $url');
      debugPrint('Authorization: ${authHeader.length > 25 ? "${authHeader.substring(0, 20)}..." : authHeader}');
      debugPrint('Payload: $encodedData');
      debugPrint('=====================================================');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': authHeader,
        },
        body: encodedData,
      ).timeout(const Duration(seconds: 30));

      debugPrint('\n========== [DOCTOR UPDATE PROFILE RESPONSE] ==========');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('======================================================');

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        return SingleDoctorApiResponse(
          success: false,
          message: 'Server returned error (${response.statusCode})',
        );
      }

      if (body is Map<String, dynamic>) {
        final res = SingleDoctorApiResponse.fromJson(body);
        if (res.success && res.doctor != null) {
          AppState().setCurrentDoctorProfile(res.doctor!);
        }
        return res;
      }

      return SingleDoctorApiResponse(
        success: false,
        message: 'Invalid server response (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('\n========== [DOCTOR UPDATE PROFILE ERROR] ==========');
      debugPrint('Error: $e');
      debugPrint('===================================================');
      return SingleDoctorApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update profile',
        ),
      );
    }
  }

  /// Endpoint: Upload Doctor Documents / Profile Photo
  /// API: POST https://backend.chikitsakart.com/api/doctors/register/documents
  /// Header:
  /// Authorization: Bearer `{token}`
  /// Content-Type: multipart/form-data
  /// Forms: profilePhoto, registrationCertificate, degreeCertificates, aadhaarFront, aadhaarBack, panCard, cancelledCheque
  static Future<DoctorDocumentsResponse> uploadDocuments({
    required String token,
    Map<String, String>? filePaths,
    Map<String, List<int>>? fileBytes,
    Map<String, List<String>>? multiFilePaths,
  }) async {
    final Uri url = Uri.parse('$baseUrl/register/documents');
    try {
      final request = http.MultipartRequest('POST', url);
      
      final cleanToken = token.trim();
      final authHeader = cleanToken.toLowerCase().startsWith('bearer ')
          ? cleanToken
          : 'Bearer $cleanToken';
      request.headers['Authorization'] = authHeader;
      request.headers['Accept'] = 'application/json';

      // 1. Single file from path
      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          if (entry.value.isNotEmpty) {
            final filename = _resolveFilename(entry.key, entry.value);
            final mediaType = _resolveMediaType(filename);
            request.files.add(
              await http.MultipartFile.fromPath(
                entry.key,
                entry.value,
                filename: filename,
                contentType: mediaType,
              ),
            );
          }
        }
      }

      // 2. Single or multiple files from bytes
      if (fileBytes != null) {
        for (final entry in fileBytes.entries) {
          if (entry.value.isNotEmpty) {
            final filename = '${entry.key}.jpg';
            request.files.add(
              http.MultipartFile.fromBytes(
                entry.key,
                entry.value,
                filename: filename,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          }
        }
      }

      // 3. Multi-file entries (e.g. degreeCertificates)
      if (multiFilePaths != null) {
        for (final entry in multiFilePaths.entries) {
          for (final path in entry.value) {
            if (path.isNotEmpty) {
              final filename = _resolveFilename(entry.key, path);
              final mediaType = _resolveMediaType(filename);
              request.files.add(
                await http.MultipartFile.fromPath(
                  entry.key,
                  path,
                  filename: filename,
                  contentType: mediaType,
                ),
              );
            }
          }
        }
      }

      debugPrint('\n========== [DOCTOR UPLOAD DOCUMENTS REQUEST] ==========');
      debugPrint('POST: $url');
      debugPrint('Authorization: ${authHeader.length > 25 ? "${authHeader.substring(0, 20)}..." : authHeader}');
      debugPrint('Files Count: ${request.files.length}');
      for (final f in request.files) {
        final kb = (f.length / 1024).toStringAsFixed(1);
        debugPrint('  - field="${f.field}", filename="${f.filename}", contentType=${f.contentType}, length=${f.length} bytes ($kb KB)');
        if (f.length > 1024 * 1024) {
          debugPrint('  WARNING: File "${f.filename}" is $kb KB (> 1MB). Nginx limit is 1MB!');
        }
      }
      debugPrint('======================================================');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('\n========== [DOCTOR UPLOAD DOCUMENTS RESPONSE] ==========');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('========================================================');

      if (response.statusCode == 413) {
        return DoctorDocumentsResponse(
          success: false,
          message:
              'File size is too large (exceeds server 1MB limit). Please choose a smaller image or file.',
        );
      }

      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (parseError) {
        debugPrint('[DoctorProfileService] Failed to parse JSON response: $parseError');
        return DoctorDocumentsResponse(
          success: false,
          message:
              'Server error (${response.statusCode}): ${response.reasonPhrase ?? 'Upload failed'}',
        );
      }

      if (body is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final docResponse = DoctorDocumentsResponse.fromJson(body);
          if (docResponse.success && docResponse.documents != null) {
            final currentDoc = AppState().currentDoctorProfile;
            if (currentDoc != null) {
              final existingDocs =
                  currentDoc.documents ?? DoctorDocumentsData();
              final newDocs = docResponse.documents!;
              final mergedDocs = existingDocs.copyWith(
                profilePhoto: newDocs.profilePhoto ?? existingDocs.profilePhoto,
                panCard: newDocs.panCard ?? existingDocs.panCard,
                aadhaarFront:
                    newDocs.aadhaarFront ?? existingDocs.aadhaarFront,
                aadhaarBack: newDocs.aadhaarBack ?? existingDocs.aadhaarBack,
                registrationCertificate: newDocs.registrationCertificate ??
                    existingDocs.registrationCertificate,
                cancelledCheque:
                    newDocs.cancelledCheque ?? existingDocs.cancelledCheque,
                degreeCertificates: (newDocs.degreeCertificates != null &&
                        newDocs.degreeCertificates!.isNotEmpty)
                    ? newDocs.degreeCertificates
                    : existingDocs.degreeCertificates,
              );
              AppState().setCurrentDoctorProfile(
                  currentDoc.copyWith(documents: mergedDocs));
            }
          }
          return docResponse;
        } else {
          final errorMsg = body['message'] ??
              body['error'] ??
              'Server error (${response.statusCode})';
          return DoctorDocumentsResponse(
            success: false,
            message: errorMsg.toString(),
          );
        }
      }

      return DoctorDocumentsResponse(
        success: false,
        message: 'Invalid response format (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('\n========== [DOCTOR UPLOAD DOCUMENTS ERROR] ==========');
      debugPrint('Error: $e');
      debugPrint('=====================================================');
      return DoctorDocumentsResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to upload documents',
        ),
      );
    }
  }
}
