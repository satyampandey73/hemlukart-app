class UserModel {
  final String id;
  final String fullName;
  final String mobile;
  final String whatsappNumber;
  final String email;
  final String role;
  final String? profileImage;
  final bool isMobileVerified;
  final bool isActive;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.whatsappNumber,
    required this.email,
    required this.role,
    this.profileImage,
    required this.isMobileVerified,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      mobile: json['mobile'] ?? '',
      whatsappNumber: json['whatsappNumber'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      profileImage: json['profileImage'] as String?,
      isMobileVerified: json['isMobileVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastLoginAt: json['lastLoginAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobile': mobile,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'role': role,
      'profileImage': profileImage,
      'isMobileVerified': isMobileVerified,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class SendOtpResponse {
  final bool success;
  final String message;
  final String? otp;

  SendOtpResponse({
    required this.success,
    required this.message,
    this.otp,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      otp: json['otp']?.toString(),
    );
  }
}

class VerifyOtpRegisterResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  VerifyOtpRegisterResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory VerifyOtpRegisterResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] as String?,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class UserProfileResponse {
  final bool success;
  final String? message;
  final UserModel? user;

  UserProfileResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
