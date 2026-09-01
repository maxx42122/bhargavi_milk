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

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _search = '';
  String _statusFilter = 'All';

  final _statuses = [
    'All',
    'pending',
    'confirmed',
    'prepared',
    'delivered',
    'completed',
    'rejected',
  ];

  String _formatStatusLabel(String s) {
    if (s == 'All') return 'All';
    return s[0].toUpperCase() + s.substring(1);
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
            title: locale.t('nav_orders'),
            subtitle: 'Distributor Orders Management',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                AppSearchBar(
                  hint: '${locale.t("search")} orders…',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statuses.map((s) {
                      final active = _statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
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
                              _formatStatusLabel(s),
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
                      final filtered = allOrders.where((o) {
                        if (_search.isEmpty) return true;
                        final q = _search.toLowerCase();
                        final matchesShop =
                            o.shopName.toLowerCase().contains(q);
                        final matchesNum =
                            o.orderNumber.toLowerCase().contains(q);
                        final matchesId = o.id.toLowerCase().contains(q);
                        final matchesProducts = o.products.any(
                          (p) => p.toLowerCase().contains(q),
                        );
                        return matchesShop ||
                            matchesNum ||
                            matchesId ||
                            matchesProducts;
                      }).toList();

                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: locale.t('no_data'),
                          subtitle: _statusFilter == 'All'
                              ? 'No orders placed yet.'
                              : 'No $_statusFilter orders found.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
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
        ? order.products.join(' • ')
        : (order.items.isNotEmpty
            ? order.items
                .map((i) => '${i.productName} × ${i.quantity}')
                .join(' • ')
            : 'Order details');

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
                  label: order.status,
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
                  label: order.paymentStatus,
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
            label: _currentStatus,
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
                label: widget.order.paymentStatus,
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
                      child: Text(item.productName, style: AppTextStyles.body),
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
              'Delivery Charge',
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
            'Payment Method',
            widget.order.paymentMethod.toUpperCase(),
            color: AppColors.ink700,
          ),
          _totalRow(
            'Payment Status',
            widget.order.paymentStatus,
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
      ('Pending', isPending),
      ('Confirmed', isConfirmed),
      ('Prepared', isPrepared),
      ('Delivered', isDelivered),
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
            _isUpdating ? 'Updating Status…' : 'Update Order Status (${_currentStatus})',
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
