class CartItemData {
  final String id;
  final String cartId;
  final String productId;
  final String? skuId;
  final String? sellerId;
  final int quantity;
  final String? buyerTypeAtAdd;
  final double priceAtAdd;
  final double discountAtAdd;
  final bool savedForLater;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? productName;
  final String? skuCode;
  final String? skuName;
  final double mrp;
  final double price;
  final String? image;
  final List<String> images;

  CartItemData({
    required this.id,
    required this.cartId,
    required this.productId,
    this.skuId,
    this.sellerId,
    required this.quantity,
    this.buyerTypeAtAdd,
    required this.priceAtAdd,
    required this.discountAtAdd,
    required this.savedForLater,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.productName,
    this.skuCode,
    this.skuName,
    this.mrp = 0.0,
    this.price = 0.0,
    this.image,
    this.images = const [],
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    // 1. Resolve nested product or sku maps if returned by backend
    final productMap = json['product'] is Map<String, dynamic> ? json['product'] as Map<String, dynamic> : null;
    final skuMap = json['sku'] is Map<String, dynamic> ? json['sku'] as Map<String, dynamic> : null;

    // 2. Resolve images
    List<String> imgList = [];
    if (json['images'] is List) {
      imgList = (json['images'] as List).map((i) => i.toString().trim()).where((i) => i.isNotEmpty).toList();
    } else if (skuMap != null && skuMap['images'] is List) {
      imgList = (skuMap['images'] as List).map((i) => i.toString().trim()).where((i) => i.isNotEmpty).toList();
    } else if (productMap != null && productMap['images'] is List) {
      imgList = (productMap['images'] as List).map((i) => i.toString().trim()).where((i) => i.isNotEmpty).toList();
    }

    String? singleImg = json['image']?.toString();
    if (singleImg == null || singleImg.isEmpty) {
      singleImg = skuMap?['image']?.toString() ?? productMap?['image']?.toString();
    }
    if ((singleImg == null || singleImg.isEmpty) && imgList.isNotEmpty) {
      singleImg = imgList.first;
    }

    // 3. Resolve MRP
    double parsedMrp = 0.0;
    final rawMrp = json['mrp'] ?? skuMap?['mrp'] ?? productMap?['mrp'] ?? json['priceAtAdd'];
    if (rawMrp != null) {
      parsedMrp = rawMrp is num ? rawMrp.toDouble() : double.tryParse(rawMrp.toString()) ?? 0.0;
    }

    // 4. Resolve discount percentage
    double parsedDiscount = 0.0;
    final rawDisc = json['discount'] ?? json['discountAtAdd'] ?? skuMap?['consumerDiscount'] ?? skuMap?['doctorDiscount'];
    if (rawDisc != null) {
      parsedDiscount = rawDisc is num ? rawDisc.toDouble() : double.tryParse(rawDisc.toString()) ?? 0.0;
    }

    // 5. Resolve Selling Price
    double parsedPrice = 0.0;
    final rawPrice = json['price'] ?? skuMap?['price'];
    if (rawPrice != null) {
      parsedPrice = rawPrice is num ? rawPrice.toDouble() : double.tryParse(rawPrice.toString()) ?? 0.0;
    }
    final double rawPriceAtAdd = json['priceAtAdd'] is num
        ? (json['priceAtAdd'] as num).toDouble()
        : double.tryParse(json['priceAtAdd']?.toString() ?? '0.0') ?? 0.0;

    if (parsedPrice <= 0) {
      final double base = parsedMrp > 0 ? parsedMrp : rawPriceAtAdd;
      if (parsedDiscount > 0 && base > 0) {
        parsedPrice = (base - (base * parsedDiscount / 100.0)).clamp(0.0, base);
      } else {
        parsedPrice = base;
      }
    }

    final pName = json['productName']?.toString() ??
        productMap?['productName']?.toString() ??
        productMap?['name']?.toString();
    final sName = json['skuName']?.toString() ?? skuMap?['skuName']?.toString();
    final sCode = json['skuCode']?.toString() ?? skuMap?['skuCode']?.toString();

    return CartItemData(
      id: json['id']?.toString() ?? '',
      cartId: json['cartId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? productMap?['id']?.toString() ?? '',
      skuId: json['skuId']?.toString() ?? skuMap?['id']?.toString(),
      sellerId: json['sellerId']?.toString() ?? skuMap?['sellerId']?.toString() ?? productMap?['sellerId']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      buyerTypeAtAdd: json['buyerTypeAtAdd']?.toString(),
      priceAtAdd: rawPriceAtAdd > 0 ? rawPriceAtAdd : parsedPrice,
      discountAtAdd: parsedDiscount,
      mrp: parsedMrp,
      price: parsedPrice,
      savedForLater: json['savedForLater'] == true,
      isActive: json['isActive'] != false,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      productName: pName,
      skuCode: sCode,
      skuName: sName,
      image: singleImg,
      images: imgList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'productId': productId,
      'skuId': skuId,
      'sellerId': sellerId,
      'quantity': quantity,
      'buyerTypeAtAdd': buyerTypeAtAdd,
      'priceAtAdd': priceAtAdd,
      'discountAtAdd': discountAtAdd,
      'savedForLater': savedForLater,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (productName != null) 'productName': productName,
      if (skuCode != null) 'skuCode': skuCode,
      if (skuName != null) 'skuName': skuName,
      'mrp': mrp,
      'price': price,
      if (image != null) 'image': image,
      'images': images,
    };
  }
}

class CartDetails {
  final String id;
  final String? buyerType;
  final String? userId;
  final String? doctorId;
  final String? sessionId;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  CartDetails({
    required this.id,
    this.buyerType,
    this.userId,
    this.doctorId,
    this.sessionId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CartDetails.fromJson(Map<String, dynamic> json) {
    return CartDetails(
      id: json['id']?.toString() ?? '',
      buyerType: json['buyerType']?.toString(),
      userId: json['userId']?.toString(),
      doctorId: json['doctorId']?.toString(),
      sessionId: json['sessionId']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerType': buyerType,
      'userId': userId,
      'doctorId': doctorId,
      'sessionId': sessionId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class GetCartData {
  final CartDetails? cart;
  final List<CartItemData> items;

  GetCartData({this.cart, required this.items});

  factory GetCartData.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<CartItemData> itemList = [];
    if (rawItems is List) {
      itemList = rawItems
          .map((e) => CartItemData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return GetCartData(
      cart: json['cart'] != null && json['cart'] is Map<String, dynamic>
          ? CartDetails.fromJson(json['cart'] as Map<String, dynamic>)
          : null,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (cart != null) 'cart': cart!.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class GetCartApiResponse {
  final bool success;
  final GetCartData? data;
  final String? message;

  GetCartApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory GetCartApiResponse.fromJson(Map<String, dynamic> json) {
    return GetCartApiResponse(
      success: json['success'] == true,
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? GetCartData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data!.toJson(),
      if (message != null) 'message': message,
    };
  }
}

class AddToCartApiResponse {
  final bool success;
  final String message;
  final CartItemData? data;

  AddToCartApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddToCartApiResponse.fromJson(Map<String, dynamic> json) {
    return AddToCartApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CartItemData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class CartActionApiResponse {
  final bool success;
  final String message;
  final CartItemData? data;

  CartActionApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CartActionApiResponse.fromJson(Map<String, dynamic> json) {
    return CartActionApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CartItemData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
    };
  }
}
