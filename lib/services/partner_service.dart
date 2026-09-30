import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_helper.dart';

class PartnerService {
  static const String liveUrl = 'https://backend.chikitsakart.com/api/partner-requests';
  static const String localUrl = 'http://10.0.2.2:5000/api/partner-requests';

  static Future<Map<String, dynamic>> submitPartnerRequest({
    required String companyName,
    required String companyType,
    required String yourName,
    required String email,
    required String phone,
    required String state,
    required String city,
    required String convenientTimeToContact,
  }) async {
    final payload = {
      'companyName': companyName.trim(),
      'companyType': companyType.trim(),
      'yourName': yourName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'state': state.trim(),
      'city': city.trim(),
      'convenientTimeToContact': convenientTimeToContact.trim(),
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Try live backend API first
    try {
      final response = await http
          .post(
            Uri.parse(liveUrl),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Partner request submitted successfully. We will contact you soon!',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to submit partner request (${response.statusCode})',
        };
      }
    } on SocketException catch (_) {
      // Fallback for local testing (localhost / Android emulator)
      try {
        final fallbackUrl = Platform.isAndroid ? localUrl : 'http://localhost:5000/api/partner-requests';
        final response = await http
            .post(
              Uri.parse(fallbackUrl),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 5));

        final data = jsonDecode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': true,
            'message': data['message'] ?? 'Partner request submitted successfully. We will contact you soon!',
            'data': data['data'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? data['error'] ?? 'Failed to submit partner request',
          };
        }
      } catch (fallbackErr) {
        return {
          'success': false,
          'message': 'Network error. Please check your internet connection.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to submit partner request',
        ),
      };
    }
  }
}
