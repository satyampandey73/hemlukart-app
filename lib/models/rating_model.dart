import 'doctor_model.dart';

class RatingUser {
  final String id;
  final String fullName;
  final String? profileImage;

  const RatingUser({
    required this.id,
    required this.fullName,
    this.profileImage,
  });

  factory RatingUser.fromJson(Map<String, dynamic> json) {
    return RatingUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'User',
      profileImage: json['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}

class RatingItem {
  final String id;
  final String userId;
  final String targetId;
  final String targetType;
  final int score;
  final String review;
  final String createdAt;
  final RatingUser? user;

  const RatingItem({
    required this.id,
    required this.userId,
    required this.targetId,
    required this.targetType,
    required this.score,
    required this.review,
    required this.createdAt,
    this.user,
  });

  factory RatingItem.fromJson(Map<String, dynamic> json) {
    return RatingItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? 'product',
      score: (json['score'] is num)
          ? (json['score'] as num).toInt()
          : int.tryParse(json['score']?.toString() ?? '5') ?? 5,
      review: json['review']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? RatingUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetId': targetId,
      'targetType': targetType,
      'score': score,
      'review': review,
      'createdAt': createdAt,
      if (user != null) 'user': user!.toJson(),
    };
  }
}

class RatingStats {
  final double averageScore;
  final int totalRatings;

  const RatingStats({
    required this.averageScore,
    required this.totalRatings,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    final rawAvg = json['averageScore'];
    double avg = 0.0;
    if (rawAvg is num) {
      avg = rawAvg.toDouble();
    } else if (rawAvg != null) {
      avg = double.tryParse(rawAvg.toString()) ?? 0.0;
    }

    final rawTotal = json['totalRatings'];
    int total = 0;
    if (rawTotal is int) {
      total = rawTotal;
    } else if (rawTotal is num) {
      total = rawTotal.toInt();
    } else if (rawTotal != null) {
      total = int.tryParse(rawTotal.toString()) ?? 0;
    }

    return RatingStats(
      averageScore: avg,
      totalRatings: total,
    );
  }
}

class AddRatingResponse {
  final bool success;
  final String message;
  final RatingItem? rating;

  const AddRatingResponse({
    required this.success,
    required this.message,
    this.rating,
  });

  factory AddRatingResponse.fromJson(Map<String, dynamic> json) {
    return AddRatingResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      rating: json['rating'] != null && json['rating'] is Map<String, dynamic>
          ? RatingItem.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
    );
  }
}

class GetRatingsResponse {
  final bool success;
  final String? message;
  final RatingStats? stats;
  final List<RatingItem> ratings;
  final dynamic targetDetails;

  const GetRatingsResponse({
    required this.success,
    this.message,
    this.stats,
    this.ratings = const [],
    this.targetDetails,
  });

  factory GetRatingsResponse.fromJson(Map<String, dynamic> json) {
    final List<RatingItem> list = [];
    if (json['ratings'] is List) {
      for (final item in json['ratings']) {
        if (item is Map<String, dynamic>) {
          list.add(RatingItem.fromJson(item));
        }
      }
    }

    RatingStats? parsedStats;
    if (json['stats'] != null && json['stats'] is Map<String, dynamic>) {
      parsedStats = RatingStats.fromJson(json['stats'] as Map<String, dynamic>);
    }

    return GetRatingsResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      stats: parsedStats,
      ratings: list,
      targetDetails: json['targetDetails'],
    );
  }

  ApiDoctor? get doctorDetails {
    if (targetDetails != null && targetDetails is Map<String, dynamic>) {
      try {
        return ApiDoctor.fromJson(targetDetails as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
