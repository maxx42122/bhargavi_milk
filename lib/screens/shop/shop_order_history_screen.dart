import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../services/pdf_receipt_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import 'shop_order_detail_screen.dart';
import 'shop_payment_screen.dart';

class ShopOrderHistoryScreen extends StatefulWidget {
  final String? distributorId;
  final String? shopUid;

  const ShopOrderHistoryScreen({
    super.key,
    this.distributorId,
    this.shopUid,
  });

  @override
  State<ShopOrderHistoryScreen> createState() => _ShopOrderHistoryScreenState();
}

class _ShopOrderHistoryScreenState extends State<ShopOrderHistoryScreen> {
  String _filter = 'All'; // 'All', 'Pending', 'Delivered', 'Unpaid'

  String _resolveDistributorId(BuildContext context) {
    if (widget.distributorId != null && widget.distributorId!.isNotEmpty) {
      return widget.distributorId!;
    }
    try {
      final auth = AuthStateScope.of(context);
      if (auth.distributorId != null && auth.distributorId!.isNotEmpty) {
        return auth.distributorId!;
      }
      if (auth.shopProfile?.distributorId.isNotEmpty == true) {
        return auth.shopProfile!.distributorId;
      }
    } catch (_) {}
    return '';
  }

  String _resolveShopUid(BuildContext context) {
    if (widget.shopUid != null && widget.shopUid!.isNotEmpty) {
      return widget.shopUid!;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      return currentUid;
    }
    try {
      final auth = AuthStateScope.of(context);
      if (auth.shopProfile?.id.isNotEmpty == true) {
        return auth.shopProfile!.id;
      }
    } catch (_) {}
    return '';
  }

  String _formatDate(DateTime? dt, LocaleState locale) {
    if (dt == null) return locale.t('recently');
    final months = [
      locale.t('month_jan'),
      locale.t('month_feb'),
      locale.t('month_mar'),
      locale.t('month_apr'),
      locale.t('month_may'),
      locale.t('month_jun'),
      locale.t('month_jul'),
      locale.t('month_aug'),
      locale.t('month_sep'),
      locale.t('month_oct'),
      locale.t('month_nov'),
      locale.t('month_dec'),
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
    final resolvedDistributorId = _resolveDistributorId(context);
    final resolvedShopUid = _resolveShopUid(context);

    if (resolvedDistributorId.isEmpty || resolvedShopUid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            GradientHeader(
              title: locale.t('order_history'),
              subtitle: locale.t('shop_orders'),
            ),
            Expanded(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: locale.t('no_data'),
                subtitle: 'Please log in to view your shop orders.',
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamShopOrders(
        distributorId: resolvedDistributorId,
        shopUid: resolvedShopUid,
      ),
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        // Apply filter
        final filteredOrders = allOrders.where((o) {
          if (_filter == 'All') return true;
          if (_filter == 'Pending') {
            return o.status.toLowerCase() == 'pending' ||
                o.orderStatus.toLowerCase() == 'pending';
          }
          if (_filter == 'Delivered') {
            return o.status.toLowerCase() == 'delivered' ||
                o.status.toLowerCase() == 'completed';
          }
          if (_filter == 'Unpaid') {
            return o.paymentStatus.toLowerCase() == 'pending';
          }
          return true;
        }).toList();

        final unpaidCount =
            allOrders.where((o) => o.paymentStatus.toLowerCase() == 'pending').length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              GradientHeader(
                title: locale.t('order_history'),
                subtitle: isLoading
                    ? locale.t('loading')
                    : '${allOrders.length} ${locale.t('nav_orders')} • $unpaidCount ${locale.t('pending')}',
              ),

              // Filter Chips
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('All', locale.t('all'), allOrders.length),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Unpaid',
                      'Unpaid Dues',
                      unpaidCount,
                      badgeColor: AppColors.amber600,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Pending',
                      locale.translateStatus('Pending'),
                      allOrders.where((o) => o.status.toLowerCase() == 'pending').length,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      'Delivered',
                      locale.translateStatus('Delivered'),
                      allOrders
                          .where((o) =>
                              o.status.toLowerCase() == 'delivered' ||
                              o.status.toLowerCase() == 'completed')
                          .length,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrders.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: locale.t('no_data'),
                            subtitle: _filter == 'Unpaid'
                                ? 'No unpaid dues! All your orders are fully settled.'
                                : 'You have no orders in this category.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final o = filteredOrders[i];
                              return _ShopOrderCard(
                                order: o,
                                formattedDate: _formatDate(o.createdAt, locale),
                                locale: locale,
                                distributorId: resolvedDistributorId,
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

  Widget _filterChip(
    String key,
    String label,
    int count, {
    Color? badgeColor,
  }) {
    final active = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.milkBlue600 : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.milkBlue600 : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.captionBold.copyWith(
                color: active ? Colors.white : AppColors.ink700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : (badgeColor ?? AppColors.milkBlue100),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : (badgeColor != null ? Colors.white : AppColors.milkBlue700),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopOrderCard extends StatelessWidget {
  final OrderModel order;
  final String formattedDate;
  final LocaleState locale;
  final String distributorId;

  const _ShopOrderCard({
    required this.order,
    required this.formattedDate,
    required this.locale,
    required this.distributorId,
  });

  @override
  Widget build(BuildContext context) {
    final isUnpaid = order.paymentStatus.toLowerCase() == 'pending';
    final productsSummary = order.products.isNotEmpty
        ? order.products.map((p) => locale.translateProduct(p)).join(', ')
        : (order.items.isNotEmpty
            ? order.items
                .map((i) =>
                    '${locale.translateProduct(i.name)} × ${i.quantity}')
                .join(', ')
            : locale.t('order_details'));

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShopOrderDetailScreen(order: order),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnpaid
                ? AppColors.amber500.withValues(alpha: 0.4)
                : AppColors.border,
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
            Row(
              children: [
                Text(
                  order.orderNumber,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue700,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              productsSummary,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.deliveryDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: AppColors.ink500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${locale.t('tag_delivery')}: ${locale.translateDate(order.deliveryDate)}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '₹${order.total.toStringAsFixed(order.total % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.data,
                ),
                const Spacer(),
                AppBadge(
                  label: locale.translateStatus(order.orderStatus),
                  variant: orderStatusVariant(order.orderStatus),
                  showDot: false,
                ),
                const SizedBox(width: 6),
                AppBadge(
                  label: locale.translateStatus(order.paymentStatus),
                  variant: paymentStatusVariant(order.paymentStatus),
                  showDot: false,
                ),
              ],
            ),
            if (isUnpaid) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => PdfReceiptService.previewReceipt(
                      context: context,
                      order: order,
                    ),
                    icon: const Icon(Icons.receipt_outlined, size: 14),
                    label: Text(locale.t('view')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopPaymentScreen(
                          order: order,
                          amountDue: order.totalAmount,
                          distributorId: distributorId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.payment_rounded, size: 14, color: Colors.white),
                    label: Text(
                      '${locale.t("pay_now")} ₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dairyGreen600,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
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
}
