import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner_model.dart';

class BannerService {
  static const String _baseUrl = 'https://backend.chikitsakart.com/api/banners';

  /// API: GET https://backend.chikitsakart.com/api/banners?page=home&section=hero
  static Future<BannersApiResponse> getHeroBanners() async {
    return _getBanners(page: 'home', section: 'hero');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=home&section=hero1
  static Future<BannersApiResponse> getHero1Banners() async {
    return _getBanners(page: 'home', section: 'hero1');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=home&section=hero2
  static Future<BannersApiResponse> getHero2Banners() async {
    return _getBanners(page: 'home', section: 'hero2');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=products&section=banner
  static Future<BannersApiResponse> getProductsBanners() async {
    return _getBanners(page: 'products', section: 'banner');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=product&section=detail+banner
  static Future<BannersApiResponse> getProductDetailBanners() async {
    return _getBanners(page: 'product', section: 'detail banner');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=medicine&section=banner
  static Future<BannersApiResponse> getMedicineBanners() async {
    return _getBanners(page: 'medicine', section: 'banner');
  }

  /// API: GET https://backend.chikitsakart.com/api/banners?page=medicine&section=banner+1
  static Future<BannersApiResponse> getMedicineBanner1() async {
    return _getBanners(page: 'medicine', section: 'banner 1');
  }

  static Future<BannersApiResponse> _getBanners({
    required String page,
    required String section,
  }) async {
    final Uri url = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'page': page, 'section': section});

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
        return BannersApiResponse.fromJson(body);
      } else {
        return BannersApiResponse(
          success: false,
          banners: [],
          message: 'Server returned error status: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BannersApiResponse(
        success: false,
        banners: [],
        message: 'Failed to fetch banners: $e',
      );
    }
  }
}
