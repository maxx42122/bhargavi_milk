import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../data/mock_data.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/kpi_card.dart';

class PaymentsOutstandingScreen extends StatefulWidget {
  const PaymentsOutstandingScreen({super.key});

  @override
  State<PaymentsOutstandingScreen> createState() =>
      _PaymentsOutstandingScreenState();
}

class _PaymentsOutstandingScreenState extends State<PaymentsOutstandingScreen> {
  String _search = '';

  List<MockPayment> get _filtered => mockPayments.where((p) {
    return _search.isEmpty ||
        p.shopName.toLowerCase().contains(_search.toLowerCase()) ||
        p.invoiceNo.toLowerCase().contains(_search.toLowerCase());
  }).toList();

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('nav_payments'),
            subtitle: locale.t('pending_payments'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPI row
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(
                        width: 170,
                        child: KpiCard(
                          label: locale.t('total_collected'),
                          value: '₹42,600',
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.dairyGreen700,
                          iconBg: AppColors.dairyGreen100,
                          delta: '+12%',
                          deltaPositive: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: KpiCard(
                          label: locale.t('todays_collection'),
                          value: '₹8,320',
                          icon: Icons.today_rounded,
                          delta: '+5%',
                          deltaPositive: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: KpiCard(
                          label: locale.t('pending_payments'),
                          value: '₹6,480',
                          icon: Icons.hourglass_empty,
                          iconColor: AppColors.amber600,
                          iconBg: AppColors.amber100,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 170,
                        child: KpiCard(
                          label: locale.t('outstanding_amount'),
                          value: '₹15,400',
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.red600,
                          iconBg: AppColors.red100,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppSearchBar(
                  hint: '${locale.t("search")} payments…',
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 16),
                // Payments list
                ..._filtered.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentRow(payment: p, locale: locale),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final MockPayment payment;
  final LocaleState locale;
  const _PaymentRow({required this.payment, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _methodColor(payment.method).$1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _methodIcon(payment.method),
                  color: _methodColor(payment.method).$2,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.shopName, style: AppTextStyles.bodyBold),
                    Text(
                      '${payment.invoiceNo} • ${payment.date}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.data,
                  ),
                  const SizedBox(height: 4),
                  AppBadge(
                    label: payment.status,
                    variant: paymentStatusVariant(payment.status),
                    showDot: false,
                  ),
                ],
              ),
            ],
          ),
          if (payment.transactionId != '—') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.tag, size: 13, color: AppColors.ink500),
                const SizedBox(width: 4),
                Text(
                  payment.transactionId,
                  style: AppTextStyles.caption.copyWith(fontFamily: 'Inter'),
                ),
                const Spacer(),
                Text(
                  payment.method,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(locale.t('record_payment'), AppColors.milkBlue600),
              const SizedBox(width: 8),
              _actionBtn(locale.t('send_reminder'), AppColors.amber600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(color: color),
        ),
      ),
    );
  }

  IconData _methodIcon(String method) {
    return switch (method.toLowerCase()) {
      'upi' => Icons.qr_code_2,
      'bank transfer' => Icons.account_balance_outlined,
      'cash' => Icons.money,
      _ => Icons.credit_card_outlined,
    };
  }

  (Color, Color) _methodColor(String method) {
    return switch (method.toLowerCase()) {
      'upi' => (AppColors.milkBlue100, AppColors.milkBlue700),
      'bank transfer' => (AppColors.dairyGreen100, AppColors.dairyGreen700),
      'cash' => (AppColors.amber100, AppColors.amber600),
      _ => (AppColors.milkBlue50, AppColors.ink700),
    };
  }
}
