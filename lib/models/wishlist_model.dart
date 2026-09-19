class WishlistActionResponse {
  final bool success;
  final String message;

  WishlistActionResponse({
    required this.success,
    required this.message,
  });

  factory WishlistActionResponse.fromJson(Map<String, dynamic> json) {
    return WishlistActionResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}

typedef AddWishlistResponse = WishlistActionResponse;
typedef RemoveWishlistResponse = WishlistActionResponse;
typedef ToggleWishlistResponse = WishlistActionResponse;

class UserWishlistProductItem {
  final String id;
  final String productId;
  final String userId;
  final String? doctorId;
  final String? createdAt;
  final String? productName;

  UserWishlistProductItem({
    required this.id,
    required this.productId,
    required this.userId,
    this.doctorId,
    this.createdAt,
    this.productName,
  });

  factory UserWishlistProductItem.fromJson(Map<String, dynamic> json) {
    return UserWishlistProductItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      productName: json['productName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'doctorId': doctorId,
      'createdAt': createdAt,
      'productName': productName,
    };
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

