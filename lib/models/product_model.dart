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
  final String skuUuid;
  final String productId;
  final String skuCode;
  final String skuName;
  final String variantId;
  final String variantName;
  final List<dynamic> description;
  final List<SkuVariantModel> variants;
  final List<String> images;
  final String unitOfMeasure;
  final String typeOfPacking;
  final int packSize;
  final String packingMaterial;
  final String mrp;
  final double masterMrp;
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
  final String? sellerId;

  ProductSkuModel({
    required this.id,
    required this.skuUuid,
    required this.productId,
    required this.skuCode,
    required this.skuName,
    this.variantId = '',
    this.variantName = '',
    required this.description,
    required this.variants,
    required this.images,
    required this.unitOfMeasure,
    required this.typeOfPacking,
    required this.packSize,
    required this.packingMaterial,
    required this.mrp,
    this.masterMrp = 0.0,
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
    this.sellerId,
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
      imageList = rawImages.map((i) => i.toString().trim()).where((i) => i.isNotEmpty).toList();
    }

    final sId = json['id']?.toString() ?? json['skuUuid']?.toString() ?? '';
    final sUuid = json['skuUuid']?.toString() ?? sId;

    return ProductSkuModel(
      id: sId,
      skuUuid: sUuid,
      productId: json['productId']?.toString() ?? '',
      skuCode: json['skuCode']?.toString().trim() ?? '',
      skuName: json['skuName']?.toString().trim() ?? '',
      variantId: json['variantId']?.toString().trim() ?? '',
      variantName: json['variantName']?.toString().trim() ?? '',
      description: json['description'] is List ? json['description'] : [],
      variants: variantList,
      images: imageList,
      unitOfMeasure: json['unitOfMeasure']?.toString().trim() ?? '',
      typeOfPacking: json['typeOfPacking']?.toString().trim() ?? '',
      packSize: json['packSize'] is int
          ? json['packSize']
          : int.tryParse(json['packSize']?.toString() ?? '1') ?? 1,
      packingMaterial: json['packingMaterial']?.toString().trim() ?? '',
      mrp: json['mrp']?.toString() ?? '0.00',
      masterMrp: json['masterMrp'] is num
          ? (json['masterMrp'] as num).toDouble()
          : double.tryParse(json['masterMrp']?.toString() ?? '0.0') ?? 0.0,
      sellerDiscount: json['sellerDiscount']?.toString() ?? '0.00',
      consumerDiscount: json['consumerDiscount']?.toString() ?? '0.00',
      consumerActive: json['consumerActive'] != false,
      doctorDiscount: json['doctorDiscount']?.toString() ?? '0.00',
      doctorActive: json['doctorActive'] != false,
      stockQuantity: json['stockQuantity'] is int
          ? json['stockQuantity']
          : int.tryParse(json['stockQuantity']?.toString() ?? '0') ?? 0,
      batchNumber: json['batchNumber']?.toString().trim() ?? '',
      expiryDate: json['expiryDate']?.toString().trim() ?? '',
      storageConditions: json['storageConditions']?.toString().trim() ?? '',
      lengthCm: json['lengthCm']?.toString() ?? '0.00',
      widthCm: json['widthCm']?.toString() ?? '0.00',
      heightCm: json['heightCm']?.toString() ?? '0.00',
      productWeight: json['productWeight']?.toString().trim() ?? '',
      theoreticalWeight: json['theoreticalWeight']?.toString().trim() ?? '',
      shipmentWeight: json['shipmentWeight']?.toString().trim() ?? '',
      processingTimeDays: json['processingTimeDays'] is int
          ? json['processingTimeDays']
          : int.tryParse(json['processingTimeDays']?.toString() ?? '1') ?? 1,
      isActive: json['isActive'] != false,
      isDeleted: json['isDeleted'] == true,
      deletedAt: json['deletedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      sellerId: json['sellerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skuUuid': skuUuid,
      'productId': productId,
      'skuCode': skuCode,
      'skuName': skuName,
      'variantId': variantId,
      'variantName': variantName,
      'description': description,
      'variants': variants.map((v) => v.toJson()).toList(),
      'images': images,
      'unitOfMeasure': unitOfMeasure,
      'typeOfPacking': typeOfPacking,
      'packSize': packSize,
      'packingMaterial': packingMaterial,
      'mrp': mrp,
      'masterMrp': masterMrp,
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

class ApiProductVariantModel {
  final String id;
  final String variantName;
  final String strength;
  final String dosageForm;
  final String description;
  final String? createdByRole;
  final String? sellerId;
  final String? sellerName;
  final List<ProductSkuModel> skus;

  ApiProductVariantModel({
    required this.id,
    required this.variantName,
    required this.strength,
    required this.dosageForm,
    this.description = '',
    this.createdByRole,
    this.sellerId,
    this.sellerName,
    required this.skus,
  });

  factory ApiProductVariantModel.fromJson(Map<String, dynamic> json) {
    final vId = json['id']?.toString().trim() ?? '';
    final vName = json['variantName']?.toString().trim() ?? '';
    var rawSkus = json['skus'];
    List<ProductSkuModel> skuList = [];
    if (rawSkus is List) {
      skuList = rawSkus.map((s) {
        final Map<String, dynamic> sMap = Map<String, dynamic>.from(s as Map);
        sMap['variantId'] ??= vId;
        sMap['variantName'] ??= vName;
        return ProductSkuModel.fromJson(sMap);
      }).toList();
    }
    return ApiProductVariantModel(
      id: vId,
      variantName: vName,
      strength: json['strength']?.toString().trim() ?? '',
      dosageForm: json['dosageForm']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      createdByRole: json['createdByRole']?.toString(),
      sellerId: json['sellerId']?.toString(),
      sellerName: json['sellerName']?.toString(),
      skus: skuList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variantName': variantName,
      'strength': strength,
      'dosageForm': dosageForm,
      'description': description,
      'createdByRole': createdByRole,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'skus': skus.map((s) => s.toJson()).toList(),
    };
  }
}

class ApiProductModel {
  final String id;
  final String productId;
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
  final List<ApiProductVariantModel> variants;
  final List<ProductSkuModel> skus;
  final String? createdByName;
  final String? keyIngredients;
  final String? therapeuticUse;
  final String? contraindications;
  final String? sideEffects;
  final String? dosage;
  final List<String> descriptionList;
  final String? termsAndConditions;
  final String? manufacturerAddress;

  ApiProductModel({
    required this.id,
    required this.productId,
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
    required this.variants,
    required this.skus,
    this.createdByName,
    this.keyIngredients,
    this.therapeuticUse,
    this.contraindications,
    this.sideEffects,
    this.dosage,
    this.descriptionList = const [],
    this.termsAndConditions,
    this.manufacturerAddress,
  });

  factory ApiProductModel.fromJson(Map<String, dynamic> json) {
    // Top-level id & productId
    final String pId = json['productId']?.toString().trim() ?? json['id']?.toString().trim() ?? '';
    final String pCode = json['productCode']?.toString().trim() ?? json['id']?.toString().trim() ?? pId;

    // Variants
    var rawVariants = json['variants'];
    List<ApiProductVariantModel> variantList = [];
    if (rawVariants is List) {
      variantList = rawVariants
          .map((v) => ApiProductVariantModel.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // SKUs
    var rawSkus = json['skus'];
    List<ProductSkuModel> skuList = [];
    if (rawSkus is List) {
      skuList = rawSkus
          .map((s) => ProductSkuModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    // If top-level skus is empty, collect from variants
    if (skuList.isEmpty && variantList.isNotEmpty) {
      for (final v in variantList) {
        skuList.addAll(v.skus);
      }
    }

    // Descriptions
    List<String> descList = [];
    var rawDesc = json['description'];
    if (rawDesc is List) {
      descList = rawDesc.map((d) => d.toString().trim()).where((d) => d.isNotEmpty).toList();
    } else if (rawDesc is String && rawDesc.trim().isNotEmpty) {
      descList = [rawDesc.trim()];
    }

    return ApiProductModel(
      id: pCode.isNotEmpty ? pCode : pId,
      productId: pId,
      productCode: pCode,
      productName: json['productName']?.toString().trim() ?? '',
      brandName: json['brandName']?.toString().trim() ?? '',
      categoryId: json['categoryId']?.toString().trim() ?? '',
      categoryName: json['categoryName']?.toString().trim() ?? '',
      categorySlug: json['categorySlug']?.toString().trim() ?? '',
      subCategory: json['subCategory']?.toString().trim() ?? '',
      prescriptionRequired: json['prescriptionRequired'] == true,
      hsnSacCode: json['hsnSacCode']?.toString().trim() ?? '',
      taxRate: json['taxRate']?.toString() ?? '0.00',
      gmpCertified: json['gmpCertified'] == true,
      manufacturerCountry: json['manufacturerCountry']?.toString().trim() ?? 'India',
      createdByRole: json['createdByRole']?.toString() ?? 'admin',
      createdBySellerId: json['createdBySellerId']?.toString(),
      createdByAdminId: json['createdByAdminId']?.toString(),
      isActive: json['isActive'] != false,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      variants: variantList,
      skus: skuList,
      createdByName: json['createdByName']?.toString(),
      keyIngredients: json['keyIngredients']?.toString().trim(),
      therapeuticUse: json['therapeuticUse']?.toString().trim(),
      contraindications: json['contraindications']?.toString().trim(),
      sideEffects: json['sideEffects']?.toString().trim(),
      dosage: json['dosage']?.toString().trim(),
      descriptionList: descList,
      termsAndConditions: json['termsAndConditions']?.toString().trim(),
      manufacturerAddress: json['manufacturerAddress']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
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
      'variants': variants.map((v) => v.toJson()).toList(),
      'skus': skus.map((s) => s.toJson()).toList(),
      'createdByName': createdByName,
      'keyIngredients': keyIngredients,
      'therapeuticUse': therapeuticUse,
      'contraindications': contraindications,
      'sideEffects': sideEffects,
      'dosage': dosage,
      'description': descriptionList,
      'termsAndConditions': termsAndConditions,
      'manufacturerAddress': manufacturerAddress,
    };
  }

  /// Converts this API product model into a list of [Product] items, one per variant.
  /// If [variants] is empty, returns a single [Product].
  List<Product> toProductList() {
    if (variants.isNotEmpty) {
      return variants.map((v) => _toProductForVariant(v)).toList();
    }
    return [toProduct()];
  }

  /// Converts this API product model into the standard app [Product].
  /// If [targetVariantId] is specified, resolves that variant; otherwise the first variant.
  Product toProduct([String? targetVariantId]) {
    if (variants.isNotEmpty) {
      if (targetVariantId != null && targetVariantId.isNotEmpty) {
        final matching = variants.firstWhere(
          (v) =>
              v.id == targetVariantId ||
              v.variantName.toLowerCase() == targetVariantId.toLowerCase(),
          orElse: () => variants.first,
        );
        return _toProductForVariant(matching);
      }
      return _toProductForVariant(variants.first);
    }
    return _toProductForVariant(null);
  }

  /// Converts a single variant of this API product into a [Product].
  /// The resulting product's [variants] list will contain ONLY the SKUs of this variant,
  /// so that the SKU dropdown/picker presents exactly the SKUs belonging to this variant.
  Product _toProductForVariant(ApiProductVariantModel? v) {
    List<ProductVariant> groupSkus = [];
    final String varId = v?.id ?? '';
    final String varName = v?.variantName ?? '';

    if (v != null && v.skus.isNotEmpty) {
      for (final sku in v.skus) {
        groupSkus.add(_convertSkuToProductVariant(sku, v.id, v.variantName));
      }
    } else if (skus.isNotEmpty) {
      for (final sku in skus) {
        groupSkus.add(_convertSkuToProductVariant(sku, '', ''));
      }
    }

    // Primary SKU: prefer one with stock > 0, otherwise first
    ProductVariant? primaryVariant;
    if (groupSkus.isNotEmpty) {
      primaryVariant = groupSkus.firstWhere(
        (sku) => sku.stockQuantity > 0,
        orElse: () => groupSkus.first,
      );
    }

    final int totalStock = groupSkus.fold<int>(0, (sum, s) => sum + s.stockQuantity);

    // Image resolution: from primary SKU images, variant SKU images, or product fallback
    String img = 'assets/p1.png';
    if (primaryVariant != null && primaryVariant.images.isNotEmpty) {
      img = primaryVariant.images.first;
    } else if (v != null && v.skus.isNotEmpty) {
      for (final s in v.skus) {
        if (s.images.isNotEmpty) {
          img = s.images.first;
          break;
        }
      }
    } else if (skus.isNotEmpty && skus.first.images.isNotEmpty) {
      img = skus.first.images.first;
    }

    // Display Name: e.g. "Baby Gentle Body Lotion - Regular Baby Lotion"
    String displayName = productName.trim();
    final vTrim = varName.trim();
    if (vTrim.isNotEmpty && vTrim.toLowerCase() != displayName.toLowerCase()) {
      if (vTrim.toLowerCase().startsWith(displayName.toLowerCase())) {
        displayName = vTrim;
      } else {
        displayName = '$displayName - $vTrim';
      }
    }

    final double mrpVal = primaryVariant?.originalPrice ?? 100.0;
    final double finalPrice = primaryVariant?.price ?? mrpVal;

    final String brand = brandName.trim().isEmpty ? 'Healthcare' : brandName.trim();
    final String category = categoryName.trim().isEmpty ? 'General' : categoryName.trim();

    String desc = '';
    if (descriptionList.isNotEmpty) {
      desc = descriptionList.join('\n');
    } else if (v != null && v.description != null && v.description!.isNotEmpty) {
      desc = v.description!;
    } else if (primaryVariant != null &&
        primaryVariant.storageConditions != null &&
        primaryVariant.storageConditions!.isNotEmpty) {
      desc = 'Storage: ${primaryVariant.storageConditions}';
    } else {
      desc = 'Quality certified medical & wellness product.';
    }

    final String potencyVal = (v != null && v.strength.isNotEmpty)
        ? v.strength
        : ((variants.isNotEmpty && variants.first.strength.isNotEmpty)
            ? variants.first.strength
            : 'Standard');

    final groups = [
      ProductVariantGroup(
        id: varId.isNotEmpty ? varId : id,
        variantName: vTrim.isNotEmpty ? vTrim : 'Standard',
        strength: v?.strength ?? '',
        dosageForm: v?.dosageForm ?? '',
        description: v?.description ?? '',
        skus: groupSkus,
      ),
    ];

    final productUniqueId = (varId.isNotEmpty && varId != id) ? varId : id;

    return Product(
      id: productUniqueId,
      productId: productId.isNotEmpty ? productId : id,
      name: displayName,
      brand: brand,
      image: img,
      price: finalPrice,
      originalPrice: mrpVal,
      rating: 4.8,
      reviewsCount: 15,
      isPrescriptionRequired: prescriptionRequired,
      isOutOfStock: primaryVariant != null ? primaryVariant.stockQuantity <= 0 : totalStock <= 0,
      category: category,
      description: desc,
      potency: potencyVal,
      packSize: primaryVariant?.packSize ?? '1 Unit',
      flavour: 'Standard',
      doctorDiscount: primaryVariant?.doctorDiscount,
      doctorActive: primaryVariant?.doctorActive,
      consumerDiscount: primaryVariant?.consumerDiscount,
      consumerActive: primaryVariant?.consumerActive,
      variants: groupSkus,
      variantGroups: groups,
      skuId: primaryVariant?.id,
      skuCode: primaryVariant?.skuCode,
      skuName: primaryVariant?.skuName,
      selectedVariantId: varId,
      selectedVariantName: vTrim,
      stockQuantity: primaryVariant?.stockQuantity ?? totalStock,
      unitOfMeasure: primaryVariant?.unitOfMeasure,
      typeOfPacking: primaryVariant?.typeOfPacking,
      packingMaterial: primaryVariant?.packingMaterial,
      batchNumber: primaryVariant?.batchNumber,
      expiryDate: primaryVariant?.expiryDate,
      storageConditions: primaryVariant?.storageConditions,
      images: primaryVariant != null && primaryVariant.images.isNotEmpty
          ? primaryVariant.images
          : (img.startsWith('http') ? [img] : []),
      keyIngredients: keyIngredients,
      therapeuticUse: therapeuticUse,
      contraindications: contraindications,
      sideEffects: sideEffects,
      dosage: dosage,
      descriptionList: descriptionList,
      termsAndConditions: termsAndConditions,
      manufacturerAddress: manufacturerAddress,
      sellerId: primaryVariant?.sellerId ?? v?.sellerId ?? createdBySellerId,
    );
  }

  static ProductVariant _convertSkuToProductVariant(
    ProductSkuModel sku,
    String variantId,
    String variantName,
  ) {
    final double skuMrp = double.tryParse(sku.mrp) ?? 0.0;
    final double skuDisc = double.tryParse(sku.consumerDiscount) ?? 0.0;
    final double skuDocDisc = double.tryParse(sku.doctorDiscount) ?? 0.0;
    final double skuDiscAmount = (skuMrp * skuDisc / 100.0);
    final double skuPrice = (skuMrp - skuDiscAmount).clamp(0.0, skuMrp);

    String packText = '';
    final String packing = sku.typeOfPacking.trim();
    final String uom = sku.unitOfMeasure.trim();
    if (sku.skuName.trim().isNotEmpty) {
      packText = sku.skuName.trim();
    } else if (packing.isNotEmpty && uom.isNotEmpty) {
      packText = '${sku.packSize} $uom $packing';
    } else if (packing.isNotEmpty) {
      packText = '${sku.packSize} $packing';
    } else if (uom.isNotEmpty) {
      packText = '${sku.packSize} $uom';
    } else {
      packText = '${sku.packSize} Unit';
    }
    packText = _normalizePackDisplay(packText);

    return ProductVariant(
      id: sku.id.isNotEmpty ? sku.id : sku.skuUuid,
      packSize: packText,
      price: skuPrice > 0 ? skuPrice : skuMrp,
      originalPrice: skuMrp,
      skuCode: sku.skuCode,
      skuName: sku.skuName,
      variantId: variantId.isNotEmpty ? variantId : sku.variantId,
      variantName: variantName.isNotEmpty ? variantName : sku.variantName,
      stockQuantity: sku.stockQuantity,
      unitOfMeasure: sku.unitOfMeasure,
      typeOfPacking: sku.typeOfPacking,
      packingMaterial: sku.packingMaterial,
      batchNumber: sku.batchNumber,
      expiryDate: sku.expiryDate,
      storageConditions: sku.storageConditions,
      images: sku.images,
      isOutOfStock: sku.stockQuantity <= 0,
      doctorDiscount: skuDocDisc,
      doctorActive: sku.doctorActive,
      consumerDiscount: skuDisc,
      consumerActive: sku.consumerActive,
      sellerId: sku.sellerId,
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
    if (json['success'] == true) {
      Map<String, dynamic> prodMap = {};
      if (json['product'] is Map<String, dynamic>) {
        prodMap = Map<String, dynamic>.from(json['product'] as Map);
      } else {
        prodMap = Map<String, dynamic>.from(json);
      }

      // Merge top-level variants if present and missing in prodMap
      if (json['variants'] is List &&
          (prodMap['variants'] == null || (prodMap['variants'] as List).isEmpty)) {
        prodMap['variants'] = json['variants'];
      }
      // Merge top-level skus if present and missing in prodMap
      if (json['skus'] is List &&
          (prodMap['skus'] == null || (prodMap['skus'] as List).isEmpty)) {
        prodMap['skus'] = json['skus'];
      }
      // Top-level id and productId
      if (json['id'] != null && prodMap['id'] == null) {
        prodMap['id'] = json['id'];
      }
      if (json['productId'] != null && prodMap['productId'] == null) {
        prodMap['productId'] = json['productId'];
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
