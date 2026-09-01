import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/product_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/quantity_stepper.dart';

// Make sure this path matches your project structure.
import 'cart_screen.dart';

class ShopProductListingScreen extends StatefulWidget {
  final String distributorId;
  final Map<String, int> cart;
  final void Function(String id) onAdd;
  final void Function(String id) onRemove;
  final void Function(String id, int quantity)? onSetQuantity;

  const ShopProductListingScreen({
    super.key,
    required this.distributorId,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    this.onSetQuantity,
  });

  @override
  State<ShopProductListingScreen> createState() =>
      _ShopProductListingScreenState();
}

class _ShopProductListingScreenState extends State<ShopProductListingScreen> {
  String _search = '';
  String _category = 'All';

  final _categories = [
    'All',
    'Milk',
    'Curd',
    'Butter',
    'Paneer',
    'Ghee',
    'Buttermilk',
    'Other',
  ];

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      if (!p.active) return false;

      final q = _search.trim().toLowerCase();

      final matchSearch =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.packSize.toLowerCase().contains(q);

      final matchCat = _category == 'All' || p.category == _category;

      return matchSearch && matchCat;
    }).toList();
  }

  // Total number of products/units currently in cart.
  int get _cartItemCount {
    return widget.cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _openCart() {
    if (_cartItemCount == 0) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          distributorId: widget.distributorId,
          cart: widget.cart,
          onAdd: widget.onAdd,
          onRemove: widget.onRemove,
          onSetQuantity: widget.onSetQuantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Product>>(
        stream: ProductService.streamProducts(widget.distributorId),
        builder: (context, snapshot) {
          final allProducts = snapshot.data ?? [];
          final activeProducts = _filterProducts(allProducts);

          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;

          return Column(
            children: [
              // ==========================================================
              // HEADER
              // ==========================================================
              GradientHeader(
                title: locale.t('nav_products'),
                subtitle: locale.t('browse_products'),
              ),

              // ==========================================================
              // SEARCH
              // ==========================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: AppSearchBar(
                  hint:
                      '${locale.t("search")} ${locale.t("nav_products").toLowerCase()}…',
                  onChanged: (v) {
                    setState(() {
                      _search = v;
                    });
                  },
                ),
              ),

              // ==========================================================
              // CATEGORY FILTER
              // ==========================================================
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: _categories.map((cat) {
                    final active = _category == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _category = cat;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.milkBlue600
                                : AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: active
                                  ? AppColors.milkBlue600
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: AppTextStyles.captionBold.copyWith(
                              color: active ? Colors.white : AppColors.ink700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ==========================================================
              // PRODUCT LIST
              // ==========================================================
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (allProducts.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: locale.t('no_data'),
                        subtitle:
                            'Your distributor has not added any products yet.',
                      );
                    }

                    if (activeProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 40,
                                color: AppColors.ink300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No matching products',
                                style: AppTextStyles.bodyBold,
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _search = '';
                                    _category = 'All';
                                  });
                                },
                                child: const Text('Reset filter'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: activeProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final product = activeProducts[i];

                        final qty = widget.cart[product.id] ?? 0;

                        return _ProductListRow(
                          product: product,
                          qty: qty,
                          onAdd: () => widget.onAdd(product.id),
                          onRemove: () => widget.onRemove(product.id),
                          onSetQuantity: widget.onSetQuantity != null
                              ? (newQty) =>
                                    widget.onSetQuantity!(product.id, newQty)
                              : null,
                          locale: locale,
                        );
                      },
                    );
                  },
                ),
              ),

              // ==========================================================
              // PROCEED TO CART BUTTON
              // ==========================================================
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.milkBlue900.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _cartItemCount > 0 ? _openCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.milkBlue600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.ink500,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _cartItemCount > 0
                                ? 'Proceed to Cart ($_cartItemCount)'
                                : 'Proceed to Cart',
                            style: AppTextStyles.bodyBold.copyWith(
                              color: _cartItemCount > 0
                                  ? Colors.white
                                  : AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================================================
// PRODUCT LIST ROW
// ==========================================================================

class _ProductListRow extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<int>? onSetQuantity;
  final LocaleState locale;

  const _ProductListRow({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.onSetQuantity,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    final isOutOfStock = product.stock <= 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart ? AppColors.milkBlue600 : AppColors.border,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ==============================================================
          // PRODUCT ICON
          // ==============================================================
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.milkBlue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.milkBlue100),
            ),
            child: Center(
              child: Text(
                product.emoji.isNotEmpty ? product.emoji : '🥛',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ==============================================================
          // PRODUCT INFORMATION
          // ==============================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.bodyBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.packSize} • ${product.unit}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? AppColors.red100
                            : (product.stock <= 10
                                  ? AppColors.amber100
                                  : AppColors.dairyGreen100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOutOfStock
                            ? locale.t('out_of_stock')
                            : (product.stock <= 10
                                  ? '${product.stock} left'
                                  : locale.t('in_stock')),
                        style: AppTextStyles.overline.copyWith(
                          color: isOutOfStock
                              ? AppColors.red600
                              : (product.stock <= 10
                                    ? AppColors.amber600
                                    : AppColors.dairyGreen700),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==============================================================
          // PRICE + QUANTITY
          // ==============================================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.milkBlue700,
                ),
              ),
              const SizedBox(height: 8),

              if (isOutOfStock)
                Text(
                  locale.t('out_of_stock'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.red500,
                    fontSize: 11,
                  ),
                )
              else
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
        ],
      ),
    );
  }
}
