import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/user_model.dart';
import 'api_helper.dart';

class AuthService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/users';

  /// Registration - Send OTP
  /// API: POST https://backend.chikitsakart.com/api/users/send-otp
  static Future<SendOtpResponse> sendOtp({
    required String fullName,
    required String email,
    required String whatsappNumber,
    required String mobile,
  }) async {
    final Uri url = Uri.parse('$baseUrl/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'whatsappNumber': whatsappNumber.trim(),
          'mobile': mobile.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.body.trim().startsWith('<')) {
        return SendOtpResponse(
          success: false,
          message: 'Server error (${response.statusCode}). Please try again later.',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return SendOtpResponse.fromJson(body);
    } catch (e) {
      return SendOtpResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to send OTP',
        ),
      );
    }
  }

  /// Registration - Verify OTP & Register
  /// API: POST https://backend.chikitsakart.com/api/users/register
  static Future<VerifyOtpRegisterResponse> verifyOtpRegister({
    required String fullName,
    required String email,
    required String whatsappNumber,
    required String mobile,
    required String otp,
  }) async {
    final Uri url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'whatsappNumber': whatsappNumber.trim(),
          'mobile': mobile.trim(),
          'otp': otp.trim(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.body.trim().startsWith('<')) {
        return VerifyOtpRegisterResponse(
          success: false,
          message: 'Server error (${response.statusCode}). Please try again.',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return VerifyOtpRegisterResponse.fromJson(body);
    } catch (e) {
      return VerifyOtpRegisterResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to complete registration',
        ),
      );
    }
  }

  /// Login - Send OTP
  /// API: POST https://backend.chikitsakart.com/api/users/login/send-otp
  static Future<SendOtpResponse> sendLoginOtp({required String mobile}) async {
    final Uri url = Uri.parse('$baseUrl/login/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'mobile': mobile.trim()}),
      ).timeout(const Duration(seconds: 30));

      if (response.body.trim().startsWith('<')) {
        return SendOtpResponse(
          success: false,
          message: 'Server error (${response.statusCode}). Please try again later.',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return SendOtpResponse.fromJson(body);
    } catch (e) {
      return SendOtpResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to send login OTP',
        ),
      );
    }
  }

  /// Login - Verify OTP
  /// API: POST https://backend.chikitsakart.com/api/users/login/verify-otp
  static Future<VerifyOtpRegisterResponse> verifyLoginOtp({
    required String mobile,
    required String otp,
  }) async {
    final Uri url = Uri.parse('$baseUrl/login/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'mobile': mobile.trim(), 'otp': otp.trim()}),
      ).timeout(const Duration(seconds: 30));

      if (response.body.trim().startsWith('<')) {
        return VerifyOtpRegisterResponse(
          success: false,
          message: 'Server error (${response.statusCode}). Please try again.',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      return VerifyOtpRegisterResponse.fromJson(body);
    } catch (e) {
      return VerifyOtpRegisterResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to verify login OTP',
        ),
      );
    }
  }

  /// Get User Profile
  /// API: GET https://backend.chikitsakart.com/api/users/profile
  static Future<UserProfileResponse> getUserProfile({
    required String token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return UserProfileResponse.fromJson(body);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch user profile',
        ),
      );
    }
  }

  /// Update User Profile
  /// API: PUT https://backend.chikitsakart.com/api/users/profile/edit
  ///
  /// • profileImage == null  → plain JSON PUT (raw body)
  /// • profileImage != null  → multipart/form-data PUT
  static Future<UpdateProfileResponse> updateProfile({
    required String token,
    required String fullName,
    required String email,
    required String mobile,
    required String dateOfBirth,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
    File? profileImage,
  }) async {
    final Uri url = Uri.parse('$baseUrl/profile/edit');
    try {
      // ── Case 1: No image → plain JSON body ──────────────────────────────
      if (profileImage == null) {
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            'mobile': mobile,
            'dateOfBirth': dateOfBirth,
            'gender': gender,
            'address': address,
            'city': city,
            'state': state,
            'pincode': pincode,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.body.trim().startsWith('<')) {
          return UpdateProfileResponse(
            success: false,
            message: 'Server error (${response.statusCode}). Please try again.',
          );
        }
        final Map<String, dynamic> body = jsonDecode(response.body);
        return UpdateProfileResponse.fromJson(body);
      }

      // ── Case 2: Image selected → multipart/form-data ────────────────────
      final request = http.MultipartRequest('PUT', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['fullName'] = fullName
        ..fields['email'] = email
        ..fields['mobile'] = mobile
        ..fields['dateOfBirth'] = dateOfBirth
        ..fields['gender'] = gender
        ..fields['address'] = address
        ..fields['city'] = city
        ..fields['state'] = state
        ..fields['pincode'] = pincode;

      // Determine MIME type from extension.
      // Server accepts: image/jpeg, image/png, image/webp only.
      final ext = p
          .extension(profileImage.path)
          .toLowerCase()
          .replaceAll('.', '');
      final MediaType mediaType;
      switch (ext) {
        case 'png':
          mediaType = MediaType('image', 'png');
          break;
        case 'webp':
          mediaType = MediaType('image', 'webp');
          break;
        default:
          // jpeg, jpg, heic, heif, bmp, tiff, gif → image/jpeg
          // image_picker already converts HEIC/HEIF to JPEG on iOS
          mediaType = MediaType('image', 'jpeg');
      }

      // Use a safe filename so server-side validators pass
      final safeName = 'profile.${ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpg'}';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profileImage',
          profileImage.path,
          contentType: mediaType,
          filename: safeName,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (responseBody.trim().startsWith('<')) {
        return UpdateProfileResponse(
          success: false,
          message: 'Server error (${streamedResponse.statusCode}). Please try again.',
        );
      }
      final Map<String, dynamic> body = jsonDecode(responseBody);
      return UpdateProfileResponse.fromJson(body);
    } catch (e) {
      return UpdateProfileResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update profile',
        ),
      );
    }
  }
}

