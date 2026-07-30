import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/brand_model.dart';
import 'package:hemlukart_app/services/brand_service.dart';

void main() {
  test('BrandModel.fromJson parses single brand correctly', () {
    final json = {
      "id": "9b6589fa-eeae-42be-b389-ae27249c3645",
      "name": "Sugar Free",
      "slug": "Sugar Free",
      "image":
          "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785326021/brands/qvjfe3bbvpksylyjqt8x.png",
      "sortOrder": 1,
      "isActive": true,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2026-07-29T11:53:42.660Z",
      "updatedAt": "2026-07-29T11:53:42.660Z"
    };

    final brand = BrandModel.fromJson(json);

    expect(brand.id, "9b6589fa-eeae-42be-b389-ae27249c3645");
    expect(brand.name, "Sugar Free");
    expect(brand.image, contains("cloudinary"));
    expect(brand.sortOrder, 1);
    expect(brand.isActive, true);
    expect(brand.isDeleted, false);
  });

  test('BrandApiResponse.fromJson parses full payload correctly', () {
    final jsonResponse = {
      "success": true,
      "brands": [
        {
          "id": "9b6589fa-eeae-42be-b389-ae27249c3645",
          "name": "Sugar Free",
          "slug": "Sugar Free",
          "image":
              "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785326021/brands/qvjfe3bbvpksylyjqt8x.png",
          "sortOrder": 1,
          "isActive": true,
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-07-29T11:53:42.660Z",
          "updatedAt": "2026-07-29T11:53:42.660Z"
        }
      ]
    };

    final response = BrandApiResponse.fromJson(jsonResponse);

    expect(response.success, true);
    expect(response.brands.length, 1);
    expect(response.brands.first.name, "Sugar Free");
  });

  test('BrandService.getBrands fetches live API data', () async {
    final response = await BrandService.getBrands();
    expect(response.success, true);
    expect(response.brands, isNotEmpty);
  });
}
