class BlogModel {
  final String id;
  final String title;
  final String? slug;
  final String image;
  final String description;
  final String? authorName;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  BlogModel({
    required this.id,
    required this.title,
    this.slug,
    required this.image,
    required this.description,
    this.authorName,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      image: json['image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      authorName: json['authorName']?.toString(),
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
      'title': title,
      if (slug != null) 'slug': slug,
      'image': image,
      'description': description,
      if (authorName != null) 'authorName': authorName,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class BlogListApiResponse {
  final bool success;
  final List<BlogModel> blogs;
  final String? message;

  BlogListApiResponse({
    required this.success,
    required this.blogs,
    this.message,
  });

  factory BlogListApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['blogs'];
    List<BlogModel> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => BlogModel.fromJson(item))
          .toList();
    }
    return BlogListApiResponse(
      success: json['success'] == true,
      blogs: list,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'blogs': blogs.map((b) => b.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

class BlogDetailApiResponse {
  final bool success;
  final BlogModel? blog;
  final String? message;

  BlogDetailApiResponse({
    required this.success,
    this.blog,
    this.message,
  });

  factory BlogDetailApiResponse.fromJson(Map<String, dynamic> json) {
    return BlogDetailApiResponse(
      success: json['success'] == true,
      blog: json['blog'] is Map<String, dynamic>
          ? BlogModel.fromJson(json['blog'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (blog != null) 'blog': blog!.toJson(),
      if (message != null) 'message': message,
    };
  }
}
