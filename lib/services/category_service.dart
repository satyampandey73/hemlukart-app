import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

class CategoryService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/categories';

  /// API: GET https://hospital.gntechnology.de/api/categories
  static Future<CategoriesApiResponse> getCategories() async {
    final Uri url = Uri.parse(baseUrl);
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
        return CategoriesApiResponse.fromJson(body);
      } else {
        return CategoriesApiResponse(
          success: false,
          categories: [],
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CategoriesApiResponse(
        success: false,
        categories: [],
        message: 'Failed to fetch categories: $e',
      );
    }
  }
}
