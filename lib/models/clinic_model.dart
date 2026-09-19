class ApiClinic {
  final String id;
  final String clinicName;
  final String? ownerId;
  final String? createdByAdminId;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? registrationNo;
  final List<String>? images;
  final String? about;
  final bool? isActive;
  final String? createdAt;
  final String? updatedAt;

  ApiClinic({
    required this.id,
    required this.clinicName,
    this.ownerId,
    this.createdByAdminId,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.registrationNo,
    this.images,
    this.about,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiClinic.fromJson(Map<String, dynamic> json) {
    List<String>? parsedImages;
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
      parsedImages = [json['image'].toString()];
    }

    return ApiClinic(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      clinicName: (json['clinicName'] ?? json['name'] ?? json['title'])?.toString() ?? 'Unnamed Clinic',
      ownerId: json['ownerId']?.toString(),
      createdByAdminId: json['createdByAdminId']?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['contact'])?.toString(),
      email: json['email']?.toString(),
      address: (json['address'] ?? json['location'])?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: (json['pincode'] ?? json['zipCode'] ?? json['zip'])?.toString(),
      registrationNo: (json['registrationNo'] ?? json['regNo'])?.toString(),
      images: parsedImages,
      about: (json['about'] ?? json['description'] ?? json['details'])?.toString(),
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['status']?.toString().toLowerCase() == 'active'),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicName': clinicName,
      'ownerId': ownerId,
      'createdByAdminId': createdByAdminId,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'registrationNo': registrationNo,
      'images': images,
      'about': about,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ClinicsApiResponse {
  final bool success;
  final List<ApiClinic> clinics;
  final Map<String, dynamic>? pagination;
  final String message;

  ClinicsApiResponse({
    required this.success,
    required this.clinics,
    this.pagination,
    this.message = '',
  });

  factory ClinicsApiResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['clinics'] ?? json['data'];
    return ClinicsApiResponse(
      success: json['success'] ?? true,
      clinics: rawList != null && rawList is List
          ? rawList
              .map((e) => ApiClinic.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      pagination: json['pagination'] as Map<String, dynamic>?,
      message: json['message']?.toString() ?? '',
    );
  }
}

class SingleClinicApiResponse {
  final bool success;
  final ApiClinic? clinic;
  final String message;

  SingleClinicApiResponse({
    required this.success,
    this.clinic,
    this.message = '',
  });

  factory SingleClinicApiResponse.fromJson(Map<String, dynamic> json) {
    bool isSuccess = json['success'] ?? false;
    ApiClinic? clinicObj;

    if (json['clinic'] != null && json['clinic'] is Map<String, dynamic>) {
      clinicObj = ApiClinic.fromJson(json['clinic'] as Map<String, dynamic>);
      isSuccess = true;
    } else if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      clinicObj = ApiClinic.fromJson(json['data'] as Map<String, dynamic>);
      isSuccess = true;
    } else if (json['id'] != null || json['_id'] != null || json['clinicName'] != null) {
      clinicObj = ApiClinic.fromJson(json);
      isSuccess = true;
    }

    return SingleClinicApiResponse(
      success: isSuccess,
      clinic: clinicObj,
      message: json['message']?.toString() ?? '',
    );
  }
}
