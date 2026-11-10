import '../constants/app_state.dart';

class WishlistActionResponse {
  final bool success;
  final String message;
  final bool? isWishlisted;

  WishlistActionResponse({
    required this.success,
    required this.message,
    this.isWishlisted,
  });

  factory WishlistActionResponse.fromJson(Map<String, dynamic> json) {
    return WishlistActionResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      isWishlisted: json['isWishlisted'] is bool ? json['isWishlisted'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (isWishlisted != null) 'isWishlisted': isWishlisted,
    };
  }
}

typedef AddWishlistResponse = WishlistActionResponse;
typedef RemoveWishlistResponse = WishlistActionResponse;
typedef ToggleWishlistResponse = WishlistActionResponse;

class UserWishlistProductItem {
  final String id;
  final String productId;
  final String? productCode;
  final String? productName;
  final String? brandName;
  final String? variantId;
  final String? skuId;
  final String? skuName;
  final String? skuCode;
  final List<String> images;
  final double? mrp;
  final dynamic packSize;
  final String? unitOfMeasure;
  final int? stockQuantity;
  final String userId;
  final String? doctorId;
  final String? createdAt;

  UserWishlistProductItem({
    required this.id,
    required this.productId,
    this.productCode,
    this.productName,
    this.brandName,
    this.variantId,
    this.skuId,
    this.skuName,
    this.skuCode,
    this.images = const [],
    this.mrp,
    this.packSize,
    this.unitOfMeasure,
    this.stockQuantity,
    this.userId = '',
    this.doctorId,
    this.createdAt,
  });

  factory UserWishlistProductItem.fromJson(Map<String, dynamic> json) {
    List<String> imgList = [];
    if (json['images'] is List) {
      imgList = (json['images'] as List).map((i) => i.toString()).toList();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      imgList = [json['image'].toString()];
    }

    double? parsedMrp;
    if (json['mrp'] != null) {
      parsedMrp = json['mrp'] is num
          ? (json['mrp'] as num).toDouble()
          : double.tryParse(json['mrp'].toString());
    }

    int? parsedStock;
    if (json['stockQuantity'] != null) {
      parsedStock = json['stockQuantity'] is int
          ? json['stockQuantity'] as int
          : int.tryParse(json['stockQuantity'].toString());
    }

    return UserWishlistProductItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productCode: json['productCode']?.toString(),
      productName: json['productName']?.toString(),
      brandName: json['brandName']?.toString(),
      variantId: json['variantId']?.toString(),
      skuId: json['skuId']?.toString(),
      skuName: json['skuName']?.toString(),
      skuCode: json['skuCode']?.toString(),
      images: imgList,
      mrp: parsedMrp,
      packSize: json['packSize'],
      unitOfMeasure: json['unitOfMeasure']?.toString(),
      stockQuantity: parsedStock,
      userId: json['userId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'brandName': brandName,
      'variantId': variantId,
      'skuId': skuId,
      'skuName': skuName,
      'skuCode': skuCode,
      'images': images,
      'mrp': mrp,
      'packSize': packSize,
      'unitOfMeasure': unitOfMeasure,
      'stockQuantity': stockQuantity,
      'userId': userId,
      'doctorId': doctorId,
      'createdAt': createdAt,
    };
  }

  /// Converts this wishlist item to a standard [Product] for display and cart operations
  Product toProduct() {
    final double priceVal = (mrp != null && mrp! > 0) ? mrp! : 150.0;
    final String img = images.isNotEmpty ? images.first : 'assets/p1.png';
    final String pack = (skuName != null && skuName!.isNotEmpty)
        ? skuName!
        : (packSize != null ? '$packSize ${unitOfMeasure ?? ""}'.trim() : '1 Unit');

    final variant = ProductVariant(
      id: (skuId != null && skuId!.isNotEmpty) ? skuId! : id,
      packSize: pack,
      price: priceVal,
      originalPrice: priceVal,
      skuCode: skuCode,
      skuName: skuName,
      stockQuantity: stockQuantity ?? 10,
      isOutOfStock: (stockQuantity ?? 10) <= 0,
      images: images,
      unitOfMeasure: unitOfMeasure,
    );

    return Product(
      id: (skuId != null && skuId!.isNotEmpty) ? skuId! : id,
      productId: productId.isNotEmpty ? productId : id,
      name: (productName != null && productName!.isNotEmpty)
          ? productName!
          : 'Wishlist Medicine',
      brand: (brandName != null && brandName!.isNotEmpty) ? brandName! : 'Healthcare',
      image: img,
      price: priceVal,
      originalPrice: priceVal,
      rating: 4.8,
      reviewsCount: 10,
      category: 'General',
      description: 'Saved wishlist product.',
      potency: 'Standard',
      packSize: pack,
      flavour: 'Standard',
      skuId: skuId,
      skuCode: skuCode,
      skuName: skuName,
      selectedVariantId: variantId,
      stockQuantity: stockQuantity ?? 10,
      isOutOfStock: (stockQuantity ?? 10) <= 0,
      images: images,
      variants: [variant],
    );
  }
}

class UserWishlistProductsApiResponse {
  final bool success;
  final List<UserWishlistProductItem> data;
  final String? message;

  UserWishlistProductsApiResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory UserWishlistProductsApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'];
    List<UserWishlistProductItem> items = [];
    if (rawList is List) {
      items = rawList
          .map((item) =>
              UserWishlistProductItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return UserWishlistProductsApiResponse(
      success: json['success'] == true,
      data: items,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

class UserWishlistDoctorItem {
  final String id;
  final String targetDoctorId;
  final String userId;
  final String? wisherDoctorId;
  final String? createdAt;

  UserWishlistDoctorItem({
    required this.id,
    required this.targetDoctorId,
    required this.userId,
    this.wisherDoctorId,
    this.createdAt,
  });

  factory UserWishlistDoctorItem.fromJson(Map<String, dynamic> json) {
    return UserWishlistDoctorItem(
      id: json['id']?.toString() ?? '',
      targetDoctorId: json['targetDoctorId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      wisherDoctorId: json['wisherDoctorId']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetDoctorId': targetDoctorId,
      'userId': userId,
      'wisherDoctorId': wisherDoctorId,
      'createdAt': createdAt,
    };
  }
}

class UserWishlistDoctorsApiResponse {
  final bool success;
  final List<UserWishlistDoctorItem> data;
  final String? message;

  UserWishlistDoctorsApiResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory UserWishlistDoctorsApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'];
    List<UserWishlistDoctorItem> items = [];
    if (rawList is List) {
      items = rawList
          .map((item) =>
              UserWishlistDoctorItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return UserWishlistDoctorsApiResponse(
      success: json['success'] == true,
      data: items,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

