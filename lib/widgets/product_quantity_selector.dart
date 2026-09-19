import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';

class ProductQuantitySelector extends StatelessWidget {
  final Product product;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onAdded;

  const ProductQuantitySelector({
    super.key,
    required this.product,
    this.iconSize = 16,
    this.fontSize = 13,
    this.onAdded,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final qty = appState.getProductQuantity(product.id);

        if (qty == 0) {
          return GestureDetector(
            onTap: () {
              appState.addToCart(product, qty: 1);
              if (onAdded != null) {
                onAdded!();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          );
        }

        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF), // Soft blue tint matching image
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC7DBF9),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  appState.updateCartQty(product, qty - 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    Icons.remove,
                    size: iconSize,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$qty',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  appState.updateCartQty(product, qty + 1);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    Icons.add,
                    size: iconSize,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
