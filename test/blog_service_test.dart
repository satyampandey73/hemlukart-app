import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/blog_model.dart';
import 'package:hemlukart_app/services/blog_service.dart';

void main() {
  test('BlogModel.fromJson parses single blog correctly', () {
    final json = {
      "id": "f3e395ee-738b-4aea-81f6-ffcdfc02394e",
      "title": "Smog:What Is It, Causes and ways To Protect Yourself From",
      "slug": "ayurvedic-tips-digestion",
      "image":
          "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785337576/blogs/ktvkt05js5k4g5ff9fph.png",
      "description":
          "Smog:What Is It, Causes and ways To Protect Yourself From",
      "authorName": "Dr. Anjali Sharma",
      "sortOrder": 1,
      "isActive": true,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2026-07-29T15:06:18.112Z",
      "updatedAt": "2026-07-29T15:06:18.112Z"
    };

    final blog = BlogModel.fromJson(json);

    expect(blog.id, "f3e395ee-738b-4aea-81f6-ffcdfc02394e");
    expect(blog.title, contains("Smog"));
    expect(blog.authorName, "Dr. Anjali Sharma");
    expect(blog.sortOrder, 1);
    expect(blog.isActive, true);
    expect(blog.isDeleted, false);
  });

  test('BlogListApiResponse.fromJson parses blog list payload correctly', () {
    final jsonResponse = {
      "success": true,
      "blogs": [
        {
          "id": "f3e395ee-738b-4aea-81f6-ffcdfc02394e",
          "title": "Smog:What Is It, Causes and ways To Protect Yourself From",
          "slug": "ayurvedic-tips-digestion",
          "image":
              "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785337576/blogs/ktvkt05js5k4g5ff9fph.png",
          "description":
              "Smog:What Is It, Causes and ways To Protect Yourself From",
          "authorName": "Dr. Anjali Sharma",
          "sortOrder": 1,
          "isActive": true,
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-07-29T15:06:18.112Z",
          "updatedAt": "2026-07-29T15:06:18.112Z"
        }
      ],
      "pagination": {"total": 1, "page": 1, "pages": 1}
    };

    final response = BlogListApiResponse.fromJson(jsonResponse);

    expect(response.success, true);
    expect(response.blogs.length, 1);
    expect(response.blogs.first.title, contains("Smog"));
  });

  test('BlogDetailApiResponse.fromJson parses single blog detail payload correctly', () {
    final jsonResponse = {
      "success": true,
      "blog": {
        "id": "f3e395ee-738b-4aea-81f6-ffcdfc02394e",
        "title": "Smog:What Is It, Causes and ways To Protect Yourself From",
        "slug": "ayurvedic-tips-digestion",
        "image":
            "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785337576/blogs/ktvkt05js5k4g5ff9fph.png",
        "description":
            "Smog:What Is It, Causes and ways To Protect Yourself From",
        "authorName": "Dr. Anjali Sharma",
        "sortOrder": 1,
        "isActive": true,
        "isDeleted": false,
        "deletedAt": null,
        "createdAt": "2026-07-29T15:06:18.112Z",
        "updatedAt": "2026-07-29T15:06:18.112Z"
      }
    };

    final response = BlogDetailApiResponse.fromJson(jsonResponse);

    expect(response.success, true);
    expect(response.blog, isNotNull);
    expect(response.blog?.authorName, "Dr. Anjali Sharma");
  });

  test('BlogService.getBlogs fetches live list API data', () async {
    final response = await BlogService.getBlogs();
    expect(response.success, true);
    expect(response.blogs, isNotEmpty);
  });

  test('BlogService.getBlogById fetches live detail API data', () async {
    final listResponse = await BlogService.getBlogs();
    expect(listResponse.success, true);
    expect(listResponse.blogs, isNotEmpty);

    final blogId = listResponse.blogs.first.id;
    final detailResponse = await BlogService.getBlogById(blogId);

    expect(detailResponse.success, true);
    expect(detailResponse.blog, isNotNull);
    expect(detailResponse.blog?.id, blogId);
  });
}
