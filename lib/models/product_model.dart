import '../constants/app_state.dart';

class SkuVariantModel {
  final String type;
  final String value;

  SkuVariantModel({
    required this.type,
    required this.value,
  });

  factory SkuVariantModel.fromJson(Map<String, dynamic> json) {
    return SkuVariantModel(
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }
}

class ProductSkuModel {
  final String id;
  final String productId;
  final String skuCode;
  final String skuName;
  final List<dynamic> description;
  final List<SkuVariantModel> variants;
  final List<String> images;
  final String unitOfMeasure;
  final String typeOfPacking;
  final int packSize;
  final String packingMaterial;
  final String mrp;
  final String sellerDiscount;
  final String consumerDiscount;
  final bool consumerActive;
  final String doctorDiscount;
  final bool doctorActive;
  final int stockQuantity;
  final String batchNumber;
  final String expiryDate;
  final String storageConditions;
  final String lengthCm;
  final String widthCm;
  final String heightCm;
  final String productWeight;
  final String theoreticalWeight;
  final String shipmentWeight;
  final int processingTimeDays;
  final bool isActive;
  final bool isDeleted;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  ProductSkuModel({
    required this.id,
    required this.productId,
    required this.skuCode,
    required this.skuName,
    required this.description,
    required this.variants,
    required this.images,
    required this.unitOfMeasure,
    required this.typeOfPacking,
    required this.packSize,
    required this.packingMaterial,
    required this.mrp,
    required this.sellerDiscount,
    required this.consumerDiscount,
    required this.consumerActive,
    required this.doctorDiscount,
    required this.doctorActive,
    required this.stockQuantity,
    required this.batchNumber,
    required this.expiryDate,
    required this.storageConditions,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.productWeight,
    required this.theoreticalWeight,
    required this.shipmentWeight,
    required this.processingTimeDays,
    required this.isActive,
    required this.isDeleted,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductSkuModel.fromJson(Map<String, dynamic> json) {
    var rawVariants = json['variants'];
    List<SkuVariantModel> variantList = [];
    if (rawVariants is List) {
      variantList = rawVariants
          .map((v) => SkuVariantModel.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    var rawImages = json['images'];
    List<String> imageList = [];
    if (rawImages is List) {
      imageList = rawImages.map((i) => i.toString()).toList();
    }

    return ProductSkuModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      skuCode: json['skuCode']?.toString() ?? '',
      skuName: json['skuName']?.toString() ?? '',
      description: json['description'] is List ? json['description'] : [],
      variants: variantList,
      images: imageList,
      unitOfMeasure: json['unitOfMeasure']?.toString() ?? '',
      typeOfPacking: json['typeOfPacking']?.toString() ?? '',
      packSize: json['packSize'] is int
          ? json['packSize']
          : int.tryParse(json['packSize']?.toString() ?? '1') ?? 1,
      packingMaterial: json['packingMaterial']?.toString() ?? '',
      mrp: json['mrp']?.toString() ?? '0.00',
      sellerDiscount: json['sellerDiscount']?.toString() ?? '0.00',
      consumerDiscount: json['consumerDiscount']?.toString() ?? '0.00',
      consumerActive: json['consumerActive'] == true,
      doctorDiscount: json['doctorDiscount']?.toString() ?? '0.00',
      doctorActive: json['doctorActive'] == true,
      stockQuantity: json['stockQuantity'] is int
          ? json['stockQuantity']
          : int.tryParse(json['stockQuantity']?.toString() ?? '0') ?? 0,
      batchNumber: json['batchNumber']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString() ?? '',
      storageConditions: json['storageConditions']?.toString() ?? '',
      lengthCm: json['lengthCm']?.toString() ?? '0.00',
      widthCm: json['widthCm']?.toString() ?? '0.00',
      heightCm: json['heightCm']?.toString() ?? '0.00',
      productWeight: json['productWeight']?.toString() ?? '',
      theoreticalWeight: json['theoreticalWeight']?.toString() ?? '',
      shipmentWeight: json['shipmentWeight']?.toString() ?? '',
      processingTimeDays: json['processingTimeDays'] is int
          ? json['processingTimeDays']
          : int.tryParse(json['processingTimeDays']?.toString() ?? '1') ?? 1,
      isActive: json['isActive'] == true,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'skuCode': skuCode,
      'skuName': skuName,
      'description': description,
      'variants': variants.map((v) => v.toJson()).toList(),
      'images': images,
      'unitOfMeasure': unitOfMeasure,
      'typeOfPacking': typeOfPacking,
      'packSize': packSize,
      'packingMaterial': packingMaterial,
      'mrp': mrp,
      'sellerDiscount': sellerDiscount,
      'consumerDiscount': consumerDiscount,
      'consumerActive': consumerActive,
      'doctorDiscount': doctorDiscount,
      'doctorActive': doctorActive,
      'stockQuantity': stockQuantity,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
      'storageConditions': storageConditions,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'productWeight': productWeight,
      'theoreticalWeight': theoreticalWeight,
      'shipmentWeight': shipmentWeight,
      'processingTimeDays': processingTimeDays,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class ApiProductModel {
  final String id;
  final String productCode;
  final String productName;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final String categorySlug;
  final String subCategory;
  final bool prescriptionRequired;
  final String hsnSacCode;
  final String taxRate;
  final bool gmpCertified;
  final String manufacturerCountry;
  final String createdByRole;
  final String? createdBySellerId;
  final String? createdByAdminId;
  final bool isActive;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final List<ProductSkuModel> skus;
  final String? createdByName;

  ApiProductModel({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    required this.subCategory,
    required this.prescriptionRequired,
    required this.hsnSacCode,
    required this.taxRate,
    required this.gmpCertified,
    required this.manufacturerCountry,
    required this.createdByRole,
    this.createdBySellerId,
    this.createdByAdminId,
    required this.isActive,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    required this.skus,
    this.createdByName,
  });

  factory ApiProductModel.fromJson(Map<String, dynamic> json) {
    var rawSkus = json['skus'];
    List<ProductSkuModel> skuList = [];
    if (rawSkus is List) {
      skuList = rawSkus
          .map((s) => ProductSkuModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return ApiProductModel(
      id: json['id']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      subCategory: json['subCategory']?.toString() ?? '',
      prescriptionRequired: json['prescriptionRequired'] == true,
      hsnSacCode: json['hsnSacCode']?.toString() ?? '',
      taxRate: json['taxRate']?.toString() ?? '0.00',
      gmpCertified: json['gmpCertified'] == true,
      manufacturerCountry: json['manufacturerCountry']?.toString() ?? 'India',
      createdByRole: json['createdByRole']?.toString() ?? 'admin',
      createdBySellerId: json['createdBySellerId']?.toString(),
      createdByAdminId: json['createdByAdminId']?.toString(),
      isActive: json['isActive'] == true,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      skus: skuList,
      createdByName: json['createdByName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productCode': productCode,
      'productName': productName,
      'brandName': brandName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categorySlug': categorySlug,
      'subCategory': subCategory,
      'prescriptionRequired': prescriptionRequired,
      'hsnSacCode': hsnSacCode,
      'taxRate': taxRate,
      'gmpCertified': gmpCertified,
      'manufacturerCountry': manufacturerCountry,
      'createdByRole': createdByRole,
      'createdBySellerId': createdBySellerId,
      'createdByAdminId': createdByAdminId,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'skus': skus.map((s) => s.toJson()).toList(),
      'createdByName': createdByName,
    };
  }

  /// Converts this API product model into the standard app [Product]
  Product toProduct() {
    final bool hasSku = skus.isNotEmpty;
    final ProductSkuModel? primarySku = hasSku ? skus.first : null;

    final String img = (primarySku != null && primarySku.images.isNotEmpty)
        ? primarySku.images.first
        : 'assets/p1.png';

    final double mrpVal = primarySku != null
        ? (double.tryParse(primarySku.mrp) ?? 100.0)
        : 100.0;

    final double discountVal = primarySku != null
        ? (double.tryParse(primarySku.consumerDiscount) ?? 0.0)
        : 0.0;

    final double doctorDiscountVal = primarySku != null
        ? (double.tryParse(primarySku.doctorDiscount) ?? 0.0)
        : 0.0;

    final bool doctorActiveVal = primarySku?.doctorActive ?? true;
    final bool consumerActiveVal = primarySku?.consumerActive ?? true;

    // Calculated price after discount
    final double calculatedPrice = (mrpVal - discountVal).clamp(0.0, mrpVal);
    final double finalPrice = calculatedPrice > 0 ? calculatedPrice : mrpVal;

    final String brand = brandName.trim().isEmpty ? 'Wellness' : brandName.trim();
    final String category = categoryName.trim().isEmpty ? 'General' : categoryName.trim();

    final String desc = (primarySku != null && primarySku.storageConditions.isNotEmpty)
        ? 'Storage: ${primarySku.storageConditions}'
        : 'Quality certified medical & wellness product.';

    String potency = 'Standard';
    if (primarySku != null && primarySku.variants.isNotEmpty) {
      final v = primarySku.variants.first;
      potency = '${v.type}: ${v.value}';
    }

    String pack = '1 Unit';
    if (primarySku != null) {
      final String pPacking = primarySku.typeOfPacking.trim();
      final String pUom = primarySku.unitOfMeasure.trim();
      if (pPacking.isNotEmpty && pUom.isNotEmpty) {
        pack = '${primarySku.packSize} ($pUom) $pPacking';
      } else if (pPacking.isNotEmpty) {
        pack = '${primarySku.packSize} $pPacking';
      } else if (pUom.isNotEmpty) {
        pack = '${primarySku.packSize} $pUom';
      } else {
        pack = '${primarySku.packSize} Unit';
      }
      pack = _normalizePackDisplay(pack);
    }

    final bool isStockOut = primarySku != null && primarySku.stockQuantity <= 0;

    final List<ProductVariant> variantList = [];
    if (skus.isNotEmpty) {
      for (final sku in skus) {
        final double skuMrp = double.tryParse(sku.mrp) ?? mrpVal;
        final double skuDisc = double.tryParse(sku.consumerDiscount) ?? 0.0;
        final double skuDocDisc = double.tryParse(sku.doctorDiscount) ?? 0.0;
        final double skuPrice = (skuMrp - skuDisc).clamp(0.0, skuMrp);

        String packText = '';
        final String packing = sku.typeOfPacking.trim();
        final String uom = sku.unitOfMeasure.trim();
        if (packing.isNotEmpty && uom.isNotEmpty) {
          packText = '${sku.packSize} ($uom) $packing';
        } else if (packing.isNotEmpty) {
          packText = '${sku.packSize} $packing';
        } else if (uom.isNotEmpty) {
          packText = '${sku.packSize} $uom';
        } else if (sku.skuName.trim().isNotEmpty) {
          packText = _normalizePackDisplay(sku.skuName.trim());
        } else {
          packText = '${sku.packSize} Unit';
        }
        packText = _normalizePackDisplay(packText);

        variantList.add(
          ProductVariant(
            id: sku.id.isNotEmpty ? sku.id : id,
            packSize: packText.trim().isNotEmpty ? packText : _normalizePackDisplay(sku.skuName),
            price: skuPrice > 0 ? skuPrice : skuMrp,
            originalPrice: skuMrp,
            skuCode: sku.skuCode,
            isOutOfStock: sku.stockQuantity <= 0,
            doctorDiscount: skuDocDisc,
            doctorActive: sku.doctorActive,
            consumerDiscount: skuDisc,
            consumerActive: sku.consumerActive,
          ),
        );
      }
    }

    return Product(
      id: id,
      name: productName,
      brand: brand,
      image: img,
      price: finalPrice,
      originalPrice: mrpVal,
      rating: 4.5,
      reviewsCount: 42,
      isPrescriptionRequired: prescriptionRequired,
      isOutOfStock: isStockOut,
      category: category,
      description: desc,
      potency: potency,
      packSize: pack,
      flavour: 'Natural',
      doctorDiscount: doctorDiscountVal,
      doctorActive: doctorActiveVal,
      consumerDiscount: discountVal,
      consumerActive: consumerActiveVal,
      variants: variantList,
      skuId: (primarySku != null && primarySku.id.isNotEmpty) ? primarySku.id : null,
    );
  }
}

class ProductsApiResponse {
  final bool success;
  final List<ApiProductModel> products;
  final Map<String, dynamic>? pagination;
  final String? message;

  ProductsApiResponse({
    required this.success,
    required this.products,
    this.pagination,
    this.message,
  });

  factory ProductsApiResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['products'];
    List<ApiProductModel> productList = [];
    if (rawList is List) {
      productList = rawList
          .map((item) => ApiProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return ProductsApiResponse(
      success: json['success'] == true,
      products: productList,
      pagination: json['pagination'] is Map<String, dynamic>
          ? json['pagination']
          : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'products': products.map((p) => p.toJson()).toList(),
      if (pagination != null) 'pagination': pagination,
      if (message != null) 'message': message,
    };
  }
}

class SingleProductApiResponse {
  final bool success;
  final ApiProductModel? product;
  final List<ProductSkuModel> skus;
  final String? message;

  SingleProductApiResponse({
    required this.success,
    this.product,
    this.skus = const [],
    this.message,
  });

  factory SingleProductApiResponse.fromJson(Map<String, dynamic> json) {
    if (json['success'] == true && json['product'] is Map<String, dynamic>) {
      final Map<String, dynamic> prodMap =
          Map<String, dynamic>.from(json['product'] as Map);

      // Merge skus if provided separately at root level
      if (json['skus'] is List) {
        prodMap['skus'] = json['skus'];
      }

      final parsedProd = ApiProductModel.fromJson(prodMap);
      return SingleProductApiResponse(
        success: true,
        product: parsedProd,
        skus: parsedProd.skus,
      );
    }
    return SingleProductApiResponse(
      success: false,
      product: null,
      skus: const [],
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (product != null) 'product': product!.toJson(),
      'skus': skus.map((s) => s.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

/// Transforms pack strings formatted as "30 Bottle (ml)" or "30 Bottle (gm)"
/// into the standard "30 (ml) Bottle" or "30 (gm) Bottle".
String _normalizePackDisplay(String raw) {
  final trimmed = raw.trim();
  final regex = RegExp(r'^(\d+)\s+([A-Za-z]+)\s*\(([A-Za-z0-9]+)\)$');
  final match = regex.firstMatch(trimmed);
  if (match != null) {
    return '${match.group(1)} (${match.group(3)}) ${match.group(2)}';
  }
  return trimmed;
}

