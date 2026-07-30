class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final num discount;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final int sortOrder;
  final String? createdByRole;
  final String? createdBySellerId;
  final String? createdByAdminId;
  final String? createdAt;
  final String? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.discount = 0,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    required this.sortOrder,
    this.createdByRole,
    this.createdBySellerId,
    this.createdByAdminId,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      discount: num.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      isActive: json['isActive'] == true,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      createdByRole: json['createdByRole']?.toString(),
      createdBySellerId: json['createdBySellerId']?.toString(),
      createdByAdminId: json['createdByAdminId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'discount': discount,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'sortOrder': sortOrder,
      'createdByRole': createdByRole,
      'createdBySellerId': createdBySellerId,
      'createdByAdminId': createdByAdminId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CategoriesApiResponse {
  final bool success;
  final List<CategoryModel> categories;
  final String? message;

  CategoriesApiResponse({
    required this.success,
    required this.categories,
    this.message,
  });

  factory CategoriesApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['categories'];
    List<CategoryModel> categoryList = [];
    if (rawList is List) {
      categoryList = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => CategoryModel.fromJson(item))
          .toList();
    }
    return CategoriesApiResponse(
      success: json['success'] == true,
      categories: categoryList,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'categories': categories.map((c) => c.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}
