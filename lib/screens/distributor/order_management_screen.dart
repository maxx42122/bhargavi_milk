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
import 'total_orders_summary_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _search = '';
  String _dateFilter = 'Today'; // Default is strictly Today!
  String _statusFilter = 'All';

  final _dateFilters = [
    'Today',
    'Yesterday',
    'This Week',
    'All Orders',
  ];

  final _statuses = [
    'All',
    'pending',
    'confirmed',
    'prepared',
    'delivered',
    'completed',
    'rejected',
  ];

  bool _isOrderInDateFilter(OrderModel order) {
    final dt = order.createdAt ?? DateTime.now();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_dateFilter) {
      case 'Today':
        return dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(todayEnd.add(const Duration(seconds: 1)));
      case 'Yesterday':
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(
          yestStart.year,
          yestStart.month,
          yestStart.day,
          23,
          59,
          59,
        );
        return dt.isAfter(yestStart.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(yestEnd.add(const Duration(seconds: 1)));
      case 'This Week':
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return dt.isAfter(weekStart.subtract(const Duration(seconds: 1)));
      case 'All Orders':
      default:
        return true;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recently';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final auth = AuthStateScope.of(context);
    final distributorId =
        auth.distributorId ?? AuthService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: _dateFilter == 'Today'
                ? locale.t('today_orders')
                : locale.t('nav_orders'),
            subtitle: _dateFilter == 'Today'
                ? 'Showing all orders received today'
                : locale.t('dist_orders_mgmt'),
            actions: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TotalOrdersSummaryScreen(
                        initialDistributorId: distributorId,
                        initialDateFilter: _dateFilter,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.milkBlue800,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(
                  Icons.analytics_rounded,
                  size: 16,
                  color: AppColors.milkBlue700,
                ),
                label: Text(
                  _dateFilter == 'Today'
                      ? locale.t('total_today_orders')
                      : locale.t('total_orders'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.milkBlue900,
                  ),
                ),
              ),
            ],
          ),

          // ── Quick Summary Action Banner ──────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TotalOrdersSummaryScreen(
                    initialDistributorId: distributorId,
                    initialDateFilter: _dateFilter,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.milkBlue800, AppColors.milkBlue600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.milkBlue700.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.checklist_rtl_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateFilter == 'Today'
                              ? 'Today Customer Checklist & Totals'
                              : 'Total Orders & Brand Summary',
                          style: AppTextStyles.captionBold.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'View customer-wise list, checklist & download PDF',
                          style: AppTextStyles.overline.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          locale.t('view_total_orders'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: AppColors.milkBlue800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.milkBlue800,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                // Date Filter Selector (Today by default!)
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _dateFilters.map((df) {
                      final active = _dateFilter == df;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _dateFilter = df),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.milkBlue700
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: active
                                    ? AppColors.milkBlue700
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (df == 'Today') ...[
                                  Icon(
                                    Icons.today_rounded,
                                    size: 13,
                                    color: active ? Colors.white : AppColors.milkBlue700,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  df == 'Today' ? locale.t('today_orders') : df,
                                  style: TextStyle(
                                    color: active ? Colors.white : AppColors.ink700,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                AppSearchBar(
                  hint: '${locale.t("search")} orders, shop, items…',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 8),

                // Status Filter
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statuses.map((s) {
                      final active = _statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.dairyGreen600
                                  : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: active
                                    ? AppColors.dairyGreen600
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              locale.translateStatus(s),
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.ink700,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: distributorId.isEmpty
                ? Center(
                    child: Text(
                      'Please log in as a distributor to view orders.',
                      style: AppTextStyles.caption,
                    ),
                  )
                : StreamBuilder<List<OrderModel>>(
                    stream: OrderService.streamDistributorOrders(
                      distributorId: distributorId,
                      statusFilter: _statusFilter,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allOrders = snapshot.data ?? [];
                      // Filter by Date (Today by default)
                      final dateFiltered = allOrders.where(_isOrderInDateFilter).toList();

                      final filtered = dateFiltered.where((o) {
                        if (_search.isEmpty) return true;
                        final q = _search.toLowerCase();
                        final matchesShop =
                            o.shopName.toLowerCase().contains(q);
                        final matchesOwner =
                            o.shopOwner.toLowerCase().contains(q);
                        final matchesNum =
                            o.orderNumber.toLowerCase().contains(q);
                        final matchesId = o.id.toLowerCase().contains(q);
                        final matchesProducts = o.products.any(
                          (p) => p.toLowerCase().contains(q),
                        );
                        return matchesShop ||
                            matchesOwner ||
                            matchesNum ||
                            matchesId ||
                            matchesProducts;
                      }).toList();

                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: locale.t('no_data'),
                          subtitle: _dateFilter == 'Today'
                              ? 'No orders placed today yet.'
                              : 'No orders found for the selected filter.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _OrderCard(
                          order: filtered[i],
                          formattedDate: _formatDate(filtered[i].createdAt),
                          locale: locale,
                          distributorId: distributorId,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Fixed Bottom Button: Total Today's Orders & Checklist ────────────────
      bottomSheet: distributorId.isEmpty
          ? null
          : StreamBuilder<List<OrderModel>>(
              stream: OrderService.streamDistributorOrders(
                distributorId: distributorId,
                statusFilter: _statusFilter,
              ),
              builder: (context, snapshot) {
                final allOrders = snapshot.data ?? [];
                final dateFiltered =
                    allOrders.where(_isOrderInDateFilter).toList();
                final totalOrdersCount = dateFiltered.length;
                final totalQty = dateFiltered.fold(
                  0,
                  (sum, o) => sum + o.totalQuantity,
                );
                final totalRupees = dateFiltered.fold(
                  0.0,
                  (sum, o) => sum + o.totalAmount,
                );

                if (dateFiltered.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TotalOrdersSummaryScreen(
                                initialDistributorId: distributorId,
                                initialDateFilter: _dateFilter,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.milkBlue700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.checklist_rtl_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _dateFilter == 'Today'
                                          ? locale.t('total_today_orders')
                                          : 'Total Orders & Checklist',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '$totalOrdersCount Orders • $totalQty Pkts • ₹${totalRupees.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    locale.t('view'),
                                    style: const TextStyle(
                                      color: AppColors.milkBlue800,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: AppColors.milkBlue800,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String formattedDate;
  final LocaleState locale;
  final String distributorId;

  const _OrderCard({
    required this.order,
    required this.formattedDate,
    required this.locale,
    required this.distributorId,
  });

  @override
  Widget build(BuildContext context) {
    final productsSummary = order.products.isNotEmpty
        ? order.products.map((p) => locale.translateProduct(p)).join(' • ')
        : (order.items.isNotEmpty
            ? order.items
                .map((i) =>
                    '${locale.translateProduct(i.productName)} × ${i.quantity}')
                .join(' • ')
            : locale.t('order_details'));

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(
            order: order,
            distributorId: distributorId,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.orderNumber,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue700,
                  ),
                ),
                const Spacer(),
                AppBadge(
                  label: locale.translateStatus(order.status),
                  variant: orderStatusVariant(order.status),
                  showDot: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.store_outlined,
                  size: 15,
                  color: AppColors.ink500,
                ),
                const SizedBox(width: 5),
                Text(order.shopName, style: AppTextStyles.body),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.ink500,
                ),
                const SizedBox(width: 5),
                Text(formattedDate, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    productsSummary,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(order.totalAmount % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.data,
                ),
                const SizedBox(width: 10),
                AppBadge(
                  label: locale.translateStatus(order.paymentStatus),
                  variant: paymentStatusVariant(order.paymentStatus),
                  showDot: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Details Screen ──────────────────────────────────────────────────────

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final String distributorId;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.distributorId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_currentStatus == newStatus) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final distId = widget.distributorId.isNotEmpty
          ? widget.distributorId
          : widget.order.distributorId;

      await OrderService.updateOrderStatus(
        distributorId: distId,
        orderId: widget.order.id,
        newStatus: newStatus,
      );

      if (!mounted) return;
      setState(() {
        _currentStatus = newStatus;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: AppColors.dairyGreen700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.red500,
        ),
      );
    }
  }

  void _showStatusDialog(BuildContext context) {
    const statuses = [
      'pending',
      'confirmed',
      'prepared',
      'delivered',
      'completed',
      'rejected',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Order Status',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 12),
                ...statuses.map((s) {
                  final isSelected = _currentStatus.toLowerCase() == s;
                  return ListTile(
                    leading: AppBadge(
                      label: s,
                      variant: orderStatusVariant(s),
                      showDot: false,
                    ),
                    title: Text(
                      s[0].toUpperCase() + s.substring(1),
                      style: isSelected
                          ? AppTextStyles.bodyBold
                          : AppTextStyles.body,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.dairyGreen700)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateStatus(s);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, locale)),
          SliverToBoxAdapter(child: _buildShopInfo(locale)),
          SliverToBoxAdapter(child: _buildLineItems(locale)),
          SliverToBoxAdapter(child: _buildTotals(locale)),
          SliverToBoxAdapter(child: _buildTimeline(locale)),
          SliverToBoxAdapter(child: _buildActionControls(context, locale)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LocaleState locale) {
    final top = MediaQuery.of(context).padding.top;
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.t('order_details'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  widget.order.orderNumber,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          AppBadge(
            label: locale.translateStatus(_currentStatus),
            variant: orderStatusVariant(_currentStatus),
            showDot: false,
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo(LocaleState locale) {
    final formattedDate = widget.order.createdAt != null
        ? '${widget.order.createdAt!.day.toString().padLeft(2, '0')}/${widget.order.createdAt!.month.toString().padLeft(2, '0')}/${widget.order.createdAt!.year} ${widget.order.createdAt!.hour.toString().padLeft(2, '0')}:${widget.order.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'Recently';

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(locale.t('shop_name'), style: AppTextStyles.overline),
              const Spacer(),
              AppBadge(
                label: locale.translateStatus(widget.order.paymentStatus),
                variant: paymentStatusVariant(widget.order.paymentStatus),
                showDot: false,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.order.shopName, style: AppTextStyles.bodyBold),
          if (widget.order.shopOwner.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(widget.order.shopOwner, style: AppTextStyles.caption),
          ],
          if (widget.order.shopMobile.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('📞 ${widget.order.shopMobile}', style: AppTextStyles.caption),
          ],
          const Divider(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.ink500,
              ),
              const SizedBox(width: 6),
              Text('Placed: $formattedDate', style: AppTextStyles.caption),
            ],
          ),
          if (widget.order.deliveryDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.milkBlue600,
                ),
                const SizedBox(width: 6),
                Text(
                  'Delivery: ${widget.order.deliveryDate} ${widget.order.deliveryTime.isNotEmpty ? "(${widget.order.deliveryTime})" : ""}',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue700,
                  ),
                ),
              ],
            ),
          ],
          if (widget.order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.ink500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.order.deliveryAddress,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItems(LocaleState locale) {
    final items = widget.order.items;

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.t('products'), style: AppTextStyles.h4),
          const SizedBox(height: 12),
          // Header row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  locale.t('product_name'),
                  style: AppTextStyles.overline,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  locale.t('quantity'),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('unit_price'),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('amount'),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No item details available', style: AppTextStyles.caption),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(locale.translateProduct(item.productName), style: AppTextStyles.body),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${item.price.toStringAsFixed(item.price % 1 == 0 ? 0 : 2)}',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${item.subtotal.toStringAsFixed(item.subtotal % 1 == 0 ? 0 : 2)}',
                        style: AppTextStyles.bodyBold,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotals(LocaleState locale) {
    final subtotal = widget.order.subtotal;
    final delivery = widget.order.deliveryCharge;
    final discount = widget.order.discount;
    final total = widget.order.totalAmount;

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _totalRow(locale.t('subtotal'), '₹${subtotal.toStringAsFixed(subtotal % 1 == 0 ? 0 : 2)}'),
          if (discount > 0)
            _totalRow(
              locale.t('discount'),
              '−₹${discount.toStringAsFixed(discount % 1 == 0 ? 0 : 2)}',
              color: AppColors.dairyGreen700,
            ),
          if (delivery > 0)
            _totalRow(
              locale.t('delivery_charge'),
              '+₹${delivery.toStringAsFixed(delivery % 1 == 0 ? 0 : 2)}',
            ),
          const Divider(height: 16),
          _totalRow(
            locale.t('grand_total'),
            '₹${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
            bold: true,
            color: AppColors.milkBlue700,
          ),
          const SizedBox(height: 8),
          _totalRow(
            locale.t('payment_method'),
            locale.translatePaymentMethod(widget.order.paymentMethod).toUpperCase(),
            color: AppColors.ink700,
          ),
          _totalRow(
            locale.t('payment_status'),
            locale.translateStatus(widget.order.paymentStatus),
            bold: true,
            color: widget.order.paymentStatus.toLowerCase() == 'paid'
                ? AppColors.dairyGreen700
                : AppColors.amber600,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: bold ? AppTextStyles.bodyBold : AppTextStyles.body,
          ),
          const Spacer(),
          Text(
            value,
            style: (bold ? AppTextStyles.bodyBold : AppTextStyles.body)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(LocaleState locale) {
    final status = _currentStatus.toLowerCase();

    final isPending = true;
    final isConfirmed = status == 'confirmed' ||
        status == 'prepared' ||
        status == 'packed' ||
        status == 'out for delivery' ||
        status == 'delivered' ||
        status == 'completed';
    final isPrepared = status == 'prepared' ||
        status == 'packed' ||
        status == 'out for delivery' ||
        status == 'delivered' ||
        status == 'completed';
    final isDelivered = status == 'delivered' || status == 'completed';

    final steps = [
      (locale.t('order_new'), isPending),
      (locale.t('order_confirmed'), isConfirmed),
      (locale.t('order_prepared'), isPrepared),
      (locale.t('order_delivered'), isDelivered),
    ];

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.t('order_timeline'), style: AppTextStyles.h4),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) {
            final idx = e.key;
            final step = e.value;
            final isLast = idx == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: step.$2
                            ? AppColors.milkBlue600
                            : AppColors.border,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.$2
                              ? AppColors.milkBlue600
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: step.$2
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: step.$2
                            ? AppColors.milkBlue100
                            : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      step.$1,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: step.$2
                            ? AppColors.ink900
                            : AppColors.ink300,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionControls(BuildContext context, LocaleState locale) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isUpdating ? null : () => _showStatusDialog(context),
          icon: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.edit_note_rounded),
          label: Text(
            _isUpdating ? 'Updating Status…' : 'Update Order Status ($_currentStatus)',
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
