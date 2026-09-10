import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../services/pdf_receipt_service.dart';
import '../../services/shop_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import 'shop_payment_screen.dart';

class ShopOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const ShopOrderDetailScreen({super.key, required this.order});

  @override
  State<ShopOrderDetailScreen> createState() => _ShopOrderDetailScreenState();
}

class _ShopOrderDetailScreenState extends State<ShopOrderDetailScreen> {
  Map<String, String>? _distributorInfo;

  @override
  void initState() {
    super.initState();
    _loadDistributorInfo();
  }

  Future<void> _loadDistributorInfo() async {
    if (widget.order.distributorId.isNotEmpty) {
      final info = await ShopService.fetchDistributorInfo(widget.order.distributorId);
      if (mounted) setState(() => _distributorInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final isPendingPayment = widget.order.paymentStatus.toLowerCase() == 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, locale)),
          SliverToBoxAdapter(child: _buildShopDeliveryInfo(locale)),
          SliverToBoxAdapter(child: _buildLineItems(locale)),
          SliverToBoxAdapter(child: _buildTotals(context, locale)),
          SliverToBoxAdapter(child: _buildTimeline(locale)),
          SliverToBoxAdapter(child: _buildInvoiceActions(context, locale)),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: isPendingPayment
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.milkBlue900.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopPaymentScreen(
                          order: widget.order,
                          amountDue: widget.order.totalAmount,
                          distributorId: widget.order.distributorId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.payment_rounded, color: Colors.white),
                    label: Text(
                      '${locale.t("pay_now")} (₹${widget.order.totalAmount.toStringAsFixed(widget.order.totalAmount % 1 == 0 ? 0 : 2)})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dairyGreen600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, LocaleState locale) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
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
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            tooltip: locale.t('view_receipt'),
            onPressed: () => PdfReceiptService.previewReceipt(
              context: context,
              order: widget.order,
              distributorInfo: _distributorInfo,
            ),
          ),
          AppBadge(
            label: locale.translateStatus(widget.order.orderStatus),
            variant: orderStatusVariant(widget.order.orderStatus),
            showDot: false,
          ),
        ],
      ),
    );
  }

  Widget _buildShopDeliveryInfo(LocaleState locale) {
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
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.ink500),
              const SizedBox(width: 6),
              Text('${locale.t('order_date')}: $formattedDate', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.milkBlue600),
              const SizedBox(width: 6),
              Text(
                '${locale.t('tag_delivery')}: ${locale.translateDate(widget.order.deliveryDate)} (${locale.translateDate(widget.order.deliveryTime)})',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.milkBlue700),
              ),
            ],
          ),
          if (widget.order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.order.deliveryAddress, style: AppTextStyles.caption),
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
          if (widget.order.items.isEmpty)
            ...widget.order.products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(p, style: AppTextStyles.body),
              ),
            )
          else
            ...widget.order.items.map(
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
                                Text(
                                  locale.translateProduct(item.name),
                                  style: AppTextStyles.body,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.packSize.isNotEmpty)
                                  Text(
                                    '${item.packSize} • ${locale.translateUnit(item.unit)}',
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

  Widget _buildTotals(BuildContext context, LocaleState locale) {
    final isPaid = widget.order.paymentStatus.toLowerCase() == 'paid';

    return _card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _totalRow(
            locale.t('subtotal'),
            '₹${widget.order.subtotal.toStringAsFixed(widget.order.subtotal % 1 == 0 ? 0 : 2)}',
          ),
          if (widget.order.deliveryCharge > 0)
            _totalRow(
              locale.t('delivery_charge'),
              '₹${widget.order.deliveryCharge.toStringAsFixed(0)}',
            ),
          if (widget.order.discount > 0)
            _totalRow(
              locale.t('discount'),
              '−₹${widget.order.discount.toStringAsFixed(0)}',
              color: AppColors.dairyGreen700,
            ),
          const Divider(height: 16),
          _totalRow(
            locale.t('grand_total'),
            '₹${widget.order.total.toStringAsFixed(widget.order.total % 1 == 0 ? 0 : 2)}',
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
            color: isPaid ? AppColors.dairyGreen700 : AppColors.red600,
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
    final status = widget.order.status.toLowerCase();

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
                  child: Text(
                    locale.t('order_cancelled'),
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.red600),
                  ),
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

  Widget _buildInvoiceActions(BuildContext context, LocaleState locale) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.t('nav_bills'), style: AppTextStyles.h4),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfReceiptService.previewReceipt(
                    context: context,
                    order: widget.order,
                    distributorInfo: _distributorInfo,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: Text(locale.t('view')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.milkBlue600,
                    side: const BorderSide(color: AppColors.milkBlue600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfReceiptService.printReceipt(
                    order: widget.order,
                    distributorInfo: _distributorInfo,
                  ),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(locale.t('print')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink700,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => PdfReceiptService.shareReceipt(
                    order: widget.order,
                    distributorInfo: _distributorInfo,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(locale.t('share')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink700,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
