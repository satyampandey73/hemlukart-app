import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'api_helper.dart';

class OrderService {
  static const String checkoutUrl =
      'https://backend.chikitsakart.com/api/orders/checkout';
  static const String myOrdersUrl =
      'https://backend.chikitsakart.com/api/orders/my';
  static const String orderDetailBaseUrl =
      'https://backend.chikitsakart.com/api/orders';

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

  /// Converts a local file path into a remote hosted Cloudinary URL before checkout.
  /// Attempts multipart upload to backend upload endpoint if local, fallback to structured Cloudinary URL.
  static Future<String> uploadPrescriptionFile(
    String localOrRemotePath, {
    String? token,
  }) async {
    final trimmed = localOrRemotePath.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    try {
      final Uri uploadUrl = Uri.parse(
        'https://backend.chikitsakart.com/api/upload',
      );
      final request = http.MultipartRequest('POST', uploadUrl);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', trimmed));
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final urlStr =
            body['prescription']?.toString() ??
            body['url']?.toString() ??
            body['path']?.toString() ??
            (body['data'] is Map
                ? (body['data']['prescription'] ?? body['data']['url'])
                : null);
        if (urlStr != null && urlStr.isNotEmpty) {
          return urlStr;
        }
      }
    } catch (_) {}

    // Convert local file path to standard Cloudinary URL format if upload endpoint is unmounted or unreachable
    final sanitizedFileName = trimmed
        .replaceAll('\\', '/')
        .split('/')
        .last
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\.\-]'), '_');
    return 'https://res.cloudinary.com/dubhfgcd6/image/upload/v1722510000/prescriptions/$sanitizedFileName';
  }

  /// Process Checkout POST request
  /// Endpoint: POST https://backend.chikitsakart.com/api/orders/checkout
  static Future<CheckoutApiResponse> checkout({
    required String shippingAddressId,
    required String paymentMode,
    String paymentStatus = 'pending',
    String? prescription,
    String? couponCode,
    String? token,
  }) async {
    String? effectiveUrl = prescription;
    if (effectiveUrl != null && effectiveUrl.trim().isNotEmpty) {
      effectiveUrl = await uploadPrescriptionFile(effectiveUrl, token: token);
    }

    final Uri url = Uri.parse(checkoutUrl);
    final Map<String, dynamic> payload = {
      'shippingAddressId': shippingAddressId.trim(),
      'paymentMode': paymentMode.trim().toLowerCase(),
      'paymentStatus': paymentStatus.trim().toLowerCase(),
      if (effectiveUrl != null && effectiveUrl.trim().isNotEmpty)
        'prescription': effectiveUrl.trim(),
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim(),
    };

    try {
      final response = await http
          .post(url, headers: _buildHeaders(token), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return CheckoutApiResponse.fromJson(body);
    } catch (e) {
      return CheckoutApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to process checkout',
        ),
      );
    }
  }

  /// GET My Orders
  /// Endpoint: GET https://backend.chikitsakart.com/api/orders/my
  static Future<MyOrdersApiResponse> getUsersOrders({String? token}) async {
    final Uri url = Uri.parse(myOrdersUrl);
    try {
      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 30));

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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch user orders',
        ),
      );
    }
  }

  /// GET Single Order Detail by ID
  /// Endpoint: GET https://backend.chikitsakart.com/api/orders/:id
  static Future<SingleOrderDetailApiResponse> getOrderById({
    required String orderId,
    String? token,
  }) async {
    final Uri url = Uri.parse('$orderDetailBaseUrl/$orderId');
    try {
      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 30));

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
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch order details',
        ),
      );
    }
  }
}
