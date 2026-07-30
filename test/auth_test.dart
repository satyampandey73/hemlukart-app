import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/user_model.dart';

void main() {
  group('Auth Model Tests', () {
    test('SendOtpResponse parsing test', () {
      final json = {
        "success": true,
        "message": "OTP sent successfully to your mobile number",
        "otp": "1234"
      };

      final response = SendOtpResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.message, equals("OTP sent successfully to your mobile number"));
      expect(response.otp, equals("1234"));
    });

    test('VerifyOtpRegisterResponse and UserModel parsing test', () {
      final json = {
        "success": true,
        "message": "Registration successful! Welcome to our platform",
        "token": "test_jwt_token_xyz",
        "user": {
          "id": "a44a4420-bb37-4e31-a752-485d161a6fc0",
          "fullName": "John Doe",
          "mobile": "9873543010",
          "whatsappNumber": "9876149210",
          "email": "soyb@gmail.com",
          "role": "customer",
          "profileImage": "",
          "mobileOtp": null,
          "mobileOtpExpiry": null,
          "isMobileVerified": true,
          "isActive": true,
          "lastLoginAt": null,
          "createdAt": "2026-07-28T13:02:21.278Z",
          "updatedAt": "2026-07-28T13:02:21.278Z"
        }
      };

      final response = VerifyOtpRegisterResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.token, equals("test_jwt_token_xyz"));
      expect(response.user, isNotNull);
      expect(response.user!.fullName, equals("John Doe"));
      expect(response.user!.email, equals("soyb@gmail.com"));
      expect(response.user!.whatsappNumber, equals("9876149210"));
      expect(response.user!.mobile, equals("9873543010"));
      expect(response.user!.isMobileVerified, isTrue);
    });

    test('VerifyLoginOtp response parsing test', () {
      final json = {
        "success": true,
        "message": "Login successful! Welcome back",
        "token": "test_login_jwt_token",
        "user": {
          "id": "d98b4f43-24b4-47a9-ad44-edb77c36f4ec",
          "fullName": "John Doe",
          "mobile": "9873543210",
          "whatsappNumber": "9876143210",
          "email": "soyeb@gmail.com",
          "role": "customer",
          "profileImage": "",
          "mobileOtp": null,
          "mobileOtpExpiry": null,
          "isMobileVerified": true,
          "isActive": true,
          "lastLoginAt": "2026-07-28T12:56:19.982Z",
          "createdAt": "2026-07-28T09:51:04.390Z",
          "updatedAt": "2026-07-28T09:51:04.390Z"
        }
      };

      final response = VerifyOtpRegisterResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.message, equals("Login successful! Welcome back"));
      expect(response.token, equals("test_login_jwt_token"));
      expect(response.user!.id, equals("d98b4f43-24b4-47a9-ad44-edb77c36f4ec"));
    });

    test('UserProfileResponse parsing test', () {
      final json = {
        "success": true,
        "user": {
          "id": "d98b4f43-24b4-47a9-ad44-edb77c36f4ec",
          "fullName": "John Doe",
          "mobile": "9873543210",
          "whatsappNumber": "9876143210",
          "email": "soyeb@gmail.com",
          "role": "customer",
          "profileImage": "",
          "mobileOtp": null,
          "mobileOtpExpiry": null,
          "isMobileVerified": true,
          "isActive": true,
          "lastLoginAt": "2026-07-28T14:25:11.646Z",
          "createdAt": "2026-07-28T09:51:04.390Z",
          "updatedAt": "2026-07-28T09:51:04.390Z"
        }
      };

      final response = UserProfileResponse.fromJson(json);
      expect(response.success, isTrue);
      expect(response.user, isNotNull);
      expect(response.user!.fullName, equals("John Doe"));
      expect(response.user!.mobile, equals("9873543210"));
    });
  });
}
