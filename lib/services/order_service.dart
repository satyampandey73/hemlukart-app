import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';

class OrderService {
  static const String checkoutUrl = 'https://hospital.gntechnology.de/api/orders/checkout';
  static const String myOrdersUrl = 'https://hospital.gntechnology.de/api/orders/my';
  static const String orderDetailBaseUrl = 'https://hospital.gntechnology.de/api/orders';

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

  /// Process Checkout POST request
  /// Endpoint: POST https://hospital.gntechnology.de/api/orders/checkout
  static Future<CheckoutApiResponse> checkout({
    required String shippingAddressId,
    required String paymentMode,
    String paymentStatus = 'pending',
    String? token,
  }) async {
    final Uri url = Uri.parse(checkoutUrl);
    final Map<String, dynamic> payload = {
      'shippingAddressId': shippingAddressId.trim(),
      'paymentMode': paymentMode.trim().toLowerCase(),
      'paymentStatus': paymentStatus.trim().toLowerCase(),
    };

    try {
      final response = await http
          .post(
            url,
            headers: _buildHeaders(token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return CheckoutApiResponse.fromJson(body);
    } catch (e) {
      return CheckoutApiResponse(
        success: false,
        message: 'Failed to process checkout: $e',
      );
    }
  }

  /// GET My Orders
  /// Endpoint: GET https://hospital.gntechnology.de/api/orders/my
  static Future<MyOrdersApiResponse> getUsersOrders({
    String? token,
  }) async {
    final Uri url = Uri.parse(myOrdersUrl);
    try {
      final response = await http
          .get(
            url,
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return MyOrdersApiResponse.fromJson(body);
      } else {
        return MyOrdersApiResponse(
          success: false,
          data: [],
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MyOrdersApiResponse(
        success: false,
        data: [],
        message: 'Failed to fetch user orders: $e',
      );
    }
  }

  /// GET Single Order Detail by ID
  /// Endpoint: GET https://hospital.gntechnology.de/api/orders/:id
  static Future<SingleOrderDetailApiResponse> getOrderById({
    required String orderId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$orderDetailBaseUrl/$orderId');
    try {
      final response = await http
          .get(
            url,
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return SingleOrderDetailApiResponse.fromJson(body);
      } else {
        return SingleOrderDetailApiResponse(
          success: false,
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SingleOrderDetailApiResponse(
        success: false,
        message: 'Failed to fetch order details: $e',
      );
    }
  }
}
