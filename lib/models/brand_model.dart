class BrandModel {
  final String id;
  final String name;
  final String? slug;
  final String image;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    this.slug,
    required this.image,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      image: json['image']?.toString() ?? '',
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : (num.tryParse(json['sortOrder']?.toString() ?? '0')?.toInt() ?? 0),
      isActive: json['isActive'] == true,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (slug != null) 'slug': slug,
      'image': image,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class BrandApiResponse {
  final bool success;
  final List<BrandModel> brands;
  final String? message;

  BrandApiResponse({
    required this.success,
    required this.brands,
    this.message,
  });

  factory BrandApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['brands'];
    List<BrandModel> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => BrandModel.fromJson(item))
          .toList();
    }
    return BrandApiResponse(
      success: json['success'] == true,
      brands: list,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'brands': brands.map((b) => b.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}
