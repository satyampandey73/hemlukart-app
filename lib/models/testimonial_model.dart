class TestimonialModel {
  final String id;
  final String name;
  final String image;
  final int rating;
  final String testimonial;
  final bool isVerified;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  TestimonialModel({
    required this.id,
    required this.name,
    required this.image,
    required this.rating,
    required this.testimonial,
    required this.isVerified,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      rating: json['rating'] is int
          ? json['rating']
          : (num.tryParse(json['rating']?.toString() ?? '5')?.toInt() ?? 5),
      testimonial: json['testimonial']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
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
      'image': image,
      'rating': rating,
      'testimonial': testimonial,
      'isVerified': isVerified,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class TestimonialApiResponse {
  final bool success;
  final List<TestimonialModel> testimonials;
  final String? message;

  TestimonialApiResponse({
    required this.success,
    required this.testimonials,
    this.message,
  });

  factory TestimonialApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['testimonials'];
    List<TestimonialModel> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => TestimonialModel.fromJson(item))
          .toList();
    }
    return TestimonialApiResponse(
      success: json['success'] == true,
      testimonials: list,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'testimonials': testimonials.map((t) => t.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}
