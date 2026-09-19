import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon_model.dart';

class CouponService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/coupons';

  static Map<String, String> _buildHeaders(String? token) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// API: GET https://backend.chikitsakart.com/api/coupons
  static Future<CouponsApiResponse> getCoupons({String? token}) async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return CouponsApiResponse.fromJson(body);
      } else {
        return CouponsApiResponse(
          success: false,
          message: 'Server returned status code: ${response.statusCode}',
          data: [],
        );
      }
    } catch (e) {
      return CouponsApiResponse(
        success: false,
        message: 'Failed to fetch coupons: $e',
        data: [],
      );
    }
  }
}
