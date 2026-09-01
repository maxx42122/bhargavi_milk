import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/broadcast_service.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/quantity_stepper.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'shop_order_history_screen.dart';
import 'shop_product_listing_screen.dart';
import 'shop_profile_screen.dart';

class ShopHomeScreen extends StatefulWidget {
  final String? distributorId;
  final int initialTabIndex;

  const ShopHomeScreen({
    super.key,
    this.distributorId,
    this.initialTabIndex = 0,
  });

  @override
  State<ShopHomeScreen> createState() => _ShopHomeScreenState();
}

class _ShopHomeScreenState extends State<ShopHomeScreen> {
  late int _navIndex;
  final Map<String, int> _cart = {};
  String _category = 'All';
  String _search = '';
  bool _dismissedBroadcast = false;
  String _lastDismissedBroadcastMessage = '';

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialTabIndex;
  }

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

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _addToCart(String id) =>
      setState(() => _cart[id] = (_cart[id] ?? 0) + 1);

  void _removeFromCart(String id) {
    if ((_cart[id] ?? 0) > 0) {
      setState(() => _cart[id] = _cart[id]! - 1);
      if (_cart[id] == 0) _cart.remove(id);
    }
  }

  void _setCartQuantity(String id, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(id);
      } else {
        _cart[id] = qty;
      }
    });
  }

  String _resolveDistributorId(BuildContext context) {
    if (widget.distributorId != null && widget.distributorId!.isNotEmpty) {
      return widget.distributorId!;
    }
    try {
      final auth = AuthStateScope.of(context);
      if (auth.distributorId != null && auth.distributorId!.isNotEmpty) {
        return auth.distributorId!;
      }
    } catch (_) {}
    return '';
  }

  String _resolveShopUid() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      if (!p.active) return false;
      final q = _search.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.packSize.toLowerCase().contains(q);
      final matchCat = _category == 'All' || p.category == _category;
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final distributorId = _resolveDistributorId(context);
    final shopUid = _resolveShopUid();

    return StreamBuilder<ShopProfile?>(
      stream: ShopService.streamShopProfile(
        distributorId: distributorId,
        shopUid: shopUid,
      ),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;

        // Keep AuthState updated with the loaded profile
        if (profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final auth = AuthStateScope.of(context);
              if (auth.shopProfile != profile) {
                auth.setShopProfile(profile);
              }
            }
          });
        }

        final pages = [
          _buildHome(context, locale, distributorId, profile),
          ShopProductListingScreen(
            distributorId: distributorId,
            cart: _cart,
            onAdd: _addToCart,
            onRemove: _removeFromCart,
            onSetQuantity: _setCartQuantity,
          ),
          CartScreen(
            distributorId: distributorId,
            cart: _cart,
            onAdd: _addToCart,
            onRemove: _removeFromCart,
            onSetQuantity: _setCartQuantity,
            onClearCart: () => setState(() => _cart.clear()),
          ),
          ShopOrderHistoryScreen(
            distributorId: distributorId,
            shopUid: shopUid,
          ),
          ShopProfileScreen(
            distributorId: distributorId,
            shopUid: shopUid,
          ),
        ];

        return Scaffold(
          body: pages[_navIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.milkBlue700,
            unselectedItemColor: AppColors.ink500,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: locale.t('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.inventory_2_rounded),
                label: locale.t('nav_products'),
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart_rounded),
                    if (_cartCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.red500,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: locale.t('nav_cart'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_rounded),
                label: locale.t('nav_history'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle_rounded),
                label: locale.t('nav_profile'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHome(
    BuildContext context,
    LocaleState locale,
    String distributorId,
    ShopProfile? profile,
  ) {
    return StreamBuilder<List<Product>>(
      stream: ProductService.streamProducts(distributorId),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final filteredProducts = _filterProducts(allProducts);

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, locale, profile),
              ),
              SliverToBoxAdapter(
                child: _buildBroadcastBanner(context, locale, distributorId),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AppSearchBar(
                    hint:
                        '${locale.t('search')} ${locale.t('nav_products').toLowerCase()}…',
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
              // Category chips
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    children: _categories.map((cat) {
                      final active = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _category = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
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
              ),
              // Products grid or empty states
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (allProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: locale.t('no_data'),
                    subtitle:
                        'No products available from your distributor right now.',
                  ),
                )
              else if (filteredProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.76,
                    ),
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final p = filteredProducts[i];
                      final qty = _cart[p.id] ?? 0;
                      return _ProductCard(
                        product: p,
                        qty: qty,
                        onAdd: () => _addToCart(p.id),
                        onRemove: () => _removeFromCart(p.id),
                        onSetQuantity: (newQty) => _setCartQuantity(p.id, newQty),
                        locale: locale,
                      );
                    }, childCount: filteredProducts.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          // Floating cart button
          floatingActionButton: _cartCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () => setState(() => _navIndex = 2),
                  backgroundColor: AppColors.milkBlue600,
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: Text(
                    '$_cartCount ${locale.t("items_in_cart")}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LocaleState locale,
    ShopProfile? profile,
  ) {
    final top = MediaQuery.of(context).padding.top;
    final shopName = profile?.shopName.isNotEmpty == true
        ? profile!.shopName
        : 'My Dairy Shop';
    final ownerName = profile?.ownerName ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${locale.t("good_morning")} 👋',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  shopName,
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ownerName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ownerName,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const LanguagePillButton(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmLogout(context, locale),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastBanner(
    BuildContext context,
    LocaleState locale,
    String distributorId,
  ) {
    if (distributorId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<BroadcastModel?>(
      stream: BroadcastService.streamCurrentBroadcast(distributorId),
      builder: (context, snapshot) {
        final b = snapshot.data;
        if (b == null || !b.active || b.message.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        // If distributor updated message, un-dismiss
        if (_dismissedBroadcast && _lastDismissedBroadcastMessage != b.message) {
          _dismissedBroadcast = false;
        }

        if (_dismissedBroadcast) return const SizedBox.shrink();

        Color tagColor;
        Color tagBg;
        IconData tagIcon;

        switch (b.tag.toLowerCase()) {
          case 'urgent':
            tagColor = AppColors.red600;
            tagBg = AppColors.red100;
            tagIcon = Icons.warning_amber_rounded;
            break;
          case 'delivery':
            tagColor = AppColors.milkBlue700;
            tagBg = AppColors.milkBlue100;
            tagIcon = Icons.local_shipping_rounded;
            break;
          case 'stock':
            tagColor = AppColors.dairyGreen700;
            tagBg = AppColors.dairyGreen100;
            tagIcon = Icons.inventory_2_rounded;
            break;
          case 'offer':
            tagColor = AppColors.amber700;
            tagBg = AppColors.amber100;
            tagIcon = Icons.local_offer_rounded;
            break;
          default:
            tagColor = AppColors.milkBlue700;
            tagBg = AppColors.milkBlue100;
            tagIcon = Icons.campaign_rounded;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tagBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: tagColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: tagColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tagIcon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          b.tag.toUpperCase(),
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (b.title.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${b.title}',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.ink900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      b.message,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _dismissedBroadcast = true;
                    _lastDismissedBroadcastMessage = b.message;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.ink500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, LocaleState locale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.red500),
            const SizedBox(width: 8),
            Text(locale.t('logout')),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your shop account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(locale.t('logout')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService.signOut();
        if (context.mounted) {
          try {
            AuthStateScope.of(context).clear();
          } catch (_) {}

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppColors.red500,
            ),
          );
        }
      }
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<int>? onSetQuantity;
  final LocaleState locale;

  const _ProductCard({
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
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inCart ? AppColors.milkBlue600 : AppColors.border,
          width: inCart ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: inCart
                ? AppColors.milkBlue600.withValues(alpha: 0.08)
                : AppColors.milkBlue900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / emoji
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.milkBlue50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  product.emoji.isNotEmpty ? product.emoji : '🥛',
                  style: const TextStyle(fontSize: 38),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.packSize} • ${product.unit}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.milkBlue700,
                      ),
                    ),
                    const Spacer(),
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          locale.t('out_of_stock'),
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.red600,
                            fontSize: 10,
                          ),
                        ),
                      )
                    else
                      QuantityStepper(
                        qty: qty,
                        compact: true,
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
          ),
        ],
      ),
    );
  }
}
