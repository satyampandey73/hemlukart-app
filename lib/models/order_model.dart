import '../constants/app_state.dart';

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

class CheckoutOrderDetails {
  final String id;
  final String orderNo;
  final String buyerType;
  final String customerId;
  final String? doctorId;
  final String? cartId;
  final String? shippingAddressId;
  final String? deliveryName;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryPincode;
  final String? deliveryInstruction;
  final String paymentMode;
  final String paymentStatus;
  final String? paymentProvider;
  final String? paymentReference;
  final String? paidAt;
  final String orderStatus;
  final String? couponId;
  final String? couponCode;
  final double couponDiscount;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingCharge;
  final double totalAmount;
  final double codAmount;
  final bool prescriptionRequired;
  final String? prescriptionUrl;
  final String? note;
  final String createdAt;
  final String updatedAt;
  final String? customerName;
  final String? doctorName;
  final String? buyerName;

  CheckoutOrderDetails({
    required this.id,
    required this.orderNo,
    required this.buyerType,
    required this.customerId,
    this.doctorId,
    this.cartId,
    this.shippingAddressId,
    this.deliveryName,
    this.deliveryPhone,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryPincode,
    this.deliveryInstruction,
    required this.paymentMode,
    required this.paymentStatus,
    this.paymentProvider,
    this.paymentReference,
    this.paidAt,
    required this.orderStatus,
    this.couponId,
    this.couponCode,
    required this.couponDiscount,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.shippingCharge,
    required this.totalAmount,
    required this.codAmount,
    required this.prescriptionRequired,
    this.prescriptionUrl,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.customerName,
    this.doctorName,
    this.buyerName,
  });

  factory CheckoutOrderDetails.fromJson(Map<String, dynamic> json) {
    return CheckoutOrderDetails(
      id: json['id']?.toString() ?? '',
      orderNo: json['orderNo']?.toString() ?? '',
      buyerType: json['buyerType']?.toString() ?? 'user',
      customerId: json['customerId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString(),
      cartId: json['cartId']?.toString(),
      shippingAddressId: json['shippingAddressId']?.toString(),
      deliveryName: json['deliveryName']?.toString(),
      deliveryPhone: json['deliveryPhone']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      deliveryCity: json['deliveryCity']?.toString(),
      deliveryState: json['deliveryState']?.toString(),
      deliveryPincode: json['deliveryPincode']?.toString(),
      deliveryInstruction: json['deliveryInstruction']?.toString(),
      paymentMode: json['paymentMode']?.toString() ?? 'cod',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      paymentProvider: json['paymentProvider']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      paidAt: json['paidAt']?.toString(),
      orderStatus: json['orderStatus']?.toString() ?? 'placed',
      couponId: json['couponId']?.toString(),
      couponCode: json['couponCode']?.toString(),
      couponDiscount: _parseDouble(json['couponDiscount']),
      subtotal: _parseDouble(json['subtotal']),
      discountAmount: _parseDouble(json['discountAmount']),
      taxAmount: _parseDouble(json['taxAmount']),
      shippingCharge: _parseDouble(json['shippingCharge']),
      totalAmount: _parseDouble(json['totalAmount']),
      codAmount: _parseDouble(json['codAmount']),
      prescriptionRequired: json['prescriptionRequired'] == true,
      prescriptionUrl: json['prescriptionUrl']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      doctorName: json['doctorName']?.toString(),
      buyerName: json['buyerName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'buyerType': buyerType,
      'customerId': customerId,
      'doctorId': doctorId,
      'cartId': cartId,
      'shippingAddressId': shippingAddressId,
      'deliveryName': deliveryName,
      'deliveryPhone': deliveryPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryCity': deliveryCity,
      'deliveryState': deliveryState,
      'deliveryPincode': deliveryPincode,
      'deliveryInstruction': deliveryInstruction,
      'paymentMode': paymentMode,
      'paymentStatus': paymentStatus,
      'paymentProvider': paymentProvider,
      'paymentReference': paymentReference,
      'paidAt': paidAt,
      'orderStatus': orderStatus,
      'couponId': couponId,
      'couponCode': couponCode,
      'couponDiscount': couponDiscount.toStringAsFixed(2),
      'subtotal': subtotal.toStringAsFixed(2),
      'discountAmount': discountAmount.toStringAsFixed(2),
      'taxAmount': taxAmount.toStringAsFixed(2),
      'shippingCharge': shippingCharge.toStringAsFixed(2),
      'totalAmount': totalAmount.toStringAsFixed(2),
      'codAmount': codAmount.toStringAsFixed(2),
      'prescriptionRequired': prescriptionRequired,
      'prescriptionUrl': prescriptionUrl,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'customerName': customerName,
      'doctorName': doctorName,
      'buyerName': buyerName,
    };
  }
}

class CheckoutOrderItem {
  final String? id;
  final String orderId;
  final String productId;
  final String? skuId;
  final String? sellerId;
  final String? buyerTypeAtPurchase;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double tax;
  final double itemTotal;
  final String status;
  final String? createdAt;
  final String? updatedAt;
  final String? sellerName;

  CheckoutOrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    this.skuId,
    this.sellerId,
    this.buyerTypeAtPurchase,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.tax,
    required this.itemTotal,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.sellerName,
  });

  factory CheckoutOrderItem.fromJson(Map<String, dynamic> json) {
    return CheckoutOrderItem(
      id: json['id']?.toString(),
      orderId: json['orderId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      skuId: json['skuId']?.toString(),
      sellerId: json['sellerId']?.toString(),
      buyerTypeAtPurchase: json['buyerTypeAtPurchase']?.toString(),
      productName: json['productName']?.toString() ?? 'Product',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: _parseDouble(json['unitPrice']),
      discount: _parseDouble(json['discount']),
      tax: _parseDouble(json['tax']),
      itemTotal: _parseDouble(json['itemTotal']),
      status: json['status']?.toString() ?? 'placed',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      sellerName: json['sellerName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'skuId': skuId,
      'sellerId': sellerId,
      'buyerTypeAtPurchase': buyerTypeAtPurchase,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice.toStringAsFixed(2),
      'discount': discount.toStringAsFixed(2),
      'tax': tax.toStringAsFixed(2),
      'itemTotal': itemTotal.toStringAsFixed(2),
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'sellerName': sellerName,
    };
  }
}

class CheckoutData {
  final CheckoutOrderDetails order;
  final List<CheckoutOrderItem> items;

  CheckoutData({
    required this.order,
    required this.items,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    return CheckoutData(
      order: CheckoutOrderDetails.fromJson(
        json['order'] is Map<String, dynamic> ? json['order'] : {},
      ),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CheckoutOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  Order toOrder(List<Product> availableProducts) {
    final List<CartItem> cartItems = items.map((item) {
      final matchingProd = availableProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(
          id: item.productId,
          name: item.productName,
          brand: item.sellerName ?? 'Seller',
          image: 'assets/img2.png',
          price: item.unitPrice,
          originalPrice: item.unitPrice + item.discount,
          rating: 4.5,
          reviewsCount: 10,
          category: 'General',
          description: '',
        ),
      );
      return CartItem(
        product: matchingProd,
        quantity: item.quantity,
      );
    }).toList();

    String formattedAddress = '';
    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) {
      formattedAddress = [
        order.deliveryAddress,
        order.deliveryCity,
        order.deliveryState,
        order.deliveryPincode
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return Order(
      id: order.id.isNotEmpty ? order.id : order.orderNo,
      items: cartItems,
      totalAmount: order.totalAmount,
      discount: order.discountAmount,
      status: order.orderStatus.isNotEmpty
          ? '${order.orderStatus[0].toUpperCase()}${order.orderStatus.substring(1)}'
          : 'Placed',
      orderDate: order.createdAt.isNotEmpty ? order.createdAt : 'Just now',
      orderNo: order.orderNo,
      paymentMode: order.paymentMode,
      deliveryAddress: formattedAddress,
    );
  }
}

class CheckoutApiResponse {
  final bool success;
  final String message;
  final CheckoutData? data;

  CheckoutApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CheckoutApiResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? CheckoutData.fromJson(json['data'])
          : null,
    );
  }
}

class MyOrderItem {
  final CheckoutOrderDetails orderDetails;
  final List<CheckoutOrderItem> items;

  MyOrderItem({
    required this.orderDetails,
    required this.items,
  });

  factory MyOrderItem.fromJson(Map<String, dynamic> json) {
    final orderDetails = CheckoutOrderDetails.fromJson(json);
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => CheckoutOrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MyOrderItem(
      orderDetails: orderDetails,
      items: itemsList,
    );
  }

  Order toOrder(List<Product> availableProducts) {
    final List<CartItem> cartItems = items.map((item) {
      final matchingProd = availableProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(
          id: item.productId,
          name: item.productName,
          brand: item.sellerName ?? 'Seller',
          image: 'assets/img2.png',
          price: item.unitPrice,
          originalPrice: item.unitPrice + item.discount,
          rating: 4.5,
          reviewsCount: 10,
          category: 'General',
          description: '',
        ),
      );
      return CartItem(
        product: matchingProd,
        quantity: item.quantity,
      );
    }).toList();

    String formattedAddress = '';
    if (orderDetails.deliveryAddress != null && orderDetails.deliveryAddress!.isNotEmpty) {
      formattedAddress = [
        orderDetails.deliveryAddress,
        orderDetails.deliveryCity,
        orderDetails.deliveryState,
        orderDetails.deliveryPincode
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return Order(
      id: orderDetails.id.isNotEmpty ? orderDetails.id : orderDetails.orderNo,
      items: cartItems,
      totalAmount: orderDetails.totalAmount,
      discount: orderDetails.discountAmount,
      status: orderDetails.orderStatus.isNotEmpty
          ? '${orderDetails.orderStatus[0].toUpperCase()}${orderDetails.orderStatus.substring(1)}'
          : 'Placed',
      orderDate: orderDetails.createdAt.isNotEmpty ? orderDetails.createdAt : 'Just now',
      orderNo: orderDetails.orderNo,
      paymentMode: orderDetails.paymentMode,
      deliveryAddress: formattedAddress,
    );
  }
}

class MyOrdersApiResponse {
  final bool success;
  final String? message;
  final List<MyOrderItem> data;

  MyOrdersApiResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory MyOrdersApiResponse.fromJson(Map<String, dynamic> json) {
    return MyOrdersApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MyOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderHistoryItem {
  final String id;
  final String orderId;
  final String status;
  final String note;
  final String changedBy;
  final String createdAt;

  OrderHistoryItem({
    required this.id,
    required this.orderId,
    required this.status,
    required this.note,
    required this.changedBy,
    required this.createdAt,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderHistoryItem(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'placed',
      note: json['note']?.toString() ?? '',
      changedBy: json['changedBy']?.toString() ?? 'user',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'status': status,
      'note': note,
      'changedBy': changedBy,
      'createdAt': createdAt,
    };
  }
}

class SingleOrderDetailData {
  final CheckoutOrderDetails order;
  final List<CheckoutOrderItem> items;
  final List<OrderHistoryItem> history;

  SingleOrderDetailData({
    required this.order,
    required this.items,
    required this.history,
  });

  factory SingleOrderDetailData.fromJson(Map<String, dynamic> json) {
    return SingleOrderDetailData(
      order: CheckoutOrderDetails.fromJson(
        json['order'] is Map<String, dynamic> ? json['order'] : {},
      ),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CheckoutOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => OrderHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Order toOrder(List<Product> availableProducts) {
    final List<CartItem> cartItems = items.map((item) {
      final matchingProd = availableProducts.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(
          id: item.productId,
          name: item.productName,
          brand: item.sellerName ?? 'Seller',
          image: 'assets/img2.png',
          price: item.unitPrice,
          originalPrice: item.unitPrice + item.discount,
          rating: 4.5,
          reviewsCount: 10,
          category: 'General',
          description: '',
        ),
      );
      return CartItem(
        product: matchingProd,
        quantity: item.quantity,
      );
    }).toList();

    String formattedAddress = '';
    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) {
      formattedAddress = [
        order.deliveryAddress,
        order.deliveryCity,
        order.deliveryState,
        order.deliveryPincode
      ].where((e) => e != null && e.isNotEmpty).join(', ');
    }

    return Order(
      id: order.id.isNotEmpty ? order.id : order.orderNo,
      items: cartItems,
      totalAmount: order.totalAmount,
      discount: order.discountAmount,
      status: order.orderStatus.isNotEmpty
          ? '${order.orderStatus[0].toUpperCase()}${order.orderStatus.substring(1)}'
          : 'Placed',
      orderDate: order.createdAt.isNotEmpty ? order.createdAt : 'Just now',
      orderNo: order.orderNo,
      paymentMode: order.paymentMode,
      deliveryAddress: formattedAddress,
    );
  }
}

class SingleOrderDetailApiResponse {
  final bool success;
  final String? message;
  final SingleOrderDetailData? data;

  SingleOrderDetailApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SingleOrderDetailApiResponse.fromJson(Map<String, dynamic> json) {
    return SingleOrderDetailApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? SingleOrderDetailData.fromJson(json['data'])
          : null,
    );
  }
}
