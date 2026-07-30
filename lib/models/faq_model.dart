class FaqModel {
  final String id;
  final String? icon;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  FaqModel({
    required this.id,
    this.icon,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id']?.toString() ?? '',
      icon: json['icon']?.toString(),
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
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
      if (icon != null) 'icon': icon,
      'question': question,
      'answer': answer,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': deletedAt,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class FaqApiResponse {
  final bool success;
  final List<FaqModel> faqs;
  final String? message;

  FaqApiResponse({
    required this.success,
    required this.faqs,
    this.message,
  });

  factory FaqApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['faqs'];
    List<FaqModel> list = [];
    if (rawList is List) {
      list = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => FaqModel.fromJson(item))
          .toList();
    }
    return FaqApiResponse(
      success: json['success'] == true,
      faqs: list,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'faqs': faqs.map((f) => f.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}
