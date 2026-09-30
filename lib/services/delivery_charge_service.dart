import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliverySlab {
  final String id;
  final double minCartValue;
  final double maxCartValue;
  final double shippingCharge;
  final bool isActive;
  final int priority;

  DeliverySlab({
    required this.id,
    required this.minCartValue,
    required this.maxCartValue,
    required this.shippingCharge,
    required this.isActive,
    required this.priority,
  });

  factory DeliverySlab.fromJson(Map<String, dynamic> json) {
    return DeliverySlab(
      id: json['id']?.toString() ?? '',
      minCartValue: double.tryParse(json['minCartValue']?.toString() ?? '0') ?? 0.0,
      maxCartValue: double.tryParse(json['maxCartValue']?.toString() ?? '0') ?? 0.0,
      shippingCharge: double.tryParse(json['shippingCharge']?.toString() ?? '0') ?? 0.0,
      isActive: json['isActive'] == true,
      priority: json['priority'] is int ? json['priority'] : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
    );
  }
}

class DeliveryCalculationResult {
  final bool success;
  final double cartValue;
  final double shippingCharge;
  final bool isFreeDelivery;
  final String? message;
  final DeliverySlab? slab;

  DeliveryCalculationResult({
    required this.success,
    required this.cartValue,
    required this.shippingCharge,
    required this.isFreeDelivery,
    this.message,
    this.slab,
  });

  factory DeliveryCalculationResult.fromJson(Map<String, dynamic> json, double fallbackCartValue) {
    final double charge = double.tryParse(json['shippingCharge']?.toString() ?? '0') ?? 0.0;
    final bool free = json['isFreeDelivery'] == true || charge <= 0;
    final double cv = double.tryParse(json['cartValue']?.toString() ?? fallbackCartValue.toString()) ?? fallbackCartValue;
    DeliverySlab? matchedSlab;
    if (json['slab'] is Map<String, dynamic>) {
      matchedSlab = DeliverySlab.fromJson(json['slab']);
    }

    return DeliveryCalculationResult(
      success: json['success'] == true,
      cartValue: cv,
      shippingCharge: charge,
      isFreeDelivery: free,
      message: json['message']?.toString(),
      slab: matchedSlab,
    );
  }

  factory DeliveryCalculationResult.fallback(double cartValue, double charge) {
    return DeliveryCalculationResult(
      success: true,
      cartValue: cartValue,
      shippingCharge: charge,
      isFreeDelivery: charge <= 0,
      message: charge <= 0 ? 'Free Delivery' : null,
    );
  }
}

class DeliveryChargeService {
  static const String calculateUrl = 'https://backend.chikitsakart.com/api/delivery-charges/calculate';
  static const String slabsUrl = 'https://backend.chikitsakart.com/api/delivery-charges?isActive=true';

  static List<DeliverySlab> _cachedSlabs = [];
  static final Map<int, DeliveryCalculationResult> _cacheByRoundedValue = {};

  /// Calculate delivery charge for a cart value using the live API
  static Future<DeliveryCalculationResult> calculateDeliveryCharge(double cartValue) async {
    final int roundedKey = cartValue.round();
    if (_cacheByRoundedValue.containsKey(roundedKey)) {
      return _cacheByRoundedValue[roundedKey]!;
    }

    try {
      final uri = Uri.parse('$calculateUrl?cartValue=${cartValue.toStringAsFixed(2)}');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final result = DeliveryCalculationResult.fromJson(body, cartValue);
        _cacheByRoundedValue[roundedKey] = result;
        return result;
      }
    } catch (_) {}

    // Fallback using active slabs or standard business rule
    final fallbackCharge = calculateFallbackCharge(cartValue);
    final fallbackResult = DeliveryCalculationResult.fallback(cartValue, fallbackCharge);
    return fallbackResult;
  }

  /// Fetch and cache active delivery charge slabs
  static Future<List<DeliverySlab>> fetchActiveSlabs() async {
    try {
      final response = await http.get(
        Uri.parse(slabsUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['slabs'] is List) {
          _cachedSlabs = (body['slabs'] as List)
              .map((s) => DeliverySlab.fromJson(s as Map<String, dynamic>))
              .where((s) => s.isActive)
              .toList();
          return _cachedSlabs;
        }
      }
    } catch (_) {}

    return _cachedSlabs;
  }

  /// Calculates charge offline using cached slabs or active rule:
  /// - 0 - 500: ₹50
  /// - 500 - 700: ₹30
  /// - > 700: Free (₹0)
  static double calculateFallbackCharge(double cartValue) {
    if (cartValue <= 0) return 0.0;

    if (_cachedSlabs.isNotEmpty) {
      for (final slab in _cachedSlabs) {
        if (cartValue >= slab.minCartValue && cartValue <= slab.maxCartValue) {
          return slab.shippingCharge;
        }
      }
      // If above all slabs, free delivery
      final maxSlab = _cachedSlabs.map((s) => s.maxCartValue).fold(0.0, (a, b) => a > b ? a : b);
      if (cartValue > maxSlab) return 0.0;
    }

    if (cartValue < 500.0) {
      return 50.0;
    } else if (cartValue <= 700.0) {
      return 30.0;
    } else {
      return 0.0;
    }
  }

  /// Clear calculation cache
  static void clearCache() {
    _cacheByRoundedValue.clear();
  }
}
