import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/category_model.dart';
import 'package:hemlukart_app/services/category_service.dart';

void main() {
  test('CategoryModel deserializes sample JSON with discount correctly', () {
    final sampleJson = {
      "id": "a2d54750-6631-4b5a-910d-dcff8f8fefa8",
      "name": "Final Testgffdgsgr",
      "slug": "final-testggddadf",
      "icon": "",
      "discount": 5,
      "isActive": true,
      "isDeleted": false,
      "deletedAt": null,
      "sortOrder": 0,
      "createdByRole": "admin",
      "createdBySellerId": null,
      "createdByAdminId": "c1ca650a-bd21-4e9e-933b-f3147a50d334",
      "createdAt": "2026-07-30T07:21:25.685Z",
      "updatedAt": "2026-07-30T07:21:25.685Z"
    };

    final category = CategoryModel.fromJson(sampleJson);
    expect(category.id, "a2d54750-6631-4b5a-910d-dcff8f8fefa8");
    expect(category.name, "Final Testgffdgsgr");
    expect(category.slug, "final-testggddadf");
    expect(category.discount, 5);
    expect(category.isActive, isTrue);
    expect(category.isDeleted, isFalse);
    expect(category.sortOrder, 0);
    expect(category.createdByRole, "admin");
    expect(category.createdByAdminId, "c1ca650a-bd21-4e9e-933b-f3147a50d334");
  });

  test('CategoriesApiResponse deserializes full API payload', () {
    final sampleResponse = {
      "success": true,
      "categories": [
        {
          "id": "97ebb13c-dcf7-4fe9-806c-3b1629b3989d",
          "name": "Zepto",
          "slug": "zepto",
          "icon": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1783020615/categories/icons/category-icon-1783020612738.jpg",
          "discount": 0,
          "isActive": true,
          "isDeleted": false,
          "sortOrder": 8
        },
        {
          "id": "a2d54750-6631-4b5a-910d-dcff8f8fefa8",
          "name": "Final Testgffdgsgr",
          "slug": "final-testggddadf",
          "icon": "",
          "discount": 5,
          "isActive": true,
          "isDeleted": false,
          "sortOrder": 0
        }
      ]
    };

    final response = CategoriesApiResponse.fromJson(sampleResponse);
    expect(response.success, isTrue);
    expect(response.categories.length, 2);
    expect(response.categories[0].name, 'Zepto');
    expect(response.categories[0].discount, 0);
    expect(response.categories[1].name, 'Final Testgffdgsgr');
    expect(response.categories[1].discount, 5);
  });

  test('CategoryService.getCategories fetches live API data', () async {
    final response = await CategoryService.getCategories();
    expect(response.success, isTrue);
    expect(response.categories, isNotEmpty);
  });
}
