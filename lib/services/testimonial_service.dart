import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/testimonial_model.dart';
import 'api_helper.dart';

class TestimonialService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/testimonials';

  /// API: GET https://backend.chikitsakart.com/api/testimonials
  static Future<TestimonialApiResponse> getTestimonials() async {
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
        return TestimonialApiResponse.fromJson(body);
      } else {
        return TestimonialApiResponse(
          success: false,
          testimonials: [],
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return TestimonialApiResponse(
        success: false,
        testimonials: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch testimonials',
        ),
      );
    }
  }
}
