import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rating_model.dart';

class RatingService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/ratings';

  /// Add a rating/review
  /// API: POST https://hospital.gntechnology.de/api/ratings
  /// Payload:
  /// {
  ///   "targetId": "f80778a9-5988-48e6-8647-4b2a90b719d2",
  ///   "targetType": "product",
  ///   "score": 5,
  ///   "review": "Excellent product! Highly recommended."
  /// }
  static Future<AddRatingResponse> addRating({
    required String targetId,
    required String targetType,
    required int score,
    required String review,
    String? token,
  }) async {
    final Uri url = Uri.parse(baseUrl);
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({
              'targetId': targetId.trim(),
              'targetType': targetType.trim(),
              'score': score,
              'review': review.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return AddRatingResponse.fromJson(body);
      } else {
        try {
          final Map<String, dynamic> body = jsonDecode(response.body);
          return AddRatingResponse(
            success: body['success'] == true,
            message: body['message']?.toString() ??
                'Server returned status ${response.statusCode}',
          );
        } catch (_) {
          return AddRatingResponse(
            success: false,
            message: 'Server returned error status: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      return AddRatingResponse(
        success: false,
        message: 'Failed to submit rating: $e',
      );
    }
  }

  /// Get ratings for a target (e.g. product or doctor)
  /// API: GET https://hospital.gntechnology.de/api/ratings/{targetType}/{targetId}
  static Future<GetRatingsResponse> getRatings({
    required String targetType,
    required String targetId,
  }) async {
    final Uri url = Uri.parse('$baseUrl/$targetType/$targetId');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return GetRatingsResponse.fromJson(body);
      } else {
        return GetRatingsResponse(
          success: false,
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return GetRatingsResponse(
        success: false,
        message: 'Failed to fetch ratings: $e',
      );
    }
  }

  /// Get all ratings
  /// API: GET https://hospital.gntechnology.de/api/ratings
  static Future<GetRatingsResponse> getAllRatings() async {
    final Uri url = Uri.parse(baseUrl);
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return GetRatingsResponse.fromJson(body);
      } else {
        return GetRatingsResponse(
          success: false,
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return GetRatingsResponse(
        success: false,
        message: 'Failed to fetch all ratings: $e',
      );
    }
  }
}
