class BannerModel {
  final String id;
  final String page;
  final String section;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String linkUrl;
  final bool isActive;
  final int sortOrder;
  final bool isDeleted;

  BannerModel({
    required this.id,
    required this.page,
    required this.section,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.linkUrl,
    required this.isActive,
    required this.sortOrder,
    required this.isDeleted,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      page: json['page'] ?? '',
      section: json['section'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      linkUrl: json['linkUrl'] ?? '',
      isActive: json['isActive'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class BannersApiResponse {
  final bool success;
  final List<BannerModel> banners;
  final String? message;

  BannersApiResponse({
    required this.success,
    required this.banners,
    this.message,
  });

  factory BannersApiResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> bannerList = json['banners'] ?? [];
    return BannersApiResponse(
      success: json['success'] ?? false,
      banners: bannerList
          .map((b) => BannerModel.fromJson(b as Map<String, dynamic>))
          .toList(),
      message: json['message'],
    );
  }
}
