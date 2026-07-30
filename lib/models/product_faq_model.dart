class ProductFaqModel {
  final String id;
  final String productId;
  final String question;
  final String answer;
  final String? source;
  final String? askedByUserId;
  final String? answeredByRole;
  final String? answeredByAdminId;
  final String? answeredBySellerId;
  final String? answeredAt;
  final bool isApproved;
  final String? approvedByAdminId;
  final String? approvedAt;
  final bool isActive;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  ProductFaqModel({
    required this.id,
    required this.productId,
    required this.question,
    required this.answer,
    this.source,
    this.askedByUserId,
    this.answeredByRole,
    this.answeredByAdminId,
    this.answeredBySellerId,
    this.answeredAt,
    required this.isApproved,
    this.approvedByAdminId,
    this.approvedAt,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductFaqModel.fromJson(Map<String, dynamic> json) {
    return ProductFaqModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      source: json['source']?.toString(),
      askedByUserId: json['askedByUserId']?.toString(),
      answeredByRole: json['answeredByRole']?.toString(),
      answeredByAdminId: json['answeredByAdminId']?.toString(),
      answeredBySellerId: json['answeredBySellerId']?.toString(),
      answeredAt: json['answeredAt']?.toString(),
      isApproved: json['isApproved'] == true,
      approvedByAdminId: json['approvedByAdminId']?.toString(),
      approvedAt: json['approvedAt']?.toString(),
      isActive: json['isActive'] == true,
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder']
          : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'question': question,
      'answer': answer,
      if (source != null) 'source': source,
      if (askedByUserId != null) 'askedByUserId': askedByUserId,
      if (answeredByRole != null) 'answeredByRole': answeredByRole,
      if (answeredByAdminId != null) 'answeredByAdminId': answeredByAdminId,
      if (answeredBySellerId != null) 'answeredBySellerId': answeredBySellerId,
      if (answeredAt != null) 'answeredAt': answeredAt,
      'isApproved': isApproved,
      if (approvedByAdminId != null) 'approvedByAdminId': approvedByAdminId,
      if (approvedAt != null) 'approvedAt': approvedAt,
      'isActive': isActive,
      'sortOrder': sortOrder,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class ProductFaqsApiResponse {
  final bool success;
  final List<ProductFaqModel> faqs;
  final String? message;

  ProductFaqsApiResponse({
    required this.success,
    required this.faqs,
    this.message,
  });

  factory ProductFaqsApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['faqs'];
    List<ProductFaqModel> faqList = [];
    if (rawList is List) {
      faqList = rawList
          .map((item) => ProductFaqModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return ProductFaqsApiResponse(
      success: json['success'] == true,
      faqs: faqList,
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

class AskProductFaqResponse {
  final bool success;
  final String? message;
  final ProductFaqModel? faq;

  AskProductFaqResponse({
    required this.success,
    this.message,
    this.faq,
  });

  factory AskProductFaqResponse.fromJson(Map<String, dynamic> json) {
    return AskProductFaqResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      faq: json['faq'] is Map<String, dynamic>
          ? ProductFaqModel.fromJson(json['faq'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (faq != null) 'faq': faq!.toJson(),
    };
  }
}
