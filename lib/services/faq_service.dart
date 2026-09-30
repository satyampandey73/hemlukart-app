import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/faq_model.dart';
import 'api_helper.dart';

class FaqService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/faqs';

  /// API: GET https://backend.chikitsakart.com/api/faqs
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
          .timeout(const Duration(seconds: 30));

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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch FAQs',
        ),
      );
    }
  }
}
