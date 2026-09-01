import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';

class ShopOrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const ShopOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, locale)),
          SliverToBoxAdapter(child: _buildShopDeliveryInfo(locale)),
          SliverToBoxAdapter(child: _buildLineItems(locale)),
          SliverToBoxAdapter(child: _buildTotals(locale)),
          SliverToBoxAdapter(child: _buildTimeline(locale)),
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
                  order.orderNumber,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          AppBadge(
            label: order.orderStatus,
            variant: orderStatusVariant(order.orderStatus),
            showDot: false,
          ),
        ],
      ),
    );
  }

  Widget _buildShopDeliveryInfo(LocaleState locale) {
    final formattedDate = order.createdAt != null
        ? '${order.createdAt!.day.toString().padLeft(2, '0')}/${order.createdAt!.month.toString().padLeft(2, '0')}/${order.createdAt!.year} ${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
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
                label: order.paymentStatus,
                variant: paymentStatusVariant(order.paymentStatus),
                showDot: false,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.shopName, style: AppTextStyles.bodyBold),
          if (order.shopOwner.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(order.shopOwner, style: AppTextStyles.caption),
          ],
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.ink500),
              const SizedBox(width: 6),
              Text('Placed: $formattedDate', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.milkBlue600),
              const SizedBox(width: 6),
              Text('Delivery: ${order.deliveryDate} (${order.deliveryTime})',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.milkBlue700)),
            ],
          ),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(order.deliveryAddress, style: AppTextStyles.caption),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItems(LocaleState locale) {
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
                flex: 2,
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
          if (order.items.isEmpty)
            ...order.products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p, style: AppTextStyles.body),
              ),
            )
          else
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Text(item.emoji.isNotEmpty ? item.emoji : '🥛',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: AppTextStyles.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                if (item.packSize.isNotEmpty)
                                  Text(
                                    '${item.packSize} • ${item.unit}',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: AppColors.ink500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
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
                        '₹${item.totalPrice.toStringAsFixed(item.totalPrice % 1 == 0 ? 0 : 2)}',
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
    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _totalRow(
            locale.t('subtotal'),
            '₹${order.subtotal.toStringAsFixed(order.subtotal % 1 == 0 ? 0 : 2)}',
          ),
          if (order.deliveryCharge > 0)
            _totalRow(
              locale.t('delivery_charge'),
              '₹${order.deliveryCharge.toStringAsFixed(0)}',
            ),
          if (order.discount > 0)
            _totalRow(
              locale.t('discount'),
              '−₹${order.discount.toStringAsFixed(0)}',
              color: AppColors.dairyGreen700,
            ),
          const Divider(height: 16),
          _totalRow(
            locale.t('grand_total'),
            '₹${order.total.toStringAsFixed(order.total % 1 == 0 ? 0 : 2)}',
            bold: true,
            color: AppColors.milkBlue700,
          ),
          const SizedBox(height: 8),
          _totalRow(
            'Payment Method',
            order.paymentMethod.toUpperCase(),
            color: AppColors.ink700,
          ),
          _totalRow(
            'Payment Status',
            order.paymentStatus,
            bold: true,
            color: order.paymentStatus.toLowerCase() == 'paid'
                ? AppColors.dairyGreen700
                : AppColors.red600,
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
            style: (bold ? AppTextStyles.bodyBold : AppTextStyles.body).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(LocaleState locale) {
    final status = order.status.toLowerCase();

    final isConfirmed = status == 'confirmed' ||
        status == 'prepared' ||
        status == 'packed' ||
        status == 'out for delivery' ||
        status == 'delivered' ||
        status == 'completed';
    final isPacked = status == 'prepared' ||
        status == 'packed' ||
        status == 'out for delivery' ||
        status == 'delivered' ||
        status == 'completed';
    final isOut = status == 'out for delivery' ||
        status == 'delivered' ||
        status == 'completed';
    final isDelivered = status == 'delivered' || status == 'completed';
    final isCancelled = status == 'cancelled' || status == 'rejected';

    final steps = [
      (locale.t('order_new'), true, ''),
      (locale.t('order_confirmed'), isConfirmed && !isCancelled, ''),
      (locale.t('order_packed'), isPacked && !isCancelled, ''),
      (locale.t('order_out_delivery'), isOut && !isCancelled, ''),
      (locale.t('order_delivered'), isDelivered && !isCancelled, ''),
    ];

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(locale.t('order_timeline'), style: AppTextStyles.h4),
              const Spacer(),
              if (isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Cancelled',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.red600)),
                ),
            ],
          ),
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
                        color: step.$2 ? AppColors.milkBlue600 : AppColors.border,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.$2 ? AppColors.milkBlue600 : AppColors.border,
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
                        color: step.$2 ? AppColors.milkBlue100 : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.$1,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: step.$2 ? AppColors.ink900 : AppColors.ink300,
                          ),
                        ),
                      ],
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
