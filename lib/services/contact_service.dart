import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_helper.dart';

class ContactService {
  static const String liveUrl = 'https://backend.chikitsakart.com/api/contacts';
  static const String localUrl = 'http://10.0.2.2:5000/api/contacts';

  static Future<Map<String, dynamic>> submitContactForm({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String whoAreYou,
    required String message,
  }) async {
    final payload = {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'mobileNumber': mobileNumber.trim(),
      'whoAreYou': whoAreYou.toLowerCase().trim(),
      'message': message.trim(),
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Try live production API first
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
          'message': data['message'] ?? 'Thank you for contacting us! We will get back to you soon.',
          'contact': data['contact'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to submit contact form (${response.statusCode})',
        };
      }
    } on SocketException catch (_) {
      // Fallback for local testing (localhost / Android emulator)
      try {
        final fallbackUrl = Platform.isAndroid ? localUrl : 'http://localhost:5000/api/contacts';
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
            'message': data['message'] ?? 'Thank you for contacting us! We will get back to you soon.',
            'contact': data['contact'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? data['error'] ?? 'Failed to submit contact form',
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
          fallback: 'Failed to submit contact form',
        ),
      };
    }
  }
}
