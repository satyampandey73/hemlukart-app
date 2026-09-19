import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/brand_model.dart';

class BrandService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/brands';

  /// API: GET https://backend.chikitsakart.com/api/brands
  static Future<BrandApiResponse> getBrands() async {
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
        return BrandApiResponse.fromJson(body);
      } else {
        return BrandApiResponse(
          success: false,
          brands: [],
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return BrandApiResponse(
        success: false,
        brands: [],
        message: 'Failed to fetch brands: $e',
      );
    }
  }
}
