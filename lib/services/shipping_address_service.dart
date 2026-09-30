import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipping_address_model.dart';
import 'api_helper.dart';

class ShippingAddressService {
  static const String baseUrl =
      'https://backend.chikitsakart.com/api/shipping-addresses';

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

  /// Get Shipping Addresses
  /// API: GET https://backend.chikitsakart.com/api/shipping-addresses
  static Future<ShippingAddressesApiResponse> getShippingAddresses({
    String? token,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return ShippingAddressesApiResponse.fromJson(body);
      } else {
        return ShippingAddressesApiResponse(
          success: false,
          data: [],
          message: 'Server returned status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ShippingAddressesApiResponse(
        success: false,
        data: [],
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to fetch shipping addresses',
        ),
      );
    }
  }

  /// Add Shipping Address
  /// API: POST https://backend.chikitsakart.com/api/shipping-addresses
  static Future<ShippingAddressApiResponse> addShippingAddress({
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
    String? token,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    final Map<String, dynamic> payload = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'addressLine': addressLine.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'isDefault': isDefault,
    };
    if (landmark != null && landmark.trim().isNotEmpty) {
      payload['landmark'] = landmark.trim();
    }

    try {
      final response = await http
          .post(url, headers: _buildHeaders(token), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return ShippingAddressApiResponse.fromJson(body);
    } catch (e) {
      return ShippingAddressApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to add shipping address',
        ),
      );
    }
  }

  /// Update Shipping Address
  /// API: PUT https://backend.chikitsakart.com/api/shipping-addresses/:id
  static Future<ShippingAddressApiResponse> updateShippingAddress({
    required String id,
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? landmark,
    bool isDefault = false,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$id');
    final Map<String, dynamic> payload = {
      'fullName': fullName.trim(),
      'phone': phone.trim(),
      'addressLine': addressLine.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'isDefault': isDefault,
    };
    if (landmark != null && landmark.trim().isNotEmpty) {
      payload['landmark'] = landmark.trim();
    }

    try {
      final response = await http
          .put(url, headers: _buildHeaders(token), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return ShippingAddressApiResponse.fromJson(body);
    } catch (e) {
      return ShippingAddressApiResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to update shipping address',
        ),
      );
    }
  }

  /// Delete Shipping Address
  /// API: DELETE https://backend.chikitsakart.com/api/shipping-addresses/:id
  static Future<ShippingAddressActionResponse> deleteShippingAddress({
    required String id,
    String? token,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$id');
    try {
      final response = await http
          .delete(url, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> body = jsonDecode(response.body);
      return ShippingAddressActionResponse.fromJson(body);
    } catch (e) {
      return ShippingAddressActionResponse(
        success: false,
        message: ApiHelper.getReadableErrorMessage(
          e,
          fallback: 'Failed to delete shipping address',
        ),
      );
    }
  }
}
