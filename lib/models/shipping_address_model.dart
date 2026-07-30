class ShippingAddressModel {
  final String id;
  final String ownerType;
  final String? userId;
  final String? doctorId;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final String? createdAt;
  final String? updatedAt;

  ShippingAddressModel({
    required this.id,
    required this.ownerType,
    this.userId,
    this.doctorId,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      id: json['id']?.toString() ?? '',
      ownerType: json['ownerType']?.toString() ?? 'user',
      userId: json['userId']?.toString(),
      doctorId: json['doctorId']?.toString(),
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      landmark: json['landmark']?.toString(),
      isDefault: json['isDefault'] == true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerType': ownerType,
      'userId': userId,
      'doctorId': doctorId,
      'fullName': fullName,
      'phone': phone,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      if (landmark != null) 'landmark': landmark,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get formattedAddress {
    final List<String> parts = [
      addressLine,
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!,
      '$city, $state $pincode',
    ];
    return parts.where((p) => p.trim().isNotEmpty).join('\n');
  }

  ShippingAddressModel copyWith({
    String? id,
    String? ownerType,
    String? userId,
    String? doctorId,
    String? fullName,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return ShippingAddressModel(
      id: id ?? this.id,
      ownerType: ownerType ?? this.ownerType,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ShippingAddressesApiResponse {
  final bool success;
  final List<ShippingAddressModel> data;
  final String? message;

  ShippingAddressesApiResponse({
    required this.success,
    required this.data,
    this.message,
  });

  factory ShippingAddressesApiResponse.fromJson(Map<String, dynamic> json) {
    List<ShippingAddressModel> items = [];
    if (json['data'] != null && json['data'] is List) {
      items = (json['data'] as List)
          .map((item) => ShippingAddressModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return ShippingAddressesApiResponse(
      success: json['success'] == true,
      data: items,
      message: json['message']?.toString(),
    );
  }
}

class ShippingAddressApiResponse {
  final bool success;
  final ShippingAddressModel? data;
  final String? message;

  ShippingAddressApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ShippingAddressApiResponse.fromJson(Map<String, dynamic> json) {
    return ShippingAddressApiResponse(
      success: json['success'] == true,
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? ShippingAddressModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}

class ShippingAddressActionResponse {
  final bool success;
  final String message;

  ShippingAddressActionResponse({
    required this.success,
    required this.message,
  });

  factory ShippingAddressActionResponse.fromJson(Map<String, dynamic> json) {
    return ShippingAddressActionResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}
