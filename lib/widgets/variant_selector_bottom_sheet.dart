import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';

String formatPackText(String text) {
  final match = RegExp(r'^(\d+)\s+([A-Za-z]+)\s*\(([A-Za-z0-9]+)\)$').firstMatch(text.trim());
  if (match != null) {
    return '${match.group(1)} (${match.group(3)}) ${match.group(2)}';
  }
  return text;
}

ProductVariant matchInitialVariant(
  List<ProductVariant> variants,
  String initialPackSize,
) {
  if (variants.isEmpty) {
    return ProductVariant(
      id: '',
      packSize: initialPackSize.isNotEmpty ? initialPackSize : '30 ml',
      price: 0,
      originalPrice: 0,
    );
  }

  if (initialPackSize.isEmpty) return variants.first;

  // Extract digits from initialPackSize, e.g. "30" from "30 Bottle (ml)"
  final digitsMatch = RegExp(r'(\d+)').firstMatch(initialPackSize);
  final digits = digitsMatch?.group(1);

  if (digits != null) {
    for (final v in variants) {
      final vDigitsMatch = RegExp(r'(\d+)').firstMatch(v.packSize);
      if (vDigitsMatch?.group(1) == digits) {
        return v;
      }
    }
  }

  // Fallback to substring or exact match
  final normInit = initialPackSize.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  for (final v in variants) {
    final normV = v.packSize.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normV == normInit || normV.contains(normInit) || normInit.contains(normV)) {
      return v;
    }
  }

  return variants.first;
}

void showVariantSelectorBottomSheet({
  required BuildContext context,
  required Product product,
  required List<ProductVariant> variants,
  required ProductVariant selectedVariant,
  required ValueChanged<ProductVariant> onSelect,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Select Bottle Size / Pack',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Variants list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  final isSelected =
                      variant.packSize.toLowerCase() ==
                      selectedVariant.packSize.toLowerCase();
                  final discountPct = variant.originalPrice > variant.price
                      ? (((variant.originalPrice - variant.price) /
                                  variant.originalPrice) *
                              100)
                          .round()
                      : 0;

                  return InkWell(
                    onTap: () {
                      onSelect(variant);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.12)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.sanitizer_outlined,
                                    size: 16,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    formatPackText(variant.packSize),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${variant.price.toInt()}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (variant.originalPrice > variant.price)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${variant.originalPrice.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textLight,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    if (discountPct > 0) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$discountPct% OFF',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
