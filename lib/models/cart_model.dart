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
  });

  factory CartItemData.fromJson(Map<String, dynamic> json) {
    return CartItemData(
      id: json['id']?.toString() ?? '',
      cartId: json['cartId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      skuId: json['skuId']?.toString(),
      sellerId: json['sellerId']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      buyerTypeAtAdd: json['buyerTypeAtAdd']?.toString(),
      priceAtAdd: json['priceAtAdd'] is num
          ? (json['priceAtAdd'] as num).toDouble()
          : double.tryParse(json['priceAtAdd']?.toString() ?? '0.0') ?? 0.0,
      discountAtAdd: json['discountAtAdd'] is num
          ? (json['discountAtAdd'] as num).toDouble()
          : double.tryParse(json['discountAtAdd']?.toString() ?? '0.0') ?? 0.0,
      savedForLater: json['savedForLater'] == true,
      isActive: json['isActive'] == true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      productName: json['productName']?.toString(),
      skuCode: json['skuCode']?.toString(),
      skuName: json['skuName']?.toString(),
      mrp: json['mrp'] is num
          ? (json['mrp'] as num).toDouble()
          : double.tryParse(json['mrp']?.toString() ?? '0.0') ?? 0.0,
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
