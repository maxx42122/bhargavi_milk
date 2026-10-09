import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/broadcast_card.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/desktop/desktop_distributor_sidebar.dart';
import '../../widgets/desktop/desktop_top_nav.dart';
import '../../widgets/desktop/desktop_kpi_card.dart';
import '../../widgets/desktop/desktop_hover_card.dart';
import 'distributor_profile_screen.dart';
import 'notifications_screen.dart';
import 'order_management_screen.dart';
import 'payments_outstanding_screen.dart';
import 'product_management_screen.dart';
import 'reports_screen.dart';
import 'shop_management_screen.dart';
import 'statement_screen.dart';
import 'total_orders_summary_screen.dart';
import 'distributor_settings_screen.dart';
import '../../services/distributor_settings_service.dart';

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
    final isWide = context.isDesktop;

    final screens = [
      _DashboardContent(onNavigate: _navigateTo),
      const OrderManagementScreen(),
      const ProductManagementScreen(),
      const ShopManagementScreen(),
      const PaymentsOutstandingScreen(),
    ];

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            DesktopDistributorSidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
              locale: locale,
            ),
            Expanded(
              child: screens[_selectedIndex],
            ),
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

// ── Top Product Model Helper ──────────────────────────────────────────────────

class _TopProductStat {
  final String productName;
  final String packSize;
  final String emoji;
  final double unitPrice;
  int quantitySold = 0;
  double totalRevenue = 0.0;

  _TopProductStat({
    required this.productName,
    required this.packSize,
    required this.emoji,
    required this.unitPrice,
  });
}

// ── Dashboard Content ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final void Function(Widget) onNavigate;
  const _DashboardContent({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final auth = AuthStateScope.of(context);
    final distributorId = auth.distributorId ??
        AuthService.currentUser?.uid ??
        '';

    if (distributorId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                locale.t('loading'),
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink700),
              ),
            ],
          ),
        ),
      );
    }

    final numberFormat = NumberFormat('#,##,##0', 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService.streamDistributorOrders(distributorId: distributorId),
        builder: (context, ordersSnapshot) {
          final allOrders = ordersSnapshot.data ?? [];
          final isOrdersLoading = ordersSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !ordersSnapshot.hasData;

          // ── Date calculations ──────────────────────────────────────────
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

          bool isToday(DateTime? dt) {
            if (dt == null) return false;
            return dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                dt.isBefore(todayEnd.add(const Duration(seconds: 1)));
          }

          final yesterdayStart = todayStart.subtract(const Duration(days: 1));
          final yesterdayEnd = DateTime(
            yesterdayStart.year,
            yesterdayStart.month,
            yesterdayStart.day,
            23,
            59,
            59,
          );

          bool isYesterday(DateTime? dt) {
            if (dt == null) return false;
            return dt.isAfter(
                  yesterdayStart.subtract(const Duration(seconds: 1)),
                ) &&
                dt.isBefore(yesterdayEnd.add(const Duration(seconds: 1)));
          }

          // ── Today & Yesterday metrics ──────────────────────────────────
          final todaysOrders =
              allOrders.where((o) => isToday(o.createdAt)).toList();
          final todaysOrdersCount = todaysOrders.length;
          final todaysSales = todaysOrders.fold<double>(
            0.0,
            (acc, o) => acc + o.totalAmount,
          );

          final yestOrders =
              allOrders.where((o) => isYesterday(o.createdAt)).toList();
          final yestSales = yestOrders.fold<double>(
            0.0,
            (acc, o) => acc + o.totalAmount,
          );

          final orderDeltaCount = todaysOrdersCount - yestOrders.length;
          final orderDeltaStr = orderDeltaCount == 0
              ? 'Same as yest.'
              : (orderDeltaCount > 0
                  ? '+$orderDeltaCount vs yest.'
                  : '$orderDeltaCount vs yest.');

          final salesDeltaPercent = yestSales > 0
              ? (((todaysSales - yestSales) / yestSales) * 100).round()
              : (todaysSales > 0 ? 100 : 0);
          final salesDeltaStr = salesDeltaPercent >= 0
              ? '+$salesDeltaPercent% vs yest.'
              : '$salesDeltaPercent% vs yest.';

          // ── Payment summary & outstanding calculations ─────────────────
          double totalCollected = 0.0;
          double totalPending = 0.0;
          double totalOverdue = 0.0;
          int pendingOrdersCount = 0;
          final sevenDaysAgo = now.subtract(const Duration(days: 7));

          for (final order in allOrders) {
            final pStatus = order.paymentStatus.trim().toLowerCase();
            final oStatus = order.status.trim().toLowerCase();
            final isPaid = pStatus == 'paid' || oStatus == 'completed';
            final isOverdue = pStatus == 'overdue' ||
                (!isPaid &&
                    order.createdAt != null &&
                    order.createdAt!.isBefore(sevenDaysAgo));

            if (isPaid) {
              totalCollected += order.totalAmount;
            } else if (isOverdue) {
              totalOverdue += order.totalAmount;
              totalPending += order.totalAmount;
              pendingOrdersCount++;
            } else {
              totalPending += order.totalAmount;
              pendingOrdersCount++;
            }
          }

          // ── 7-Day sales breakdown ──────────────────────────────────────
          final List<Map<String, dynamic>> last7DaysSales = [];
          double maxSalesIn7Days = 0.0;

          for (int i = 6; i >= 0; i--) {
            final d = now.subtract(Duration(days: i));
            final dStart = DateTime(d.year, d.month, d.day);
            final dEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);
            final dayName = DateFormat('E').format(d);

            final dayOrders = allOrders.where((o) {
              final dt = o.createdAt;
              if (dt == null) return false;
              return dt.isAfter(dStart.subtract(const Duration(seconds: 1))) &&
                  dt.isBefore(dEnd.add(const Duration(seconds: 1)));
            });

            final dayTotal =
                dayOrders.fold<double>(0.0, (acc, o) => acc + o.totalAmount);
            if (dayTotal > maxSalesIn7Days) maxSalesIn7Days = dayTotal;

            last7DaysSales.add({
              'day': dayName,
              'date': d,
              'amount': dayTotal,
            });
          }

          // ── Top selling products aggregation ───────────────────────────
          final Map<String, _TopProductStat> productSalesMap = {};
          for (final order in allOrders) {
            if (order.items.isNotEmpty) {
              for (final item in order.items) {
                final key =
                    '${item.productName.trim().toLowerCase()}_${item.packSize.trim().toLowerCase()}';
                final stat = productSalesMap.putIfAbsent(
                  key,
                  () => _TopProductStat(
                    productName: item.productName.trim(),
                    packSize: item.packSize.trim(),
                    emoji: item.emoji.isNotEmpty ? item.emoji : '🥛',
                    unitPrice: item.price,
                  ),
                );
                stat.quantitySold += item.quantity;
                stat.totalRevenue += item.subtotal;
              }
            } else if (order.products.isNotEmpty) {
              for (final prodStr in order.products) {
                final key = prodStr.trim().toLowerCase();
                final stat = productSalesMap.putIfAbsent(
                  key,
                  () => _TopProductStat(
                    productName: prodStr.trim(),
                    packSize: '500ml',
                    emoji: '🥛',
                    unitPrice: 30.0,
                  ),
                );
                stat.quantitySold += 1;
                stat.totalRevenue += (order.totalAmount > 0
                    ? (order.totalAmount / order.products.length)
                    : 30.0);
              }
            }
          }

          final topProductsList = productSalesMap.values.toList()
            ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

          if (context.isDesktop) {
            return _buildDesktopDashboardView(
              context: context,
              locale: locale,
              distributorId: distributorId,
              allOrders: allOrders,
              isOrdersLoading: isOrdersLoading,
              todaysOrdersCount: todaysOrdersCount,
              orderDeltaStr: orderDeltaStr,
              orderDeltaPositive: orderDeltaCount >= 0,
              todaysSales: todaysSales,
              salesDeltaStr: salesDeltaStr,
              salesDeltaPositive: salesDeltaPercent >= 0,
              totalCollected: totalCollected,
              totalPending: totalPending,
              totalOverdue: totalOverdue,
              pendingOrdersCount: pendingOrdersCount,
              last7DaysSales: last7DaysSales,
              maxSalesIn7Days: maxSalesIn7Days,
              topProductsList: topProductsList,
              numberFormat: numberFormat,
              onNavigate: onNavigate,
            );
          }

          return CustomScrollView(
            slivers: [
              // Top Bar
              SliverToBoxAdapter(
                child: _buildTopBar(context, locale, distributorId),
              ),

              // Store Order Timing & Payment Rules Banner
              SliverToBoxAdapter(
                child: _DistributorOrderTimingBanner(
                  distributorId: distributorId,
                  locale: locale,
                  onNavigate: onNavigate,
                ),
              ),

              // Broadcast to all shops
              const SliverToBoxAdapter(child: DistributorBroadcastCard()),

              // KPI Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          locale.t('nav_dashboard'),
                          style: AppTextStyles.h4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dairyGreen100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.dairyGreen500.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.dairyGreen600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppColors.dairyGreen700,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Real-time KPI cards row
              SliverToBoxAdapter(
                child: _buildRealTimeKpiRow(
                  distributorId: distributorId,
                  todaysOrdersCount: todaysOrdersCount,
                  orderDeltaStr: orderDeltaStr,
                  orderDeltaPositive: orderDeltaCount >= 0,
                  todaysSales: todaysSales,
                  salesDeltaStr: salesDeltaStr,
                  salesDeltaPositive: salesDeltaPercent >= 0,
                  totalPending: totalPending,
                  pendingOrdersCount: pendingOrdersCount,
                  outstandingAmount: totalPending,
                  totalOverdue: totalOverdue,
                  numberFormat: numberFormat,
                  locale: locale,
                  onNavigate: onNavigate,
                ),
              ),

              // 7-Day Real-Time Sales Chart
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  context,
                  title: locale.t('sales_overview'),
                  subtitle: locale.t('7_day_sales'),
                  actionLabel: locale.t('view_all'),
                  onAction: () => onNavigate(
                    const TotalOrdersSummaryScreen(
                      initialDateFilter: 'This Week',
                    ),
                  ),
                  child: _buildRealTimeBarChart(
                    salesData: last7DaysSales,
                    maxVal: maxSalesIn7Days,
                    locale: locale,
                    numberFormat: numberFormat,
                  ),
                ),
              ),

              // Real-Time Payment Summary
              SliverToBoxAdapter(
                child: _buildRealTimePaymentSummary(
                  totalCollected: totalCollected,
                  totalPending: totalPending,
                  totalOverdue: totalOverdue,
                  numberFormat: numberFormat,
                  locale: locale,
                  onNavigate: onNavigate,
                ),
              ),

              // Real-Time Recent Orders
              SliverToBoxAdapter(
                child: _buildSectionCard(
                  context,
                  title: locale.t('recent_orders'),
                  subtitle: allOrders.isNotEmpty
                      ? '${allOrders.length} total orders recorded'
                      : null,
                  actionLabel: locale.t('view_all'),
                  onAction: () => onNavigate(const OrderManagementScreen()),
                  child: _buildRealTimeOrdersTable(
                    orders: allOrders.take(5).toList(),
                    isLoading: isOrdersLoading,
                    numberFormat: numberFormat,
                    locale: locale,
                    onNavigate: onNavigate,
                  ),
                ),
              ),

              // Top Products + Real-Time Low Stock
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
                          actionLabel: locale.t('view_all'),
                          onAction: () => onNavigate(
                            const TotalOrdersSummaryScreen(
                              initialDateFilter: 'All Time',
                            ),
                          ),
                          child: _buildRealTimeTopProducts(
                            topProducts: topProductsList.take(4).toList(),
                            distributorId: distributorId,
                            numberFormat: numberFormat,
                            locale: locale,
                          ),
                          noPadding: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSectionCard(
                          context,
                          title: locale.t('low_stock'),
                          actionLabel: locale.t('view_all'),
                          onAction: () =>
                              onNavigate(const ProductManagementScreen()),
                          child: _buildRealTimeLowStock(
                            distributorId: distributorId,
                            locale: locale,
                          ),
                          noPadding: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopDashboardView({
    required BuildContext context,
    required LocaleState locale,
    required String distributorId,
    required List<OrderModel> allOrders,
    required bool isOrdersLoading,
    required int todaysOrdersCount,
    required String orderDeltaStr,
    required bool orderDeltaPositive,
    required double todaysSales,
    required String salesDeltaStr,
    required bool salesDeltaPositive,
    required double totalCollected,
    required double totalPending,
    required double totalOverdue,
    required int pendingOrdersCount,
    required List<Map<String, dynamic>> last7DaysSales,
    required double maxSalesIn7Days,
    required List<_TopProductStat> topProductsList,
    required NumberFormat numberFormat,
    required void Function(Widget) onNavigate,
  }) {
    final user = AuthService.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: distributorId.isNotEmpty
          ? AuthService.distributorStream(distributorId)
          : null,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final companyName = (data['companyName'] ??
                data['name'] ??
                user?.displayName ??
                'MilkRoute Distributor')
            .toString();

        return Column(
          children: [
            // Desktop Top Nav Bar
            DesktopTopNav(
              title: companyName,
              subtitle: 'Morning Procurement & Route Dispatch Center',
              showLiveBadge: true,
              unreadNotifications: 0,
              onNotificationTap: () => onNavigate(const NotificationsScreen()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.ink700, size: 20),
                  tooltip: locale.t('order_settings'),
                  onPressed: () => onNavigate(const DistributorSettingsScreen()),
                ),
              ],
              trailingCustom: GestureDetector(
                onTap: () => onNavigate(const DistributorProfileScreen()),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.milkBlue600,
                  child: Text(
                    companyName.isNotEmpty ? companyName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: DesktopMaxContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Timing rules & Broadcast
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _DistributorOrderTimingBanner(
                              distributorId: distributorId,
                              locale: locale,
                              onNavigate: onNavigate,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            flex: 5,
                            child: DistributorBroadcastCard(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Row 2: 4-Card Responsive KPI Metrics
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('distributor')
                            .doc(distributorId)
                            .collection('shops')
                            .snapshots(),
                        builder: (context, shopsSnap) {
                          final shopsDocs = shopsSnap.data?.docs ?? [];
                          final totalShops = shopsDocs.length;
                          final pendingShops = shopsDocs
                              .where((d) => (d.data()['status'] ?? '') == 'pending')
                              .length;
                          final activeShops = shopsDocs
                              .where((d) => (d.data()['status'] ?? '') == 'active')
                              .length;

                          final shopsDelta = pendingShops > 0
                              ? '+$pendingShops Pending Approval'
                              : '$activeShops Active';

                          return Row(
                            children: [
                              // KPI 1: Today's Sales
                              Expanded(
                                child: DesktopKpiCard(
                                  title: locale.t('todays_sales'),
                                  value: '₹${numberFormat.format(todaysSales)}',
                                  icon: Icons.trending_up_rounded,
                                  iconColor: AppColors.primaryBlue,
                                  iconBg: AppColors.milkBlue50,
                                  deltaText: salesDeltaStr,
                                  deltaPositive: salesDeltaPositive,
                                  subtitle: 'Based on today\'s confirmed orders',
                                  onTap: () => onNavigate(
                                    const TotalOrdersSummaryScreen(initialDateFilter: 'Today'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // KPI 2: Today's Orders
                              Expanded(
                                child: DesktopKpiCard(
                                  title: locale.t('todays_orders'),
                                  value: '$todaysOrdersCount Orders',
                                  icon: Icons.receipt_long_rounded,
                                  iconColor: AppColors.dairyGreen600,
                                  iconBg: AppColors.dairyGreen50,
                                  deltaText: orderDeltaStr,
                                  deltaPositive: orderDeltaPositive,
                                  subtitle: 'Morning delivery batches',
                                  onTap: () => onNavigate(
                                    const TotalOrdersSummaryScreen(initialDateFilter: 'Today'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // KPI 3: Outstanding Ledger
                              Expanded(
                                child: DesktopKpiCard(
                                  title: locale.t('outstanding_amount'),
                                  value: '₹${numberFormat.format(totalPending)}',
                                  icon: Icons.account_balance_wallet_rounded,
                                  iconColor: totalOverdue > 0 ? AppColors.red600 : AppColors.amber600,
                                  iconBg: totalOverdue > 0 ? AppColors.red50 : AppColors.amber50,
                                  deltaText: totalOverdue > 0
                                      ? '₹${numberFormat.format(totalOverdue)} overdue'
                                      : '$pendingOrdersCount pending',
                                  deltaPositive: totalOverdue == 0,
                                  subtitle: 'Total shop receivables',
                                  onTap: () => onNavigate(const PaymentsOutstandingScreen()),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // KPI 4: Retail Customer Shops
                              Expanded(
                                child: DesktopKpiCard(
                                  title: locale.t('total_shops'),
                                  value: '$totalShops Shops',
                                  icon: Icons.storefront_rounded,
                                  iconColor: const Color(0xFF7C3AED),
                                  iconBg: const Color(0xFFF3E8FF),
                                  deltaText: shopsDelta,
                                  deltaPositive: pendingShops == 0,
                                  subtitle: '$activeShops verified vendors',
                                  onTap: () => onNavigate(const ShopManagementScreen()),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Row 3: 2-Column Split (Live Orders & Top Products on Left, Sales Chart & Financials on Right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left 58% Column
                          Expanded(
                            flex: 58,
                            child: Column(
                              children: [
                                // Live Orders Table
                                DesktopHoverCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.milkBlue50,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.bolt_rounded,
                                                  color: AppColors.primaryBlue,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    locale.t('recent_orders'),
                                                    style: AppTextStyles.desktopH3,
                                                  ),
                                                  Text(
                                                    '${allOrders.length} total orders recorded',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.ink500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => onNavigate(const OrderManagementScreen()),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                            label: Text(locale.t('view_all')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      _buildRealTimeOrdersTable(
                                        orders: allOrders.take(6).toList(),
                                        isLoading: isOrdersLoading,
                                        numberFormat: numberFormat,
                                        locale: locale,
                                        onNavigate: onNavigate,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Top Selling Products Leaderboard
                                DesktopHoverCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.dairyGreen50,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.leaderboard_rounded,
                                                  color: AppColors.dairyGreen600,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    locale.t('top_products'),
                                                    style: AppTextStyles.desktopH3,
                                                  ),
                                                  Text(
                                                    'Highest demand dairy items',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.ink500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => onNavigate(
                                              const TotalOrdersSummaryScreen(initialDateFilter: 'All Time'),
                                            ),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                            label: Text(locale.t('view_all')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      _buildRealTimeTopProducts(
                                        topProducts: topProductsList.take(5).toList(),
                                        distributorId: distributorId,
                                        numberFormat: numberFormat,
                                        locale: locale,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right 42% Column
                          Expanded(
                            flex: 42,
                            child: Column(
                              children: [
                                // 7-Day Real-Time Sales Bar Chart
                                DesktopHoverCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.amber50,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.bar_chart_rounded,
                                                  color: AppColors.amber600,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    locale.t('sales_overview'),
                                                    style: AppTextStyles.desktopH3,
                                                  ),
                                                  Text(
                                                    locale.t('7_day_sales'),
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.ink500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => onNavigate(
                                              const TotalOrdersSummaryScreen(initialDateFilter: 'This Week'),
                                            ),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                            label: Text(locale.t('view_all')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      _buildRealTimeBarChart(
                                        salesData: last7DaysSales,
                                        maxVal: maxSalesIn7Days,
                                        locale: locale,
                                        numberFormat: numberFormat,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Payment Ledger & Recovery Matrix
                                DesktopHoverCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.milkBlue50,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.payments_rounded,
                                                  color: AppColors.primaryBlue,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                locale.t('payment_summary'),
                                                style: AppTextStyles.desktopH3,
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => onNavigate(const PaymentsOutstandingScreen()),
                                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                            label: Text(locale.t('view_all')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      _buildRealTimePaymentSummary(
                                        totalCollected: totalCollected,
                                        totalPending: totalPending,
                                        totalOverdue: totalOverdue,
                                        numberFormat: numberFormat,
                                        locale: locale,
                                        onNavigate: onNavigate,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Operations Quick Action Grid
                                DesktopHoverCard(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quick Operations Actions',
                                        style: AppTextStyles.desktopH3,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Direct shortcuts to distributor management tools',
                                        style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          _quickActionButton(
                                            icon: Icons.table_chart_rounded,
                                            label: 'Orders Matrix',
                                            color: AppColors.primaryBlue,
                                            onTap: () => onNavigate(const TotalOrdersSummaryScreen()),
                                          ),
                                          _quickActionButton(
                                            icon: Icons.inventory_2_rounded,
                                            label: 'Manage Products',
                                            color: AppColors.dairyGreen600,
                                            onTap: () => onNavigate(const ProductManagementScreen()),
                                          ),
                                          _quickActionButton(
                                            icon: Icons.store_rounded,
                                            label: 'Customer Shops',
                                            color: const Color(0xFF7C3AED),
                                            onTap: () => onNavigate(const ShopManagementScreen()),
                                          ),
                                          _quickActionButton(
                                            icon: Icons.account_balance_wallet_rounded,
                                            label: 'Customer Ledger',
                                            color: AppColors.amber600,
                                            onTap: () => onNavigate(const StatementScreen(shopName: 'All Shops')),
                                          ),
                                          _quickActionButton(
                                            icon: Icons.bar_chart_rounded,
                                            label: 'Sales Reports',
                                            color: const Color(0xFF0284C7),
                                            onTap: () => onNavigate(const ReportsScreen()),
                                          ),
                                          _quickActionButton(
                                            icon: Icons.tune_rounded,
                                            label: 'Cutoff Rules',
                                            color: AppColors.ink700,
                                            onTap: () => onNavigate(const DistributorSettingsScreen()),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.captionBold.copyWith(color: color, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    LocaleState locale,
    String distributorId,
  ) {
    final top = MediaQuery.of(context).padding.top;
    final user = AuthService.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: distributorId.isNotEmpty
          ? AuthService.distributorStream(distributorId)
          : null,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final companyName = (data['companyName'] ??
                data['name'] ??
                user?.displayName ??
                'MilkRoute Distributor')
            .toString();
        final ownerName = (data['distributorName'] ??
                data['ownerName'] ??
                user?.displayName ??
                '')
            .toString();

        final displayName = companyName.isNotEmpty
            ? companyName
            : (ownerName.isNotEmpty ? ownerName : 'Distributor');
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
                      companyName,
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ownerName.isNotEmpty && ownerName != companyName)
                      Text(
                        'Prop: $ownerName',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        locale.t('dist_orders_mgmt'),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white70,
                        ),
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
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: locale.t('order_settings'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DistributorSettingsScreen(),
                  ),
                ),
              ),
              const LanguagePillButton(),
              const SizedBox(width: 8),
              // Profile avatar button
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
                      style: AppTextStyles.captionBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRealTimeKpiRow({
    required String distributorId,
    required int todaysOrdersCount,
    required String orderDeltaStr,
    required bool orderDeltaPositive,
    required double todaysSales,
    required String salesDeltaStr,
    required bool salesDeltaPositive,
    required double totalPending,
    required int pendingOrdersCount,
    required double outstandingAmount,
    required double totalOverdue,
    required NumberFormat numberFormat,
    required LocaleState locale,
    required void Function(Widget) onNavigate,
  }) {
    return SizedBox(
      height: 140,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('distributor')
            .doc(distributorId)
            .collection('shops')
            .snapshots(),
        builder: (context, snapshot) {
          final shopsDocs = snapshot.data?.docs ?? [];
          final totalShops = shopsDocs.length;
          final pendingShops = shopsDocs
              .where((d) => (d.data()['status'] ?? '') == 'pending')
              .length;
          final activeShops = shopsDocs
              .where((d) => (d.data()['status'] ?? '') == 'active')
              .length;

          final shopsDelta = pendingShops > 0
              ? '+$pendingShops pending'
              : (activeShops > 0 ? '$activeShops active' : '0 active');

          final cards = [
            // Total Shops Card
            GestureDetector(
              onTap: () => onNavigate(const ShopManagementScreen()),
              child: KpiCard(
                label: locale.t('total_shops'),
                value: '$totalShops',
                icon: Icons.store_rounded,
                delta: shopsDelta,
                deltaPositive: pendingShops > 0 || activeShops > 0,
              ),
            ),

            // Today's Orders Card
            GestureDetector(
              onTap: () => onNavigate(
                const TotalOrdersSummaryScreen(initialDateFilter: 'Today'),
              ),
              child: KpiCard(
                label: locale.t('todays_orders'),
                value: '$todaysOrdersCount',
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.dairyGreen700,
                iconBg: AppColors.dairyGreen100,
                delta: orderDeltaStr,
                deltaPositive: orderDeltaPositive,
              ),
            ),

            // Today's Sales Card
            GestureDetector(
              onTap: () => onNavigate(
                const TotalOrdersSummaryScreen(initialDateFilter: 'Today'),
              ),
              child: KpiCard(
                label: locale.t('todays_sales'),
                value: '₹${numberFormat.format(todaysSales)}',
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.amber600,
                iconBg: AppColors.amber100,
                delta: salesDeltaStr,
                deltaPositive: salesDeltaPositive,
              ),
            ),

            // Pending Payments Card
            GestureDetector(
              onTap: () => onNavigate(const PaymentsOutstandingScreen()),
              child: KpiCard(
                label: locale.t('pending_payments'),
                value: '₹${numberFormat.format(totalPending)}',
                icon: Icons.hourglass_empty_rounded,
                iconColor: AppColors.red600,
                iconBg: AppColors.red100,
                delta: '$pendingOrdersCount orders',
                deltaPositive: false,
              ),
            ),

            // Outstanding Amount Card
            GestureDetector(
              onTap: () => onNavigate(const PaymentsOutstandingScreen()),
              child: KpiCard(
                label: locale.t('outstanding_amount'),
                value: '₹${numberFormat.format(outstandingAmount)}',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.milkBlue900,
                iconBg: AppColors.milkBlue100,
                delta: totalOverdue > 0
                    ? '₹${numberFormat.format(totalOverdue)} overdue'
                    : 'All clear',
                deltaPositive: totalOverdue == 0,
              ),
            ),
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 180, child: cards[i]),
          );
        },
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

  Widget _buildRealTimeBarChart({
    required List<Map<String, dynamic>> salesData,
    required double maxVal,
    required LocaleState locale,
    required NumberFormat numberFormat,
  }) {
    final effectiveMax = maxVal > 0 ? maxVal : 1.0;
    final hasAnySales = maxVal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: salesData.map((d) {
              final amount = d['amount'] as double;
              final frac = amount / effectiveMax;
              final isMax = hasAnySales && amount == maxVal && amount > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (amount > 0)
                        Text(
                          amount >= 1000
                              ? '₹${(amount / 1000).toStringAsFixed(1)}k'
                              : '₹${amount.toInt()}',
                          style: AppTextStyles.overline.copyWith(
                            color: isMax
                                ? AppColors.milkBlue700
                                : AppColors.ink700,
                            fontWeight:
                                isMax ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox(height: 14),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: amount > 0
                            ? (100 * frac).clamp(8.0, 100.0)
                            : 4.0,
                        decoration: BoxDecoration(
                          gradient: amount > 0
                              ? LinearGradient(
                                  colors: isMax
                                      ? [
                                          AppColors.milkBlue700,
                                          AppColors.milkBlue500,
                                        ]
                                      : [
                                          AppColors.milkBlue300,
                                          AppColors.milkBlue100,
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : null,
                          color: amount == 0 ? AppColors.border : null,
                          borderRadius: BorderRadius.vertical(
                            top: const Radius.circular(6),
                            bottom: Radius.circular(amount == 0 ? 6 : 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        locale.translateDate(d['day'] as String),
                        style: AppTextStyles.overline.copyWith(
                          color: isMax
                              ? AppColors.milkBlue900
                              : AppColors.ink500,
                          fontWeight:
                              isMax ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (!hasAnySales) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              locale.t('no_sales_yet'),
              style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRealTimePaymentSummary({
    required double totalCollected,
    required double totalPending,
    required double totalOverdue,
    required NumberFormat numberFormat,
    required LocaleState locale,
    required void Function(Widget) onNavigate,
  }) {
    final items = [
      (
        locale.t('collected'),
        '₹${numberFormat.format(totalCollected)}',
        AppColors.dairyGreen600,
        AppColors.dairyGreen100,
        Icons.check_circle_rounded,
      ),
      (
        locale.t('pending'),
        '₹${numberFormat.format(totalPending)}',
        AppColors.amber600,
        AppColors.amber100,
        Icons.hourglass_top_rounded,
      ),
      (
        locale.t('overdue'),
        '₹${numberFormat.format(totalOverdue)}',
        AppColors.red600,
        AppColors.red100,
        Icons.warning_amber_rounded,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(locale.t('payment_summary'), style: AppTextStyles.h4),
              TextButton(
                onPressed: () => onNavigate(const PaymentsOutstandingScreen()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  locale.t('view_all'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: item.$4,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.$1,
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.ink700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(item.$5, size: 14, color: item.$3),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        style: AppTextStyles.captionBold.copyWith(
                          color: item.$3,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  Widget _buildRealTimeOrdersTable({
    required List<OrderModel> orders,
    required bool isLoading,
    required NumberFormat numberFormat,
    required LocaleState locale,
    required void Function(Widget) onNavigate,
  }) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.ink300,
              ),
              const SizedBox(height: 8),
              Text(
                locale.t('no_orders_yet'),
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.ink700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                locale.t('no_orders_sub'),
                textAlign: TextAlign.center,
                style: AppTextStyles.overline.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
        ),
      );
    }

    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM');

    return Column(
      children: orders.map((order) {
        final dt = order.createdAt;
        final timeStr = dt != null
            ? (DateTime.now().difference(dt).inDays == 0
                ? timeFormat.format(dt)
                : '${dateFormat.format(dt)}, ${timeFormat.format(dt)}')
            : '';

        return InkWell(
          onTap: () => onNavigate(const OrderManagementScreen()),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.orderNumber,
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.milkBlue900,
                              fontSize: 12.5,
                            ),
                          ),
                          if (timeStr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              timeStr,
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.ink500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.shopName.isNotEmpty
                            ? order.shopName
                            : (order.shopOwner.isNotEmpty
                                ? order.shopOwner
                                : 'Customer'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${numberFormat.format(order.totalAmount)}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.ink900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppBadge(
                  label: locale.translateStatus(order.status),
                  variant: orderStatusVariant(order.status),
                  showDot: false,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRealTimeTopProducts({
    required List<_TopProductStat> topProducts,
    required String distributorId,
    required NumberFormat numberFormat,
    required LocaleState locale,
  }) {
    if (topProducts.isEmpty) {
      return StreamBuilder<List<Product>>(
        stream: ProductService.streamProducts(distributorId),
        builder: (context, snapshot) {
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  locale.t('no_sales_yet'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                  ),
                ),
              ),
            );
          }

          return Column(
            children: products.take(4).map((p) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: Row(
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translateProduct(p.name),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.ink900,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            p.packSize,
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${numberFormat.format(p.price)}',
                      style: AppTextStyles.captionBold.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
    }

    return Column(
      children: topProducts.map((p) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
          child: Row(
            children: [
              Text(p.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.translateProduct(p.productName),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.ink900,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${p.quantitySold} ${locale.t('items_sold')} • ${p.packSize}',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.milkBlue700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${numberFormat.format(p.totalRevenue)}',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.dairyGreen700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRealTimeLowStock({
    required String distributorId,
    required LocaleState locale,
  }) {
    return StreamBuilder<List<Product>>(
      stream: ProductService.streamProducts(distributorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final products = snapshot.data ?? [];
        final lowStockProducts = products.where((p) => p.stock <= 15).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));

        if (lowStockProducts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.dairyGreen600,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  locale.t('all_stocked'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.dairyGreen700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  locale.t('stock_healthy'),
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.ink500,
                    fontSize: 9.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: lowStockProducts.take(4).map((p) {
            final frac = (p.stock / 20.0).clamp(0.0, 1.0);
            final isCritical = p.stock <= 5;

            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locale.translateProduct(p.name),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.ink900,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${p.stock} ${locale.t('units_left')}',
                        style: AppTextStyles.captionBold.copyWith(
                          color: isCritical
                              ? AppColors.red600
                              : AppColors.amber600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: frac,
                    backgroundColor:
                        isCritical ? AppColors.red100 : AppColors.amber100,
                    color: isCritical ? AppColors.red500 : AppColors.amber500,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 5,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DistributorOrderTimingBanner extends StatelessWidget {
  final String distributorId;
  final LocaleState locale;
  final void Function(Widget) onNavigate;

  const _DistributorOrderTimingBanner({
    required this.distributorId,
    required this.locale,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (distributorId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DistributorOrderSettings>(
      stream: DistributorSettingsService.streamSettings(distributorId),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? const DistributorOrderSettings();
        final status = DistributorSettingsService.isWithinOrderingHours(settings);
        final isOpen = status.isOpen;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOpen
                  ? AppColors.dairyGreen300
                  : AppColors.amber300,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOpen ? AppColors.dairyGreen700 : AppColors.amber700)
                    .withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOpen ? AppColors.dairyGreen50 : AppColors.amber50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                  color: isOpen ? AppColors.dairyGreen700 : AppColors.amber800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          locale.t('ordering_hours'),
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.ink900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.dairyGreen600
                                : AppColors.amber700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.orderTimingEnabled
                          ? '${settings.startTimeFormatted} – ${settings.endTimeFormatted}${settings.blockOnPendingPayment ? " • Unpaid Block: Active" : ""}'
                          : '24/7 Ordering Open (No time limit)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.milkBlue500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => onNavigate(const DistributorSettingsScreen()),
                child: Text(
                  locale.t('edit'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

