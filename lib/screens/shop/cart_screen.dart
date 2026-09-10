import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/product_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/quantity_stepper.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final String distributorId;
  final Map<String, int> cart;
  final void Function(String) onAdd;
  final void Function(String) onRemove;
  final void Function(String id, int quantity)? onSetQuantity;
  final VoidCallback? onClearCart;

  const CartScreen({
    super.key,
    required this.distributorId,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    this.onSetQuantity,
    this.onClearCart,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    return StreamBuilder<List<Product>>(
      stream: ProductService.streamProducts(distributorId),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final productMap = {for (final p in allProducts) p.id: p};

        final cartItems = cart.entries
            .where((e) => e.value > 0 && productMap.containsKey(e.key))
            .map((e) => (productMap[e.key]!, e.value))
            .toList();

        final double subtotal = cartItems.fold(
          0.0,
          (sum, item) => sum + (item.$1.price * item.$2),
        );

        final totalItemCount = cartItems.fold(0, (sum, item) => sum + item.$2);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              GradientHeader(
                title: locale.t('cart'),
                subtitle: '$totalItemCount ${locale.t('items_in_cart')}',
              ),
              if (cartItems.isEmpty)
                Expanded(
                  child: EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: locale.t('empty_cart'),
                    subtitle: locale.t('add_items'),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = cartItems[i];
                      return _CartRow(
                        product: item.$1,
                        qty: item.$2,
                        onAdd: () => onAdd(item.$1.id),
                        onRemove: () => onRemove(item.$1.id),
                        onSetQuantity: onSetQuantity != null
                            ? (newQty) => onSetQuantity!(item.$1.id, newQty)
                            : null,
                        locale: locale,
                      );
                    },
                  ),
                ),
                // Bill summary
                _buildBillSummary(context, locale, cartItems, subtotal),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillSummary(
    BuildContext context,
    LocaleState locale,
    List<(Product, int)> cartItems,
    double subtotal,
  ) {
    const discount = 0.0;
    final total = subtotal - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(
            locale.t('subtotal'),
            '₹${subtotal.toStringAsFixed(subtotal % 1 == 0 ? 0 : 2)}',
          ),
          if (discount > 0)
            _summaryRow(
              locale.t('discount'),
              '−₹${discount.toStringAsFixed(0)}',
              color: AppColors.dairyGreen700,
            ),
          const Divider(height: 16),
          _summaryRow(
            locale.t('grand_total'),
            '₹${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
            bold: true,
            color: AppColors.milkBlue700,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckoutScreen(
                    distributorId: distributorId,
                    cartItems: cartItems,
                    total: total,
                    onOrderPlaced: onClearCart,
                  ),
                ),
              ),
              child: Text(locale.t('proceed_checkout')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    final style = bold ? AppTextStyles.bodyBold : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<int>? onSetQuantity;
  final LocaleState locale;

  const _CartRow({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.onSetQuantity,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.milkBlue100),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.milkBlue50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                product.emoji.isNotEmpty ? product.emoji : '🥛',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.translateProduct(product.name), style: AppTextStyles.bodyBold),
                Text(
                  '${product.packSize} • ${locale.translateUnit(product.unit)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
                ),
                Text(
                  '₹${(product.price * qty).toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue700,
                  ),
                ),
              ],
            ),
          ),
          QuantityStepper(
            qty: qty,
            maxStock: product.stock > 0 ? product.stock : null,
            productName: product.name,
            addLabel: locale.t('add').toUpperCase(),
            onChanged: (newQty) {
              if (onSetQuantity != null) {
                onSetQuantity!(newQty);
              } else {
                final diff = newQty - qty;
                if (diff > 0) {
                  for (int k = 0; k < diff; k++) {
                    onAdd();
                  }
                } else if (diff < 0) {
                  for (int k = 0; k < -diff; k++) {
                    onRemove();
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
