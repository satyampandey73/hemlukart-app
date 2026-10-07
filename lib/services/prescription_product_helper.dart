import 'package:flutter/foundation.dart';
import '../constants/app_state.dart';
import '../services/product_service.dart';

class PrescriptionProductHelper {
  static final Map<String, Product> _productCache = {};

  /// Extracts the product ID from a medication map or object if present
  static String? extractProductId(dynamic med) {
    if (med == null) return null;
    if (med is Map) {
      dynamic pid = med['productId'] ??
          med['product_id'] ??
          med['product'] ??
          med['productDetails'] ??
          med['storeProductId'] ??
          med['storeId'];

      if (pid is Map) {
        pid = pid['_id'] ?? pid['id'] ?? pid['productId'];
      }
      if (pid != null) {
        final str = pid.toString().trim();
        if (str.isNotEmpty &&
            str.toLowerCase() != 'null' &&
            str.toLowerCase() != 'undefined') {
          return str;
        }
      }

      // If item is explicitly marked as in store or store product
      if (med['inStore'] == true ||
          med['isStoreProduct'] == true ||
          med['availableInStore'] == true ||
          med['storeAvailable'] == true) {
        final alt = med['_id'] ?? med['id'] ?? med['name'];
        if (alt != null && alt.toString().trim().isNotEmpty) {
          return alt.toString().trim();
        }
      }
    }
    return null;
  }

  /// Alias for extractProductId
  static String? getProductId(dynamic med) => extractProductId(med);

  /// Determines if a medication item is linked to a store product
  static bool isMedicationInStore(dynamic med) {
    if (med == null) return false;
    if (med is Map) {
      if (med['inStore'] == true ||
          med['isStoreProduct'] == true ||
          med['availableInStore'] == true ||
          med['storeAvailable'] == true) {
        return true;
      }
      if (med['inStore'] == false ||
          med['isStoreProduct'] == false ||
          med['availableInStore'] == false ||
          med['storeAvailable'] == false) {
        return false;
      }
      final pid = extractProductId(med);
      return pid != null && pid.isNotEmpty;
    }
    return false;
  }

  /// Resolve product from a medication map or object
  static Future<Product?> getProductFromMed(dynamic med) async {
    final pid = extractProductId(med);
    if (pid == null) return null;
    final name = med is Map ? med['name']?.toString() : null;
    final price = med is Map
        ? (med['price'] is num
            ? (med['price'] as num).toDouble()
            : double.tryParse(med['price']?.toString() ?? ''))
        : null;
    final img = med is Map
        ? (med['image']?.toString() ?? med['imageUrl']?.toString())
        : null;
    final dosage = med is Map ? (med['dosage']?.toString() ?? med['dosageForm']?.toString()) : null;
    return getOrFetchProduct(
      productId: pid,
      fallbackName: name,
      fallbackPrice: price,
      fallbackImage: img,
      fallbackDosageForm: dosage,
    );
  }

  /// Retrieves a product from memory cache or fetches it from API
  static Future<Product?> getOrFetchProduct({
    required String productId,
    String? fallbackName,
    double? fallbackPrice,
    String? fallbackImage,
    String? fallbackDosageForm,
  }) async {
    final trimmedId = productId.trim();
    if (trimmedId.isEmpty) return null;

    if (_productCache.containsKey(trimmedId)) {
      return _productCache[trimmedId];
    }

    try {
      final res = await ProductService.getProductById(trimmedId);
      if (res.success && res.product != null) {
        final prod = res.product!.toProduct();
        _productCache[trimmedId] = prod;
        return prod;
      }
    } catch (e) {
      debugPrint('[PrescriptionProductHelper] Error resolving product $trimmedId: $e');
    }

    // Build fallback product so user can immediately add to cart and order
    final fallback = Product(
      id: trimmedId,
      name: fallbackName?.isNotEmpty == true ? fallbackName! : 'Prescribed Medicine',
      brand: 'Hemlukart',
      image: fallbackImage?.isNotEmpty == true ? fallbackImage! : 'assets/p1.png',
      price: fallbackPrice ?? 150.0,
      originalPrice: fallbackPrice ?? 150.0,
      rating: 4.5,
      reviewsCount: 1,
      category: 'Prescription',
      description: 'Prescribed medication',
      potency: 'Standard',
      packSize: fallbackDosageForm ?? '1 Unit',
      flavour: 'Natural',
    );
    _productCache[trimmedId] = fallback;
    return fallback;
  }

  /// Store a known product in cache
  static void cacheProduct(Product product) {
    _productCache[product.id] = product;
  }
}
