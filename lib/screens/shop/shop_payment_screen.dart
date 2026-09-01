import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/gradient_header.dart';

class ShopPaymentScreen extends StatefulWidget {
  const ShopPaymentScreen({super.key});

  @override
  State<ShopPaymentScreen> createState() => _ShopPaymentScreenState();
}

class _ShopPaymentScreenState extends State<ShopPaymentScreen> {
  String _paymentMethod = 'upi';
  bool _paid = false;

  static const _methods = [
    ('upi', Icons.qr_code_2, 'pay_upi'),
    ('cod', Icons.money, 'pay_cod'),
    ('bank', Icons.account_balance_outlined, 'pay_bank'),
    ('credit', Icons.credit_card_outlined, 'pay_credit'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('nav_payments'),
            subtitle: 'Invoice #INV-1042',
          ),
          Expanded(
            child: _paid
                ? _buildSuccessView(context, locale)
                : _buildPaymentView(context, locale),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentView(BuildContext context, LocaleState locale) {
    final auth = AuthStateScope.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Invoice info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.milkBlue700, AppColors.milkBlue500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.t('invoice_no'),
                            style: AppTextStyles.overline.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                          Text(
                            '#INV-1042',
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppBadge(
                      label: locale.t('pay_pending'),
                      variant: BadgeVariant.error,
                      showDot: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _invoiceCell(
                      locale.t('amount_due'),
                      '₹${(auth.shopProfile?.outstanding ?? 0).toStringAsFixed(0)}',
                      Colors.white70,
                      Colors.white,
                    ),
                    _invoiceCell(
                      locale.t('prev_outstanding'),
                      '₹${(auth.shopProfile?.outstanding ?? 0).toStringAsFixed(0)}',
                      Colors.white70,
                      Colors.white,
                    ),
                    _invoiceCell(
                      locale.t('total_payable'),
                      '₹${(auth.shopProfile?.outstanding ?? 0).toStringAsFixed(0)}',
                      Colors.white70,
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Payment method selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.t('payment_method'), style: AppTextStyles.h4),
                const SizedBox(height: 12),
                ..._methods.map((m) {
                  final selected = _paymentMethod == m.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = m.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.milkBlue50
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.milkBlue600
                                : AppColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              m.$2,
                              color: selected
                                  ? AppColors.milkBlue700
                                  : AppColors.ink500,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(locale.t(m.$3), style: AppTextStyles.body),
                            const Spacer(),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.milkBlue600,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _paid = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dairyGreen500,
              ),
              child: Text(
                '${locale.t('confirm')} ₹1,200',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, LocaleState locale) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.dairyGreen500, AppColors.dairyGreen700],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dairyGreen500.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            locale.t('payment_success'),
            style: AppTextStyles.h3.copyWith(color: AppColors.dairyGreen700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment has been processed successfully',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dairyGreen100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _detailRow(locale.t('transaction_id'), 'TXN9876543'),
                const SizedBox(height: 8),
                _detailRow(
                  locale.t('amount_paid'),
                  '₹1,200',
                  valueColor: AppColors.dairyGreen700,
                ),
                const SizedBox(height: 8),
                _detailRow(
                  locale.t('remaining_balance'),
                  '₹2,240',
                  valueColor: AppColors.amber600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: Text(locale.t('view_receipt')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.milkBlue600,
                    side: const BorderSide(color: AppColors.milkBlue600),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(locale.t('download_receipt')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _paid = false),
            child: const Text('Make Another Payment'),
          ),
        ],
      ),
    );
  }

  Widget _invoiceCell(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(color: valueColor),
          ),
          Text(
            label,
            style: AppTextStyles.overline.copyWith(color: labelColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.captionBold.copyWith(
            color: valueColor ?? AppColors.ink900,
          ),
        ),
      ],
    );
  }
}
