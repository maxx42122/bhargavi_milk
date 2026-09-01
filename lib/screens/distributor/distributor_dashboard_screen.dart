import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/broadcast_card.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/section_header.dart';
import 'distributor_profile_screen.dart';
import 'product_management_screen.dart';
import 'shop_management_screen.dart';
import 'order_management_screen.dart';
import 'payments_outstanding_screen.dart';
import 'reports_screen.dart';
import 'invoice_screen.dart';
import 'statement_screen.dart';
import 'notifications_screen.dart';

class DistributorDashboardScreen extends StatefulWidget {
  const DistributorDashboardScreen({super.key});

  @override
  State<DistributorDashboardScreen> createState() =>
      _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState
    extends State<DistributorDashboardScreen> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'nav_dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'nav_orders'),
    _NavItem(Icons.inventory_2_rounded, 'nav_products'),
    _NavItem(Icons.store_rounded, 'nav_customers'),
    _NavItem(Icons.payments_rounded, 'nav_payments'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final isWide = MediaQuery.of(context).size.width > 700;

    final screens = [
      _DashboardContent(onNavigate: _navigateTo),
      const OrderManagementScreen(),
      const ProductManagementScreen(),
      const ShopManagementScreen(),
      const PaymentsOutstandingScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _DistributorSidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
              locale: locale,
            ),
            Expanded(child: screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: _navItems
            .map(
              (n) => BottomNavigationBarItem(
                icon: Icon(n.icon),
                label: locale.t(n.labelKey),
              ),
            )
            .toList(),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _NavItem {
  final IconData icon;
  final String labelKey;
  const _NavItem(this.icon, this.labelKey);
}

// ── Sidebar (wide) ────────────────────────────────────────────────────────────

class _DistributorSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final LocaleState locale;

  const _DistributorSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.locale,
  });

  static const _allItems = [
    _NavItem(Icons.dashboard_rounded, 'nav_dashboard'),
    _NavItem(Icons.receipt_long_rounded, 'nav_orders'),
    _NavItem(Icons.inventory_2_rounded, 'nav_products'),
    _NavItem(Icons.store_rounded, 'nav_customers'),
    _NavItem(Icons.payments_rounded, 'nav_payments'),
    _NavItem(Icons.description_rounded, 'nav_bills'),
    _NavItem(Icons.account_balance_wallet_rounded, 'nav_statements'),
    _NavItem(Icons.bar_chart_rounded, 'nav_reports'),
    _NavItem(Icons.settings_rounded, 'nav_settings'),
  ];

  String _sidebarInitials(LocaleState locale) {
    final name = AuthService.currentUser?.displayName ?? '';
    if (name.isEmpty) return 'D';
    return name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.milkBlue900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  locale.t('app_name'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Nav items (first 5 are main tabs)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _allItems.length,
              itemBuilder: (_, i) {
                final item = _allItems[i];
                final active = i == selectedIndex && i < 5;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (i < 5) {
                        onSelect(i);
                      } else {
                        // Navigate to standalone screens
                        final screens = [
                          const InvoiceScreen(),
                          const StatementScreen(shopName: 'Sharma Kirana'),
                          const ReportsScreen(),
                          const Scaffold(body: Center(child: Text('Settings'))),
                        ];
                        if (i - 5 < screens.length) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => screens[i - 5]),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.milkBlue600
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: active ? Colors.white : Colors.white60,
                            size: 19,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            locale.t(item.labelKey),
                            style: AppTextStyles.label.copyWith(
                              color: active ? Colors.white : Colors.white70,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Bottom: profile · language · logout ──────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile row
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DistributorProfileScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Mini avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.milkBlue500,
                                AppColors.milkBlue700,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _sidebarInitials(locale),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AuthService.currentUser?.displayName ??
                                    locale.t('nav_profile'),
                                style: AppTextStyles.captionBold.copyWith(
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                locale.t('nav_profile'),
                                style: AppTextStyles.overline.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),
                const LanguagePillButton(),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async => AuthService.signOut(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          color: Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          locale.t('logout'),
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
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

// ── Dashboard Content ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final void Function(Widget) onNavigate;
  const _DashboardContent({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Top bar
          SliverToBoxAdapter(child: _buildTopBar(context, locale)),
          // Broadcast to all shops
          const SliverToBoxAdapter(child: DistributorBroadcastCard()),
          // KPI cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: SectionHeader(title: locale.t('nav_dashboard')),
            ),
          ),
          SliverToBoxAdapter(child: _buildKpiRow(locale)),
          // Sales chart
          SliverToBoxAdapter(
            child: _buildSectionCard(
              context,
              title: locale.t('sales_overview'),
              subtitle: locale.t('7_day_sales'),
              child: _buildBarChart(),
            ),
          ),
          // Payment summary + Recent orders
          SliverToBoxAdapter(child: _buildPaymentSummary(locale)),
          SliverToBoxAdapter(
            child: _buildSectionCard(
              context,
              title: locale.t('recent_orders'),
              actionLabel: locale.t('view_all'),
              onAction: () => onNavigate(const OrderManagementScreen()),
              child: _buildOrdersTable(locale),
            ),
          ),
          // Top products + Low stock
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      context,
                      title: locale.t('top_products'),
                      child: _buildTopProducts(),
                      noPadding: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSectionCard(
                      context,
                      title: locale.t('low_stock'),
                      child: _buildLowStock(locale),
                      noPadding: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, LocaleState locale) {
    final top = MediaQuery.of(context).padding.top;
    final user = AuthService.currentUser;
    final displayName = user?.displayName ?? locale.t('app_name');
    final initials = displayName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.t('app_name'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  displayName,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          // Notifications
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.amber500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const LanguagePillButton(),
          const SizedBox(width: 8),
          // ── Profile avatar button ─────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DistributorProfileScreen(),
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white24, Colors.white10],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initials.isEmpty ? 'D' : initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(LocaleState locale) {
    final cards = [
      KpiCard(
        label: locale.t('total_shops'),
        value: '48',
        icon: Icons.store_rounded,
        delta: '+3',
        deltaPositive: true,
      ),
      KpiCard(
        label: locale.t('todays_orders'),
        value: '23',
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.dairyGreen700,
        iconBg: AppColors.dairyGreen100,
        delta: '+5',
        deltaPositive: true,
      ),
      KpiCard(
        label: locale.t('todays_sales'),
        value: '₹12,840',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.amber600,
        iconBg: AppColors.amber100,
        delta: '+8%',
        deltaPositive: true,
      ),
      KpiCard(
        label: locale.t('pending_payments'),
        value: '₹8,320',
        icon: Icons.hourglass_empty_rounded,
        iconColor: AppColors.red600,
        iconBg: AppColors.red100,
        delta: '-2',
        deltaPositive: false,
      ),
      KpiCard(
        label: locale.t('outstanding_amount'),
        value: '₹15,400',
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.red600,
        iconBg: AppColors.red100,
      ),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 180, child: cards[i]),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
    required Widget child,
    bool noPadding = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.h4),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.milkBlue600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          noPadding
              ? child
              : Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxVal = salesChartData
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: salesChartData.map((d) {
          final frac = (d['amount'] as double) / maxVal;
          final isMax = d['amount'] == maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 110 * frac,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isMax
                            ? [AppColors.milkBlue700, AppColors.milkBlue500]
                            : [AppColors.milkBlue100, const Color(0xFFBDD8F6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d['day'] as String, style: AppTextStyles.overline),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSummary(LocaleState locale) {
    final items = [
      (
        locale.t('collected'),
        '₹42,600',
        AppColors.dairyGreen500,
        AppColors.dairyGreen100,
      ),
      (locale.t('pending'), '₹8,320', AppColors.amber500, AppColors.amber100),
      (locale.t('overdue'), '₹6,480', AppColors.red500, AppColors.red100),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.t('payment_summary'), style: AppTextStyles.h4),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: item.$4,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: AppTextStyles.h4.copyWith(color: item.$3),
                      ),
                      Text(item.$1, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(LocaleState locale) {
    final distId = AuthService.currentUser?.uid ?? '';
    if (distId.isEmpty) {
      return Column(
        children: mockOrders.take(4).map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.id, style: AppTextStyles.captionBold),
                      Text(order.shopName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${order.total.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyBold,
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
        }).toList(),
      );
    }

    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.streamDistributorOrders(distributorId: distId),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Column(
            children: mockOrders.take(4).map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.id, style: AppTextStyles.captionBold),
                          Text(order.shopName, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyBold,
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
            }).toList(),
          );
        }

        return Column(
          children: orders.take(4).map((order) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderNumber, style: AppTextStyles.captionBold),
                        Text(order.shopName, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyBold,
                    ),
                  ),
                  AppBadge(
                    label: order.status,
                    variant: orderStatusVariant(order.status),
                    showDot: false,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopProducts() {
    final top = [
      ('Full Cream Milk 1L', '🥛', '₹54', '180 sold'),
      ('Toned Milk 500ml', '🥛', '₹24', '162 sold'),
      ('Fresh Curd 500g', '🍶', '₹40', '98 sold'),
      ('Paneer 200g', '🧀', '₹90', '72 sold'),
    ];
    return Column(
      children: top.map((p) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(p.$2, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.$1,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.ink900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(p.$4, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Text(p.$3, style: AppTextStyles.captionBold),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLowStock(LocaleState locale) {
    final lowStockProducts = mockProducts.where((p) => p.stock <= 10).toList();
    if (lowStockProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(locale.t('no_data'), style: AppTextStyles.caption),
      );
    }
    return Column(
      children: lowStockProducts.map((p) {
        final frac = p.stock / 20.0; // show as fraction of 20
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.name,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.ink900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${p.stock} left',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.red600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: frac.clamp(0.0, 1.0),
                backgroundColor: AppColors.red100,
                color: AppColors.red500,
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
