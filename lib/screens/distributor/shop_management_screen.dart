import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import 'customer_profile_screen.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// ShopManagementScreen
///
/// Distributor screen:
/// 1. Active Shops
/// 2. Pending Shop Requests
///
/// When a shop selects this distributor, the shop should be stored under:
///
/// distributor/{distributorId}/shops/{shopUid}
///
/// with:
///
/// status: "pending"
///
/// The distributor can then Approve or Reject the request.
/// ─────────────────────────────────────────────────────────────────────────────

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  String _search = '';

  @override
  void initState() {
    super.initState();

    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final authState = AuthStateScope.of(context);

    final distributorId = authState.distributorId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ────────────────────────────────────────────────────────────────
          // Header
          // ────────────────────────────────────────────────────────────────
          GradientHeader(
            title: locale.t('nav_customers'),
            subtitle: locale.t('manage_shops_requests'),
          ),

          // ────────────────────────────────────────────────────────────────
          // Search
          // ────────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AppSearchBar(
              hint: '${locale.t("search")} shops…',
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),

          // ────────────────────────────────────────────────────────────────
          // Tabs
          // ────────────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.ink500,
              labelStyle: AppTextStyles.captionBold,
              unselectedLabelStyle: AppTextStyles.caption,
              indicator: BoxDecoration(
                color: AppColors.milkBlue600,
                borderRadius: BorderRadius.circular(9),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                // Active Shops
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 15),
                      const SizedBox(width: 6),
                      Text(locale.t('shop_active')),
                    ],
                  ),
                ),

                // Pending Requests
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text(locale.t('requests')),
                      if (distributorId.isNotEmpty)
                        _PendingCountBadge(distributorId: distributorId),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ────────────────────────────────────────────────────────────────
          // Content
          // ────────────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Active shops
                _ShopList(
                  distributorId: distributorId,
                  status: 'active',
                  search: _search,
                  locale: locale,
                ),

                // Pending shop requests
                _ShopList(
                  distributorId: distributorId,
                  status: 'pending',
                  search: _search,
                  locale: locale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending request count
// ─────────────────────────────────────────────────────────────────────────────

class _PendingCountBadge extends StatelessWidget {
  final String distributorId;

  const _PendingCountBadge({required this.distributorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AuthService.shopsStream(
        distributorId: distributorId,
        status: 'pending',
      ),
      builder: (_, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.red500,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Firestore shop list
// ─────────────────────────────────────────────────────────────────────────────

class _ShopList extends StatefulWidget {
  final String distributorId;
  final String status;
  final String search;
  final LocaleState locale;

  const _ShopList({
    required this.distributorId,
    required this.status,
    required this.search,
    required this.locale,
  });

  @override
  State<_ShopList> createState() => _ShopListState();
}

class _ShopListState extends State<_ShopList> {
  Stream<QuerySnapshot<Map<String, dynamic>>>? _shopsStream;
  Stream<List<OrderModel>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant _ShopList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.distributorId != widget.distributorId ||
        oldWidget.status != widget.status) {
      _initStreams();
    }
  }

  void _initStreams() {
    if (widget.distributorId.isNotEmpty) {
      _shopsStream = AuthService.shopsStream(
        distributorId: widget.distributorId,
        status: widget.status,
      );
      _ordersStream = OrderService.streamDistributorOrders(
        distributorId: widget.distributorId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.distributorId.isEmpty || _shopsStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _shopsStream,
      builder: (context, snapshot) {
        // ────────────────────────────────────────────────────────────────
        // Loading
        // ────────────────────────────────────────────────────────────────

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // ────────────────────────────────────────────────────────────────
        // Error
        // ────────────────────────────────────────────────────────────────

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.ink300,
                  ),
                  const SizedBox(height: 12),
                  Text('Could not load shops', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  Text(
                    'Check your internet connection and try again.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // ────────────────────────────────────────────────────────────────
        // Search filter
        // ────────────────────────────────────────────────────────────────

        final query = widget.search.trim().toLowerCase();

        final filtered = query.isEmpty
            ? docs
            : docs.where((doc) {
                final data = doc.data();

                final shopName = (data['shopName'] as String? ?? '')
                    .toLowerCase();

                final ownerName = (data['ownerName'] as String? ?? '')
                    .toLowerCase();

                final phone =
                    (data['mobile'] as String? ??
                            data['phone'] as String? ??
                            '')
                        .toLowerCase();

                final email = (data['email'] as String? ?? '').toLowerCase();

                return shopName.contains(query) ||
                    ownerName.contains(query) ||
                    phone.contains(query) ||
                    email.contains(query);
              }).toList();

        // ────────────────────────────────────────────────────────────────
        // Empty state
        // ────────────────────────────────────────────────────────────────

        if (filtered.isEmpty) {
          return EmptyState(
            icon: widget.status == 'pending'
                ? Icons.person_add_alt_1_rounded
                : Icons.store_outlined,
            title: widget.status == 'pending'
                ? widget.locale.t('no_shop_requests')
                : widget.locale.t('no_active_shops'),
            subtitle: widget.status == 'pending'
                ? widget.locale.t('no_shop_requests_sub')
                : widget.locale.t('no_active_shops_sub'),
          );
        }

        // ────────────────────────────────────────────────────────────────
        // Single order stream for all shops to eliminate flicker
        // ────────────────────────────────────────────────────────────────

        return StreamBuilder<List<OrderModel>>(
          stream: _ordersStream,
          builder: (context, orderSnapshot) {
            final allOrders = orderSnapshot.data ?? [];
            final Map<String, List<OrderModel>> ordersByShop = {};
            for (final o in allOrders) {
              ordersByShop.putIfAbsent(o.shopId, () => []).add(o);
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (_, index) {
                final data = filtered[index].data();
                final shopUid = filtered[index].id;
                final shopOrders = ordersByShop[shopUid] ?? const [];

                return _ShopCard(
                  key: ValueKey(shopUid),
                  shopUid: shopUid,
                  data: data,
                  distributorId: widget.distributorId,
                  locale: widget.locale,
                  status: widget.status,
                  orders: shopOrders,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shop card
// ─────────────────────────────────────────────────────────────────────────────

class _ShopCard extends StatefulWidget {
  final String shopUid;
  final Map<String, dynamic> data;
  final String distributorId;
  final LocaleState locale;
  final String status;
  final List<OrderModel> orders;

  const _ShopCard({
    super.key,
    required this.shopUid,
    required this.data,
    required this.distributorId,
    required this.locale,
    required this.status,
    this.orders = const [],
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  bool _actionLoading = false;

  // ─────────────────────────────────────────────────────────────────────
  // Approve / reject
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _updateStatus(String newStatus) async {
    if (_actionLoading) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await AuthService.updateShopStatus(
        distributorId: widget.distributorId,
        shopUid: widget.shopUid,
        status: newStatus,
      );

      if (!mounted) return;

      final shopName = widget.data['shopName'] as String? ?? 'Shop';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'active'
                ? '$shopName has been approved ✓'
                : '$shopName has been rejected.',
          ),
          backgroundColor: newStatus == 'active'
              ? AppColors.dairyGreen500
              : AppColors.red500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Reject confirmation
  // ─────────────────────────────────────────────────────────────────────

  void _confirmReject(BuildContext context) {
    if (_actionLoading) return;

    final shopName = widget.data['shopName'] as String? ?? 'this shop';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Reject Shop Request?',
            style: AppTextStyles.h4,
          ),
          content: Text(
            'Are you sure you want to reject the request from $shopName?\n\n'
            'The shop will see that their distributor request was rejected.',
            style: AppTextStyles.body,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _updateStatus('rejected');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Build card
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final isPending = widget.status == 'pending';

    final shopName = data['shopName'] as String? ?? '—';

    final ownerName = data['ownerName'] as String? ?? '—';

    final phone = data['mobile'] as String? ?? data['phone'] as String? ?? '—';

    final email = data['email'] as String? ?? '—';

    final address = data['address'] as String? ?? '—';

    final totalOrders = widget.orders.isNotEmpty
        ? widget.orders.length
        : ((data['totalOrders'] as num?)?.toInt() ?? 0);

    final totalPurchase = widget.orders.isNotEmpty
        ? widget.orders.fold<double>(0.0, (acc, o) => acc + o.totalAmount)
        : ((data['totalPurchase'] as num?)?.toDouble() ?? 0.0);

    final outstanding = widget.orders.isNotEmpty
        ? widget.orders
            .where((o) => o.paymentStatus.toLowerCase() != 'paid')
            .fold<double>(0.0, (acc, o) => acc + o.totalAmount)
        : ((data['outstanding'] as num?)?.toDouble() ?? 0.0);

    final createdAt = data['createdAt'] as Timestamp?;

    final registeredOn = createdAt != null
        ? _formatDate(createdAt.toDate())
        : null;

    return GestureDetector(
      onTap: !isPending
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerProfileScreen(
                    shopData: widget.data,
                    shopUid: widget.shopUid,
                  ),
                ),
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? AppColors.amber500.withValues(alpha: 0.6)
                : AppColors.border,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.milkBlue900.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────────────────────────────────────────────────────────
            // Avatar + name + status
            // ───────────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPending
                          ? [AppColors.amber500, const Color(0xFFE8920A)]
                          : [AppColors.milkBlue700, AppColors.milkBlue500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      shopName.isNotEmpty ? shopName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName, style: AppTextStyles.bodyBold),

                      const SizedBox(height: 2),

                      Text(ownerName, style: AppTextStyles.caption),

                      if (registeredOn != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Registered $registeredOn',
                          style: AppTextStyles.overline,
                        ),
                      ],
                    ],
                  ),
                ),

                AppBadge(
                  label: isPending
                      ? widget.locale.t('pay_pending')
                      : widget.locale.t('shop_active'),
                  variant: isPending
                      ? BadgeVariant.warning
                      : BadgeVariant.success,
                  showDot: false,
                ),
              ],
            ),

            // ───────────────────────────────────────────────────────────
            // SHOP REQUEST BANNER
            // ───────────────────────────────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.amber500,
                      size: 19,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Shop Request',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.ink700,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            'This shop wants to join your distribution network.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            const Divider(height: 1, color: AppColors.border),

            const SizedBox(height: 10),

            // ───────────────────────────────────────────────────────────
            // Contact information
            // ───────────────────────────────────────────────────────────
            _iconRow(Icons.phone_outlined, phone),

            const SizedBox(height: 5),

            _iconRow(Icons.email_outlined, email),

            const SizedBox(height: 5),

            _iconRow(Icons.location_on_outlined, address),

            // ───────────────────────────────────────────────────────────
            // Active shop statistics
            // ───────────────────────────────────────────────────────────
            if (!isPending) ...[
              const SizedBox(height: 12),

              const Divider(height: 1, color: AppColors.border),

              const SizedBox(height: 10),

              Row(
                children: [
                  _StatChip(
                    label: widget.locale.t('nav_orders'),
                    value: '$totalOrders',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.milkBlue600,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: widget.locale.t('total_purchase'),
                    value: totalPurchase >= 1000
                        ? '₹${(totalPurchase / 1000).toStringAsFixed(1)}k'
                        : '₹${totalPurchase.toStringAsFixed(0)}',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.dairyGreen700,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: widget.locale.t('outstanding'),
                    value: '₹${outstanding.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: outstanding > 0
                        ? AppColors.red600
                        : AppColors.dairyGreen700,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view profile →',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.milkBlue600,
                    ),
                  ),
                ],
              ),
            ],

            // ───────────────────────────────────────────────────────────
            // Pending request actions
            // ───────────────────────────────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 14),

              Text(
                'Shop Request',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.ink700,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.dairyGreen700,
                      bgColor: AppColors.dairyGreen100,
                      loading: _actionLoading,
                      onTap: () {
                        _updateStatus('active');
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: AppColors.red600,
                      bgColor: AppColors.red100,
                      loading: _actionLoading,
                      onTap: () {
                        _confirmReject(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Small contact row
  // ─────────────────────────────────────────────────────────────────────

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.ink500),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Date
  // ─────────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approve / Reject button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 17),

                  const SizedBox(width: 6),

                  Text(
                    label,
                    style: AppTextStyles.captionBold.copyWith(color: color),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active shop stat chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.captionBold.copyWith(color: color),
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    label,
                    style: AppTextStyles.overline,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
