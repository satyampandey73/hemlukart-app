import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/product_model.dart';
import 'package:hemlukart_app/services/product_service.dart';

void main() {
  test('ApiProductModel deserializes sample product JSON correctly', () {
    final sampleJson = {
      "id": "bcebcbee-106e-4c54-a575-8f406931b94d",
      "productCode": "ADM-PRD-00018",
      "productName": "updated product",
      "brandName": "Brand ANme ",
      "categoryId": "35d62575-7f10-409d-955e-b1dfb172f2f3",
      "categoryName": "sakshi_singh",
      "categorySlug": "sakshi-singh",
      "subCategory": "cfsds",
      "prescriptionRequired": false,
      "hsnSacCode": "dvsv",
      "taxRate": "12.00",
      "gmpCertified": true,
      "manufacturerCountry": "India",
      "createdByRole": "admin",
      "createdBySellerId": null,
      "createdByAdminId": "c1ca650a-bd21-4e9e-933b-f3147a50d334",
      "isActive": true,
      "isDeleted": false,
      "createdAt": "2026-07-03T17:15:07.218Z",
      "updatedAt": "2026-07-13T14:16:58.682Z",
      "skus": [
        {
          "id": "e11963db-ff99-4115-b9f8-1b1c64572b20",
          "productId": "bcebcbee-106e-4c54-a575-8f406931b94d",
          "skuCode": "ADM-PRD-00018-SKU-001",
          "skuName": "dsfds",
          "description": [],
          "variants": [
            {
              "type": "Potencysdffsd",
              "value": "12vd"
            }
          ],
          "images": [
            "https://res.cloudinary.com/dubhfgcd6/image/upload/v1783098906/products/sku-images/sku-1783098905026-TravelBookings.webp"
          ],
          "unitOfMeasure": "ml",
          "typeOfPacking": "Bottle",
          "packSize": 8,
          "packingMaterial": "glass",
          "mrp": "8.00",
          "sellerDiscount": "2.00",
          "consumerDiscount": "0.00",
          "consumerActive": true,
          "doctorDiscount": "1.00",
          "doctorActive": true,
          "stockQuantity": 1,
          "batchNumber": "3f",
          "expiryDate": "20/08/2026",
          "storageConditions": "sdfs",
          "lengthCm": "0.00",
          "widthCm": "0.00",
          "heightCm": "0.00",
          "productWeight": "23",
          "theoreticalWeight": "",
          "shipmentWeight": "",
          "processingTimeDays": 1,
          "isActive": true,
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-07-03T17:15:07.293Z",
          "updatedAt": "2026-07-03T17:15:07.293Z"
        }
      ],
      "createdByName": "Admin"
    };

    final apiProd = ApiProductModel.fromJson(sampleJson);
    expect(apiProd.id, "bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(apiProd.productName, "updated product");
    expect(apiProd.brandName, "Brand ANme ");
    expect(apiProd.categoryName, "sakshi_singh");
    expect(apiProd.skus.length, 1);
    expect(apiProd.skus.first.mrp, "8.00");
    expect(apiProd.skus.first.images.first, contains("cloudinary.com"));

    // Test conversion to standard Product object
    final product = apiProd.toProduct();
    expect(product.id, "bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(product.name, "updated product");
    expect(product.brand, "Brand ANme");
    expect(product.price, 8.0);
    expect(product.originalPrice, 8.0);
    expect(product.image, contains("cloudinary.com"));
    expect(product.isOutOfStock, false);
  });

  test('ProductsApiResponse deserializes root payload', () {
    final samplePayload = {
      "success": true,
      "products": [
        {
          "id": "231313b6-87e9-4668-b31f-9f30c349c79c",
          "productCode": "187B27-PRD-00015",
          "productName": "Ashwagandha",
          "brandName": "Dabur",
          "categoryId": "ab4301e5-1849-41b6-9e5d-719f28c9b943",
          "categoryName": "Homeopathic",
          "categorySlug": "homeopathic",
          "subCategory": "",
          "prescriptionRequired": false,
          "hsnSacCode": "HSN",
          "taxRate": "12.00",
          "gmpCertified": true,
          "manufacturerCountry": "India",
          "createdByRole": "seller",
          "isActive": true,
          "isDeleted": false,
          "skus": []
        }
      ],
      "pagination": {
        "total": 8,
        "page": 1,
        "pages": 1
      }
    };

    final response = ProductsApiResponse.fromJson(samplePayload);
    expect(response.success, isTrue);
    expect(response.products.length, 1);
    expect(response.products[0].productName, 'Ashwagandha');
    expect(response.products[0].brandName, 'Dabur');
  });

  test('ProductService.getProducts handles optional categoryId parameter', () async {
    // Calling getProducts with categoryId parameter
    final result = await ProductService.getProducts(
      categoryId: '35d62575-7f10-409d-955e-b1dfb172f2f3',
    );
    expect(result, isA<ProductsApiResponse>());
  });

  test('ProductService.getProducts handles optional search parameter', () async {
    // Calling getProducts with search parameter
    final result = await ProductService.getProducts(
      search: 'Ashwagandha',
    );
    expect(result, isA<ProductsApiResponse>());
  });

  test('SingleProductApiResponse deserializes single product GET payload', () {
    final singleProductJson = {
      "success": true,
      "product": {
        "id": "bcebcbee-106e-4c54-a575-8f406931b94d",
        "productCode": "ADM-PRD-00018",
        "productName": "updated product",
        "brandName": "Brand ANme ",
        "categoryId": "35d62575-7f10-409d-955e-b1dfb172f2f3",
        "subCategory": "cfsds",
        "prescriptionRequired": false,
        "hsnSacCode": "dvsv",
        "taxRate": "12.00",
        "gmpCertified": true,
        "manufacturerCountry": "India",
        "createdByRole": "admin",
        "isActive": true,
        "isDeleted": false
      },
      "skus": [
        {
          "id": "e11963db-ff99-4115-b9f8-1b1c64572b20",
          "productId": "bcebcbee-106e-4c54-a575-8f406931b94d",
          "skuCode": "ADM-PRD-00018-SKU-001",
          "skuName": "dsfds",
          "variants": [],
          "images": [
            "https://res.cloudinary.com/dubhfgcd6/image/upload/v1783098906/products/sku-images/sku-1783098905026-TravelBookings.webp"
          ],
          "unitOfMeasure": "ml",
          "typeOfPacking": "Bottle",
          "packSize": 8,
          "mrp": "8.00",
          "sellerDiscount": "2.00",
          "consumerDiscount": "0.00",
          "stockQuantity": 1,
          "isActive": true,
          "isDeleted": false
        }
      ]
    };

    final response = SingleProductApiResponse.fromJson(singleProductJson);
    expect(response.success, isTrue);
    expect(response.product, isNotNull);
    expect(response.product!.id, "bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(response.product!.productName, "updated product");
    expect(response.skus.length, 1);
    expect(response.skus.first.mrp, "8.00");

    final convertedProd = response.product!.toProduct();
    expect(convertedProd.id, "bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(convertedProd.price, 8.0);
  });

  test('ProductService.getProductById executes API call correctly', () async {
    final response = await ProductService.getProductById("bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(response, isA<SingleProductApiResponse>());
  });
}
