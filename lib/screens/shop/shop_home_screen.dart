import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/broadcast_service.dart';
import '../../services/payment_reminder_service.dart';
import '../../services/product_service.dart';
import '../../services/shop_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/bvh_logo_widget.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'shop_order_history_screen.dart';
import 'shop_payment_screen.dart';
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
  Timer? _broadcastTicker;

  // Payment Reminder state
  StreamSubscription<PaymentReminderModel?>? _reminderSubscription;
  String? _listenedDistributorId;
  String? _listenedShopUid;
  String? _lastShownReminderKey;
  bool _isReminderDialogOpen = false;
  bool _dismissedReminderBanner = false;
  String _lastDismissedBannerReminderId = '';

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialTabIndex;
    // Periodic ticker to refresh banner live when 24h expiration completes
    _broadcastTicker = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _broadcastTicker?.cancel();
    _reminderSubscription?.cancel();
    super.dispose();
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

    // Attach real-time payment reminder listener for this shop
    _initPaymentReminderListener(distributorId, shopUid, locale);

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
          _buildHome(context, locale, distributorId, shopUid, profile),
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
    String shopUid,
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
                child: _buildPaymentReminderBanner(
                  context,
                  locale,
                  distributorId,
                  shopUid,
                ),
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
                              locale.translateCategory(cat),
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
                            locale.t('no_matching_products'),
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
                            child: Text(locale.t('reset_filter')),
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
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const BvhLogoWidget(
              size: 34,
              showCard: false,
            ),
          ),
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
        if (b == null || !b.active || b.message.trim().isEmpty || b.isExpired) {
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
                          locale.translateBroadcastTag(b.tag).toUpperCase(),
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
                        ] else
                          const Spacer(),
                        if (b.timeRemaining != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 10, color: tagColor),
                                const SizedBox(width: 3),
                                Text(
                                  b.timeRemainingFormatted,
                                  style: TextStyle(
                                    color: tagColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

  void _initPaymentReminderListener(
    String distributorId,
    String shopUid,
    LocaleState locale,
  ) {
    if (distributorId.isEmpty || shopUid.isEmpty) return;
    if (_listenedDistributorId == distributorId && _listenedShopUid == shopUid) {
      return;
    }

    _listenedDistributorId = distributorId;
    _listenedShopUid = shopUid;
    _reminderSubscription?.cancel();

    _reminderSubscription = PaymentReminderService.streamShopPaymentReminder(
      distributorId: distributorId,
      shopUid: shopUid,
    ).listen((reminder) {
      if (!mounted) return;
      if (reminder != null && reminder.active) {
        final reminderKey =
            '${reminder.id}_${reminder.createdAt?.millisecondsSinceEpoch ?? 0}_${reminder.amount.toStringAsFixed(2)}';

        if (_lastShownReminderKey != reminderKey && !_isReminderDialogOpen) {
          _lastShownReminderKey = reminderKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isReminderDialogOpen) {
              _showPaymentReminderDialog(
                reminder: reminder,
                locale: locale,
                distributorId: distributorId,
                shopUid: shopUid,
              );
            }
          });
        }
      }
    });
  }

  Widget _buildPaymentReminderBanner(
    BuildContext context,
    LocaleState locale,
    String distributorId,
    String shopUid,
  ) {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<PaymentReminderModel?>(
      stream: PaymentReminderService.streamShopPaymentReminder(
        distributorId: distributorId,
        shopUid: shopUid,
      ),
      builder: (context, snapshot) {
        final reminder = snapshot.data;
        if (reminder == null || !reminder.active) {
          return const SizedBox.shrink();
        }

        if (_dismissedReminderBanner &&
            _lastDismissedBannerReminderId != reminder.id) {
          _dismissedReminderBanner = false;
        }

        if (_dismissedReminderBanner) return const SizedBox.shrink();

        final numberFormat = NumberFormat('#,##,##0', 'en_IN');
        final formattedAmount = reminder.amount > 0
            ? '₹${numberFormat.format(reminder.amount)}'
            : '';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.amber50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.amber600.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber600.withValues(alpha: 0.1),
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
                  color: AppColors.amber600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
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
                          locale.t('payment_reminder').toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.amber700,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (formattedAmount.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• $formattedAmount Due',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.amber700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder.message.isNotEmpty
                          ? reminder.message
                          : locale.t('clear_dues_msg'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ink900,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopPaymentScreen(
                              amountDue: reminder.amount > 0 ? reminder.amount : null,
                              distributorId: distributorId,
                              distributorName: reminder.distributorName,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        '${locale.t('pay_now')} →',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.milkBlue700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _dismissedReminderBanner = true;
                    _lastDismissedBannerReminderId = reminder.id;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
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

  Future<void> _showPaymentReminderDialog({
    required PaymentReminderModel reminder,
    required LocaleState locale,
    required String distributorId,
    required String shopUid,
  }) async {
    _isReminderDialogOpen = true;
    final numberFormat = NumberFormat('#,##,##0', 'en_IN');
    final formattedAmount = reminder.amount > 0
        ? '₹${numberFormat.format(reminder.amount)}'
        : 'Payment Due';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 16,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bell icon with glowing ring
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.amber100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber600.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.amber600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    reminder.title.isNotEmpty
                        ? reminder.title
                        : locale.t('payment_reminder'),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.ink900,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (reminder.distributorName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${locale.t('from_distributor')}: ${reminder.distributorName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Highlighted Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.amber50,
                          AppColors.amber100.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.amber600.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          locale.t('pending_dues').toUpperCase(),
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.amber700,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedAmount,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.amber700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (reminder.pendingOrdersCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${reminder.pendingOrdersCount} ${locale.t('nav_orders').toLowerCase()} ${locale.t('pay_pending').toLowerCase()}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Custom Message from distributor
                  if (reminder.message.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.milkBlue50.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.milkBlue200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.milkBlue700,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reminder.message,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.ink900,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    locale.t('clear_dues_msg'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink500,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 22),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await PaymentReminderService.dismissReminderForShop(
                              distributorId: distributorId,
                              shopUid: shopUid,
                              reminder: reminder,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            locale.t('remind_me_later'),
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.ink700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await PaymentReminderService.dismissReminderForShop(
                              distributorId: distributorId,
                              shopUid: shopUid,
                              reminder: reminder,
                            );
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShopPaymentScreen(
                                    amountDue: reminder.amount > 0 ? reminder.amount : null,
                                    distributorId: distributorId,
                                    distributorName: reminder.distributorName,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.payment_rounded, size: 18),
                          label: Text(locale.t('pay_now')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dairyGreen600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isReminderDialogOpen = false;
    }
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
        content: Text(
          locale.t('logout_shop_confirm'),
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
                  locale.translateProduct(product.name),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${product.packSize} • ${locale.translateUnit(product.unit)}',
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
