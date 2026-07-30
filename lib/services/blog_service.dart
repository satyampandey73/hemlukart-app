import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blog_model.dart';

class BlogService {
  static const String baseUrl = 'https://hospital.gntechnology.de/api/blogs';

  /// API: GET https://hospital.gntechnology.de/api/blogs
  static Future<BlogListApiResponse> getBlogs() async {
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
        return BlogListApiResponse.fromJson(body);
      } else {
        return BlogListApiResponse(
          success: false,
          blogs: [],
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return BlogListApiResponse(
        success: false,
        blogs: [],
        message: 'Failed to fetch blogs: $e',
      );
    }
  }

  /// API: GET https://hospital.gntechnology.de/api/blogs/{id}
  static Future<BlogDetailApiResponse> getBlogById(String id) async {
    final Uri url = Uri.parse('$baseUrl/$id');
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
        return BlogDetailApiResponse.fromJson(body);
      } else {
        return BlogDetailApiResponse(
          success: false,
          blog: null,
          message: 'Server returned status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return BlogDetailApiResponse(
        success: false,
        blog: null,
        message: 'Failed to fetch blog details: $e',
      );
    }
  }
}
