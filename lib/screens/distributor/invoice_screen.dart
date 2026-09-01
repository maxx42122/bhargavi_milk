import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../state/locale_state.dart';

class InvoiceScreen extends StatelessWidget {
  final bool embedded;
  const InvoiceScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, locale),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInvoice(locale),
                  const SizedBox(height: 20),
                  _buildActions(context, locale),
                ],
              ),
            ),
          ),
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
          if (!embedded)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          Expanded(
            child: Text(
              locale.t('invoice'),
              style: AppTextStyles.h4.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoice(LocaleState locale) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distributor info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              Icons.water_drop,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bhargavi Distributors',
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '123, Dairy Road, Pune – 411001',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'Phone: 9876543210',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        'GST: 27ABCDE1234F1Z5',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Invoice number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      locale.t('invoice').toUpperCase(),
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      '#INV-1042',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '23 Aug 2026',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bill to
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BILL TO',
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.milkBlue700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Sharma Kirana Store', style: AppTextStyles.bodyBold),
                Text(
                  '12, MG Road, Pune – 411001',
                  style: AppTextStyles.caption,
                ),
                Text('Owner: Rajesh Sharma', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Divider(height: 1),
          // Product table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.milkBlue50,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    locale.t('product_name').toUpperCase(),
                    style: AppTextStyles.overline,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'QTY',
                    style: AppTextStyles.overline,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    locale.t('unit_price').toUpperCase(),
                    style: AppTextStyles.overline,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    locale.t('amount').toUpperCase(),
                    style: AppTextStyles.overline,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Line items
          ..._lineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTextStyles.body),
                        Text(item.packSize, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.qty}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${(item.qty * item.price).toStringAsFixed(0)}',
                      style: AppTextStyles.bodyBold,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Totals
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _totalRow(locale.t('subtotal'), '₹1,066'),
                _totalRow(
                  locale.t('discount'),
                  '−₹66',
                  color: AppColors.dairyGreen700,
                ),
                _totalRow('${locale.t('tax')} (0%)', '₹0'),
                const Divider(height: 16),
                _totalRow(
                  locale.t('grand_total'),
                  '₹1,000',
                  bold: true,
                  color: AppColors.milkBlue700,
                  large: true,
                ),
                const SizedBox(height: 8),
                _totalRow(
                  locale.t('amount_paid'),
                  '₹1,000',
                  color: AppColors.dairyGreen700,
                ),
                _totalRow(
                  locale.t('balance_due'),
                  '₹0',
                  bold: true,
                  color: AppColors.dairyGreen700,
                ),
              ],
            ),
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
    bool large = false,
  }) {
    final style = bold ? AppTextStyles.bodyBold : AppTextStyles.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: style.copyWith(color: color, fontSize: large ? 18 : null),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, LocaleState locale) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            icon: Icons.download_outlined,
            label: locale.t('download_pdf'),
            primary: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.print_outlined,
            label: locale.t('print'),
            primary: false,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionBtn(
            icon: Icons.share_outlined,
            label: locale.t('share'),
            primary: false,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppColors.milkBlue600 : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primary ? AppColors.milkBlue600 : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : AppColors.milkBlue600,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.captionBold.copyWith(
                color: primary ? Colors.white : AppColors.milkBlue600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static const _lineItems = [
    _Item('Full Cream Milk', '1L', 8, 54.0),
    _Item('Fresh Curd', '500g', 4, 40.0),
    _Item('Buttermilk', '500ml', 3, 22.0),
  ];
}

class _Item {
  final String name;
  final String packSize;
  final int qty;
  final double price;
  const _Item(this.name, this.packSize, this.qty, this.price);
}
