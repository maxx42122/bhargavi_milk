import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/product_service.dart';
import '../../state/locale_state.dart';
import '../quantity_stepper.dart';
import 'desktop_hover_card.dart';

class DesktopProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<int> onSetQuantity;

  const DesktopProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onSetQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final inStock = product.stock > 0 && product.active;
    final itemTotal = product.price * quantity;

    return DesktopHoverCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Emoji / Icon + Pack Size Badge + Stock Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.milkBlue50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.milkBlue100,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    product.emoji.isNotEmpty ? product.emoji : '🥛',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        product.packSize.isNotEmpty
                            ? product.packSize
                            : 'Standard',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.ink700,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.translateCategory(product.category),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: inStock ? AppColors.dairyGreen50 : AppColors.red50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: inStock
                        ? AppColors.dairyGreen300
                        : AppColors.red300,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  inStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color: inStock
                        ? AppColors.dairyGreen700
                        : AppColors.red600,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Product Name
          Text(
            locale.translateProduct(product.name),
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.ink900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),
          const SizedBox(height: 14),

          // Price & Stepper Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: AppTextStyles.priceLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  if (quantity > 0)
                    Text(
                      'Total: ₹${itemTotal.toStringAsFixed(0)}',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.ink600,
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),

              if (inStock)
                QuantityStepper(
                  qty: quantity,
                  compact: true,
                  maxStock: product.stock > 0 ? product.stock : null,
                  productName: product.name,
                  onChanged: (newQty) {
                    onSetQuantity(newQty);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Unavailable',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink500,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
