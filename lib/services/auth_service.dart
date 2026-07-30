import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/users';

  /// Registration - Send OTP
  /// API: POST https://hospital.gntechnology.de/api/users/send-otp
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
  /// API: POST https://hospital.gntechnology.de/api/users/verify-otp-register
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
  /// API: POST https://hospital.gntechnology.de/api/users/login/send-otp
  static Future<SendOtpResponse> sendLoginOtp({
    required String mobile,
  }) async {
    final Uri url = Uri.parse('$baseUrl/login/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mobile': mobile.trim(),
        }),
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
  /// API: POST https://hospital.gntechnology.de/api/users/login/verify-otp
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
        body: jsonEncode({
          'mobile': mobile.trim(),
          'otp': otp.trim(),
        }),
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
  /// API: GET https://hospital.gntechnology.de/api/users/profile
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
}
