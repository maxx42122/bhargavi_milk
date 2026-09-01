import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import 'shop_order_detail_screen.dart';

class ShopOrderHistoryScreen extends StatelessWidget {
  final String? distributorId;
  final String? shopUid;

  const ShopOrderHistoryScreen({
    super.key,
    this.distributorId,
    this.shopUid,
  });

  String _resolveDistributorId(BuildContext context) {
    if (distributorId != null && distributorId!.isNotEmpty) {
      return distributorId!;
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
    if (shopUid != null && shopUid!.isNotEmpty) {
      return shopUid!;
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
    final resolvedDistributorId = _resolveDistributorId(context);
    final resolvedShopUid = _resolveShopUid(context);

    if (resolvedDistributorId.isEmpty || resolvedShopUid.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            GradientHeader(
              title: locale.t('order_history'),
              subtitle: 'Shop Orders',
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
        final orders = snapshot.data ?? [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              GradientHeader(
                title: locale.t('order_history'),
                subtitle: isLoading
                    ? 'Loading orders…'
                    : '${orders.length} ${orders.length == 1 ? "order" : "orders"}',
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : orders.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: locale.t('no_data'),
                            subtitle:
                                'You have not placed any orders yet. Visit products to place your first order.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: orders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final o = orders[i];
                              return _ShopOrderCard(
                                order: o,
                                formattedDate: _formatDate(o.createdAt),
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
}

class _ShopOrderCard extends StatelessWidget {
  final OrderModel order;
  final String formattedDate;

  const _ShopOrderCard({
    required this.order,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final productsSummary = order.products.isNotEmpty
        ? order.products.join(', ')
        : (order.items.isNotEmpty
            ? order.items.map((i) => '${i.name} × ${i.quantity}').join(', ')
            : 'Order Details');

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
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.milkBlue900.withValues(alpha: 0.03),
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
                    'Delivery: ${order.deliveryDate}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '₹${order.total.toStringAsFixed(order.total % 1 == 0 ? 0 : 2)}',
                  style: AppTextStyles.data,
                ),
                const Spacer(),
                AppBadge(
                  label: order.orderStatus,
                  variant: orderStatusVariant(order.orderStatus),
                  showDot: false,
                ),
                const SizedBox(width: 8),
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
