import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../data/mock_data.dart';
import '../../state/locale_state.dart';
import '../../widgets/gradient_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _selectedPeriod = 1; // 0=daily, 1=weekly, 2=monthly

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('reports'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                onPressed: () {},
                tooltip: locale.t('export'),
              ),
            ],
          ),
          // Tab bar
          Container(
            color: AppColors.cardSurface,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.milkBlue700,
              unselectedLabelColor: AppColors.ink500,
              indicatorColor: AppColors.milkBlue600,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.captionBold,
              tabs: [
                Tab(text: locale.t('daily_sales')),
                Tab(text: locale.t('product_sales')),
                Tab(text: locale.t('shop_sales')),
                Tab(text: locale.t('collection_report')),
                Tab(text: locale.t('outstanding_report')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SalesReportTab(
                  locale: locale,
                  periodSel: _selectedPeriod,
                  onPeriod: (i) => setState(() => _selectedPeriod = i),
                ),
                _ProductSalesTab(locale: locale),
                _ShopSalesTab(locale: locale),
                _CollectionTab(locale: locale),
                _OutstandingTab(locale: locale),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sales Report Tab ──────────────────────────────────────────────────────────

class _SalesReportTab extends StatelessWidget {
  final LocaleState locale;
  final int periodSel;
  final ValueChanged<int> onPeriod;
  const _SalesReportTab({
    required this.locale,
    required this.periodSel,
    required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = salesChartData
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        Row(
          children: [
            _periodChip(locale.t('daily_sales'), 0),
            const SizedBox(width: 8),
            _periodChip(locale.t('weekly_sales'), 1),
            const SizedBox(width: 8),
            _periodChip(locale.t('monthly_sales'), 2),
          ],
        ),
        const SizedBox(height: 16),
        // Summary row
        Row(
          children: [
            _summaryCard('₹67,200', locale.t('total_sales'), AppColors.milkBlue600),
            const SizedBox(width: 10),
            _summaryCard('247', locale.t('nav_orders'), AppColors.dairyGreen700),
            const SizedBox(width: 10),
            _summaryCard('₹272', locale.t('avg_order'), AppColors.amber600),
          ],
        ),
        const SizedBox(height: 16),
        // Bar chart
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
              Text(locale.t('7_day_sales'), style: AppTextStyles.h4),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: salesChartData.map((d) {
                    final frac = (d['amount'] as double) / maxVal;
                    final isMax = d['amount'] == maxVal;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isMax)
                              Text(
                                '₹${((d['amount'] as double) / 1000).toStringAsFixed(1)}k',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppColors.milkBlue600,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              height: 120 * frac,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMax
                                      ? [
                                          AppColors.milkBlue700,
                                          AppColors.milkBlue500,
                                        ]
                                      : [
                                          AppColors.milkBlue100,
                                          const Color(0xFFBDD8F6),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              locale.translateDate(d['day'] as String),
                              style: AppTextStyles.overline,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periodChip(String label, int idx) {
    final active = periodSel == idx;
    return GestureDetector(
      onTap: () => onPeriod(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.milkBlue600 : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.milkBlue600 : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: active ? Colors.white : AppColors.ink700,
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.bodyBold.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Product Sales Tab ─────────────────────────────────────────────────────────

class _ProductSalesTab extends StatelessWidget {
  final LocaleState locale;
  const _ProductSalesTab({required this.locale});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Full Cream Milk 1L', '🥛', 180, '₹9,720', 0.85),
      ('Toned Milk 500ml', '🥛', 162, '₹3,888', 0.77),
      ('Toned Milk 1L', '🥛', 140, '₹6,440', 0.66),
      ('Fresh Curd 500g', '🍶', 98, '₹3,920', 0.46),
      ('Paneer 200g', '🧀', 72, '₹6,480', 0.34),
      ('White Butter 100g', '🧈', 55, '₹3,575', 0.26),
      ('Buttermilk 500ml', '🥤', 48, '₹1,056', 0.23),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(item.$2, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(locale.translateProduct(item.$1), style: AppTextStyles.bodyBold)),
                  Text(
                    item.$4,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.milkBlue700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${item.$3} ${locale.t('items_sold')}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item.$5,
                backgroundColor: AppColors.milkBlue50,
                color: AppColors.milkBlue500,
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shop Sales Tab ────────────────────────────────────────────────────────────

class _ShopSalesTab extends StatelessWidget {
  final LocaleState locale;
  const _ShopSalesTab({required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockShops.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = mockShops[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.milkBlue700, AppColors.milkBlue500],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    s.shopName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.shopName, style: AppTextStyles.bodyBold),
                    Text(
                      '${s.totalOrders} ${locale.t('nav_orders')}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${(s.totalPurchase / 1000).toStringAsFixed(1)}k',
                style: AppTextStyles.data.copyWith(
                  color: AppColors.milkBlue700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Collection Tab ────────────────────────────────────────────────────────────

class _CollectionTab extends StatelessWidget {
  final LocaleState locale;
  const _CollectionTab({required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCards(locale),
        const SizedBox(height: 16),
        ...mockPayments.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.shopName, style: AppTextStyles.bodyBold),
                        Text(
                          '${p.invoiceNo} • ${locale.translateDate(p.date)}',
                          style: AppTextStyles.caption,
                        ),
                        Text(locale.translatePaymentMethod(p.method), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    '₹${p.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.data.copyWith(
                      color: AppColors.dairyGreen700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(LocaleState locale) {
    return Row(
      children: [
        Expanded(
          child: _card(
            '₹42,600',
            locale.t('total_collected'),
            AppColors.dairyGreen700,
            AppColors.dairyGreen100,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card(
            '₹8,320',
            locale.t('pending'),
            AppColors.amber600,
            AppColors.amber100,
          ),
        ),
      ],
    );
  }

  Widget _card(String val, String lbl, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: AppTextStyles.h4.copyWith(color: fg)),
          Text(lbl, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Outstanding Tab ───────────────────────────────────────────────────────────

class _OutstandingTab extends StatelessWidget {
  final LocaleState locale;
  const _OutstandingTab({required this.locale});

  @override
  Widget build(BuildContext context) {
    final withOut = mockShops.where((s) => s.outstanding > 0).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: withOut.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = withOut[i];
        final pct = s.outstanding / s.totalPurchase;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.shopName, style: AppTextStyles.bodyBold),
                        Text(s.ownerName, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    '₹${s.outstanding.toStringAsFixed(0)}',
                    style: AppTextStyles.data.copyWith(color: AppColors.red600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: AppColors.red100,
                color: AppColors.red500,
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
            ],
          ),
        );
      },
    );
  }
}
