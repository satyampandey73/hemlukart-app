import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faq_model.dart';

class FaqService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/faqs';

  /// API: GET https://hospital.gntechnology.de/api/faqs
  static Future<FaqApiResponse> getFaqs() async {
    final Uri url = Uri.parse(baseUrl);
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
        return FaqApiResponse.fromJson(body);
      } else {
        return FaqApiResponse(
          success: false,
          faqs: [],
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return FaqApiResponse(
        success: false,
        faqs: [],
        message: 'Failed to fetch FAQs: $e',
      );
    }
  }
}
