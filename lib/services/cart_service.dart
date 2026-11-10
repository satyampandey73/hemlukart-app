import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_model.dart';
import 'api_helper.dart';

class CartService {
  static const String baseUrl = 'https://backend.chikitsakart.com/api/cart';

  /// API: POST https://backend.chikitsakart.com/api/cart
  /// Request Body:
  /// {
  ///   "productId": "dfae3ed6-b953-4668-9f29-37afe344c62a",
  ///   "quantity": 1,
  ///   "skuId": "029a1e05-0926-4b6a-b1f0-ac85577ff1a4",
  ///   "sellerId": "c1a2b3c4-d5e6-7890-abcd-ef1234567890",
  ///   "price": 343.00,
  ///   "mrp": 350.00,
  ///   "discount": 2.00
  /// }
  static Future<AddToCartApiResponse> addToCart({
    required String productId,
    String? skuId,
    String? sellerId,
    double? price,
    double? mrp,
    double? discount,
    int quantity = 1,
    String? token,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final Map<String, dynamic> requestBody = {
      'productId': productId.trim(),
      'quantity': quantity,
      if (skuId != null && skuId.isNotEmpty) 'skuId': skuId.trim(),
      if (sellerId != null && sellerId.isNotEmpty) 'sellerId': sellerId.trim(),
      if (price != null && price > 0) 'price': price,
      if (mrp != null && mrp > 0) 'mrp': mrp,
      if (discount != null && discount > 0) 'discount': discount,
    };

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddToCartApiResponse.fromJson(body);
      } else {
        return AddToCartApiResponse(
          success: body['success'] == true,
          message:
              body['message']?.toString() ??
              'Server returned status ${response.statusCode}',
          data: body['data'] != null && body['data'] is Map<String, dynamic>
              ? CartItemData.fromJson(body['data'] as Map<String, dynamic>)
              : null,
        );
      }
    } catch (e) {
      return AddToCartApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to add item to cart',
        ),
      );
    }
  }

  /// API: GET https://backend.chikitsakart.com/api/cart
  /// Response: {"success": true, "data": {"cart": {...}, "items": [...]}}
  static Future<GetCartApiResponse> getCart({String? token}) async {
    final Uri url = Uri.parse(baseUrl);
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
        return GetCartApiResponse.fromJson(body);
      } else {
        return GetCartApiResponse(
          success: false,
          message: 'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return GetCartApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch cart',
        ),
      );
    }
  }

  /// API: PUT https://backend.chikitsakart.com/api/cart/items/{itemId}
  /// Request Body: {"quantity": 5}
  /// Response: {"success": true, "message": "Cart item updated", "data": {...}}
  static Future<CartActionApiResponse> updateCartItemQuantity({
    required String itemId,
    required int quantity,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/items/$itemId');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode({'quantity': quantity}))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return CartActionApiResponse.fromJson(body);
    } catch (e) {
      return CartActionApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update cart item quantity',
        ),
      );
    }
  }

  /// API: DELETE https://backend.chikitsakart.com/api/cart/items/{itemId}
  /// Response: {"success": true, "message": "Item removed from cart"}
  static Future<CartActionApiResponse> removeCartItem({
    required String itemId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/items/$itemId');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return CartActionApiResponse.fromJson(body);
    } catch (e) {
      return CartActionApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to remove item from cart',
        ),
      );
    }
  }

  /// API: DELETE https://backend.chikitsakart.com/api/cart/clear
  /// Response: {"success": true, "message": "Cart cleared"}
  static Future<CartActionApiResponse> clearCart({String? token}) async {
    final Uri url = Uri.parse('$baseUrl/clear');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return CartActionApiResponse.fromJson(body);
    } catch (e) {
      return CartActionApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to clear cart',
        ),
      );
    }
  }
}
