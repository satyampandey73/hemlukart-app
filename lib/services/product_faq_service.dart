import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_faq_model.dart';

class ProductFaqService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/product-faqs/product';

  /// API: GET https://hospital.gntechnology.de/api/product-faqs/product/{productId}
  static Future<ProductFaqsApiResponse> getFaqsByProductId(String productId) async {
    final Uri url = Uri.parse('$baseUrl/$productId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return ProductFaqsApiResponse.fromJson(body);
      } else {
        return ProductFaqsApiResponse(
          success: false,
          faqs: [],
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return ProductFaqsApiResponse(
        success: false,
        faqs: [],
        message: 'Failed to fetch product FAQs: $e',
      );
    }
  }

  /// API: POST https://hospital.gntechnology.de/api/product-faqs/product/{productId}/ask
  /// Payload: { "question": "Is this multivitamin suitable for vegetarians?" }
  static Future<AskProductFaqResponse> askQuestion({
    required String productId,
    required String question,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$productId/ask');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'question': question.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AskProductFaqResponse.fromJson(body);
      } else {
        return AskProductFaqResponse(
          success: body['success'] == true,
          message: body['message']?.toString() ??
              'Server returned status code ${response.statusCode}',
          faq: body['faq'] is Map<String, dynamic>
              ? ProductFaqModel.fromJson(body['faq'] as Map<String, dynamic>)
              : null,
        );
      }
    } catch (e) {
      return AskProductFaqResponse(
        success: false,
        message: 'Failed to submit question: $e',
      );
    }
  }
}
