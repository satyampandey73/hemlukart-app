import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/products';

  /// API: GET https://backend.chikitsakart.com/api/products
  /// Query Parameters:
  /// - categoryId: Optional category UUID (e.g. 35d62575-7f10-409d-955e-b1dfb172f2f3)
  /// - search: Optional search query string (e.g. Ashwagandha)
  static Future<ProductsApiResponse> getProducts({
    String? categoryId,
    String? search,
  }) async {
    Uri url = Uri.parse(baseUrl);
    final Map<String, String> queryParams = {};
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      queryParams['categoryId'] = categoryId.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
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
        return ProductsApiResponse.fromJson(body);
      } else {
        return ProductsApiResponse(
          success: false,
          products: [],
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ProductsApiResponse(
        success: false,
        products: [],
        message: 'Failed to fetch products: $e',
      );
    }
  }

  /// API: GET https://backend.chikitsakart.com/api/products/{id}
  static Future<SingleProductApiResponse> getProductById(String id) async {
    final Uri url = Uri.parse('$baseUrl/$id');
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
        return SingleProductApiResponse.fromJson(body);
      } else {
        return SingleProductApiResponse(
          success: false,
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleProductApiResponse(
        success: false,
        message: 'Failed to fetch product details: $e',
      );
    }
  }
}
