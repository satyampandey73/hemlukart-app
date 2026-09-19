import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../models/user_model.dart';

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
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return SendOtpResponse.fromJson(body);
    } catch (e) {
      return SendOtpResponse(
        success: false,
        message: 'Failed to send OTP. Please check your network connection: $e',
      );
    }
  }

  /// Registration - Verify OTP & Register
  /// API: POST https://backend.chikitsakart.com/api/users/verify-otp-register
  static Future<VerifyOtpRegisterResponse> verifyOtpRegister({
    required String fullName,
    required String email,
    required String whatsappNumber,
    required String mobile,
    required String otp,
  }) async {
    final Uri url = Uri.parse('$baseUrl/verify-otp-register');
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
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return VerifyOtpRegisterResponse.fromJson(body);
    } catch (e) {
      return VerifyOtpRegisterResponse(
        success: false,
        message: 'Failed to verify OTP. Please try again: $e',
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
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return SendOtpResponse.fromJson(body);
    } catch (e) {
      return SendOtpResponse(
        success: false,
        message: 'Failed to send login OTP. Please check your network: $e',
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
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return VerifyOtpRegisterResponse.fromJson(body);
    } catch (e) {
      return VerifyOtpRegisterResponse(
        success: false,
        message: 'Failed to verify login OTP: $e',
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
      );

      final Map<String, dynamic> body = jsonDecode(response.body);
      return UserProfileResponse.fromJson(body);
    } catch (e) {
      return UserProfileResponse(
        success: false,
        message: 'Failed to fetch user profile: $e',
      );
    }
  }

  /// Update User Profile
  /// API: PUT https://backend.chikitsakart.com/api/users/profile/edit
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

      if (profileImage != null) {
        // Determine MIME type from extension and map unsupported formats to JPEG.
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
            // jpeg, jpg, heic, heif, bmp, tiff, gif — all sent as image/jpeg
            // image_picker already converts HEIC/HEIF to JPEG on iOS
            mediaType = MediaType('image', 'jpeg');
        }

        // Use a safe filename with the correct extension so server-side validators pass
        final safeName =
            'profile.${ext == 'png'
                ? 'png'
                : ext == 'webp'
                ? 'webp'
                : 'jpg'}';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            profileImage.path,
            contentType: mediaType,
            filename: safeName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> body = jsonDecode(responseBody);
      return UpdateProfileResponse.fromJson(body);
    } catch (e) {
      return UpdateProfileResponse(
        success: false,
        message: 'Failed to update profile: $e',
      );
    }
  }
}
