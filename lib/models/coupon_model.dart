class CouponModel {
  final String id;
  final String code;
  final String name;
  final String type; // 'percentage' or 'fixed'
  final double value;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int usageLimit;
  final int usedCount;
  final String? createdAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.isActive,
    this.startDate,
    this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    this.createdAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'percentage',
      value: _parseDouble(json['value']),
      minOrderAmount: _parseDouble(json['minOrderAmount']),
      maxDiscountAmount: _parseDouble(json['maxDiscountAmount']),
      isActive: json['isActive'] == true,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      usageLimit: _parseInt(json['usageLimit']),
      usedCount: _parseInt(json['usedCount']),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
      'value': value.toStringAsFixed(2),
      'minOrderAmount': minOrderAmount.toStringAsFixed(2),
      'maxDiscountAmount': maxDiscountAmount.toStringAsFixed(2),
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'createdAt': createdAt,
    };
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  /// Calculates discount amount for a given order subtotal
  double calculateDiscount(double subtotal) {
    if (!isActive) return 0.0;
    if (subtotal < minOrderAmount) return 0.0;

    double discount = 0.0;
    if (type.toLowerCase() == 'percentage') {
      discount = subtotal * (value / 100.0);
      if (maxDiscountAmount > 0 && discount > maxDiscountAmount) {
        discount = maxDiscountAmount;
      }
    } else {
      discount = value;
      if (discount > subtotal) {
        discount = subtotal;
      }
    }
    return discount;
  }

  /// Checks whether coupon is valid for a given subtotal
  bool isValidForOrder(double subtotal) {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (expiryDate != null && now.isAfter(expiryDate!)) return false;
    if (usageLimit > 0 && usedCount >= usageLimit) return false;
    if (subtotal < minOrderAmount) return false;
    return true;
  }
}

class CouponsApiResponse {
  final bool success;
  final String message;
  final List<CouponModel> data;

  CouponsApiResponse({
    required this.success,
    this.message = '',
    required this.data,
  });

  factory CouponsApiResponse.fromJson(Map<String, dynamic> json) {
    List<CouponModel> couponsList = [];
    if (json['data'] is List) {
      couponsList = (json['data'] as List)
          .map((item) => CouponModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return CouponsApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: couponsList,
    );
  }
}
