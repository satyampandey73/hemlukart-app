import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wishlist_model.dart';
import 'api_helper.dart';

class WishlistService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/wishlists';

  /// API: POST https://backend.chikitsakart.com/api/wishlists/user/products
  /// Request Body: {"productId": "bcebcbee-106e-4c54-a575-8f406931b94d"}
  /// Response: {"success": true, "message": "Added to wishlist"} / {"success": true, "message": "Removed from wishlist"}
  static Future<WishlistActionResponse> toggleWishlist({
    required String productId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/user/products');
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
            body: jsonEncode({'productId': productId.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return WishlistActionResponse.fromJson(body);
      } else {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return WishlistActionResponse(
            success: body['success'] == true,
            message:
                body['message']?.toString() ??
                'Server returned status ${response.statusCode}',
          );
        } catch (_) {
          return WishlistActionResponse(
            success: false,
            message: 'Server returned error status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      return WishlistActionResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update wishlist',
        ),
      );
    }
  }

  static Future<WishlistActionResponse> addToWishlist({
    required String productId,
    String? token,
  }) async => toggleWishlist(productId: productId, token: token);

  static Future<WishlistActionResponse> removeFromWishlist({
    required String productId,
    String? token,
  }) async => toggleWishlist(productId: productId, token: token);

  /// API: GET https://backend.chikitsakart.com/api/wishlists/user/products
  /// Response: {"success": true, "data": [...]}
  static Future<UserWishlistProductsApiResponse> getUserWishlistProducts({
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/user/products');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return UserWishlistProductsApiResponse.fromJson(body);
      } else {
        return UserWishlistProductsApiResponse(
          success: false,
          data: [],
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UserWishlistProductsApiResponse(
        success: false,
        data: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch wishlist products',
        ),
      );
    }
  }

  /// API: POST https://backend.chikitsakart.com/api/wishlists/user/doctors
  /// Request Body: {"targetDoctorId": "a78cb806-93db-46e2-b9ea-9fd8409ef29f"}
  /// Response: {"success": true, "message": "Added to wishlist"}
  static Future<WishlistActionResponse> toggleDoctorWishlist({
    required String targetDoctorId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/user/doctors');
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
            body: jsonEncode({'targetDoctorId': targetDoctorId.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return WishlistActionResponse.fromJson(body);
      } else {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return WishlistActionResponse(
            success: body['success'] == true,
            message:
                body['message']?.toString() ??
                'Server returned status ${response.statusCode}',
          );
        } catch (_) {
          return WishlistActionResponse(
            success: false,
            message: 'Server returned error status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      return WishlistActionResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update doctor wishlist',
        ),
      );
    }
  }

  static Future<WishlistActionResponse> addToDoctorWishlist({
    required String targetDoctorId,
    String? token,
  }) async =>
      toggleDoctorWishlist(targetDoctorId: targetDoctorId, token: token);

  static Future<WishlistActionResponse> removeFromDoctorWishlist({
    required String targetDoctorId,
    String? token,
  }) async =>
      toggleDoctorWishlist(targetDoctorId: targetDoctorId, token: token);

  /// API: GET https://backend.chikitsakart.com/api/wishlists/user/doctors
  /// Response: {"success": true, "data": [...]}
  static Future<UserWishlistDoctorsApiResponse> getUserWishlistDoctors({
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/user/doctors');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return UserWishlistDoctorsApiResponse.fromJson(body);
      } else {
        return UserWishlistDoctorsApiResponse(
          success: false,
          data: [],
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UserWishlistDoctorsApiResponse(
        success: false,
        data: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch doctor wishlist',
        ),
      );
    }
  }
}
