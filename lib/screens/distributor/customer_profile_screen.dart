import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../data/mock_data.dart';
import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../shop/shop_order_detail_screen.dart';
import 'statement_screen.dart';
import 'invoice_screen.dart';

/// Accepts a Firestore shop document (Map) from ShopManagementScreen.
/// Falls back gracefully when fields are missing.
class CustomerProfileScreen extends StatefulWidget {
  /// Raw Firestore data map from distributor/{id}/shops/{shopId}
  final Map<String, dynamic> shopData;
  final String shopUid;

  const CustomerProfileScreen({
    super.key,
    required this.shopData,
    required this.shopUid,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late Stream<List<OrderModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    final distId = (widget.shopData['distributorId'] as String?) ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    _ordersStream = OrderService.streamShopOrders(
      distributorId: distId,
      shopUid: widget.shopUid,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String get _shopName => widget.shopData['shopName'] as String? ?? '—';
  String get _ownerName => widget.shopData['ownerName'] as String? ?? '—';
  String get _phone =>
      widget.shopData['mobile'] as String? ??
      widget.shopData['phone'] as String? ??
      '—';
  double get _totalOrders =>
      (widget.shopData['totalOrders'] as num?)?.toDouble() ?? 0;
  double get _totalPurchase =>
      (widget.shopData['totalPurchase'] as num?)?.toDouble() ?? 0;
  double get _paidAmount =>
      (widget.shopData['paidAmount'] as num?)?.toDouble() ?? 0;
  double get _outstanding =>
      (widget.shopData['outstanding'] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader(context, locale)),
          SliverToBoxAdapter(child: _buildStatsRow(locale)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabs,
                labelColor: AppColors.milkBlue700,
                unselectedLabelColor: AppColors.ink500,
                indicatorColor: AppColors.milkBlue600,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: AppTextStyles.captionBold,
                tabs: [
                  Tab(text: locale.t('order_history')),
                  Tab(text: locale.t('payment_history')),
                  Tab(text: locale.t('statement')),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _OrderHistoryTab(
              locale: locale,
              ordersStream: _ordersStream,
            ),
            _PaymentHistoryTab(locale: locale),
            StatementScreen(shopName: _shopName, embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LocaleState locale) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  locale.t('customer_profile'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ),
              _headerBtn(Icons.note_add_outlined, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InvoiceScreen()),
                );
              }),
              _headerBtn(Icons.account_balance_wallet_outlined, () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StatementScreen(shopName: _shopName),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _shopName.isNotEmpty ? _shopName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shopName,
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                    ),
                    Text(
                      _ownerName,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _phone,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(LocaleState locale) {
    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final totalOrders = orders.isNotEmpty ? orders.length : _totalOrders.toInt();
        final totalPurchase = orders.isNotEmpty
            ? orders.fold<double>(0.0, (sum, o) => sum + o.totalAmount)
            : _totalPurchase;
        final paidAmount = orders.isNotEmpty
            ? orders
                .where((o) => o.paymentStatus.toLowerCase() == 'paid')
                .fold<double>(0.0, (sum, o) => sum + o.totalAmount)
            : _paidAmount;
        final outstanding = orders.isNotEmpty
            ? orders
                .where((o) => o.paymentStatus.toLowerCase() != 'paid')
                .fold<double>(0.0, (sum, o) => sum + o.totalAmount)
            : _outstanding;

        return Container(
          color: AppColors.cardSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              _statCell(locale.t('total_orders'), '$totalOrders'),
              _divider(),
              _statCell(
                locale.t('total_purchase'),
                totalPurchase >= 1000
                    ? '₹${(totalPurchase / 1000).toStringAsFixed(1)}k'
                    : '₹${totalPurchase.toStringAsFixed(0)}',
              ),
              _divider(),
              _statCell(
                locale.t('paid_amount'),
                paidAmount >= 1000
                    ? '₹${(paidAmount / 1000).toStringAsFixed(1)}k'
                    : '₹${paidAmount.toStringAsFixed(0)}',
                color: AppColors.dairyGreen700,
              ),
              _divider(),
              _statCell(
                locale.t('outstanding'),
                '₹${outstanding.toStringAsFixed(0)}',
                color: outstanding > 0
                    ? AppColors.red600
                    : AppColors.dairyGreen700,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCell(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h4.copyWith(color: color ?? AppColors.ink900),
          ),
          Text(
            label,
            style: AppTextStyles.overline,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

// ── Sliver tab bar delegate ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: AppColors.cardSurface, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}

// ── Order history tab (streams Firestore orders) ──────────────────────────────

class _OrderHistoryTab extends StatelessWidget {
  final LocaleState locale;
  final Stream<List<OrderModel>> ordersStream;

  const _OrderHistoryTab({
    required this.locale,
    required this.ordersStream,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recently';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    return '${dt.day} $month ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.ink300),
                  const SizedBox(height: 8),
                  Text(
                    locale.t('no_data'),
                    style: AppTextStyles.bodyBold,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No orders placed by this shop yet.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final o = orders[i];
            final productsSummary = o.products.isNotEmpty
                ? o.products.join(', ')
                : (o.items.isNotEmpty
                    ? o.items.map((it) => '${it.name} × ${it.quantity}').join(', ')
                    : 'Order Items');

            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShopOrderDetailScreen(order: o),
                ),
              ),
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
                          Text(o.orderNumber, style: AppTextStyles.captionBold.copyWith(color: AppColors.milkBlue700)),
                          Text(_formatDate(o.createdAt), style: AppTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(
                            productsSummary,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${o.total.toStringAsFixed(o.total % 1 == 0 ? 0 : 2)}',
                          style: AppTextStyles.bodyBold,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBadge(
                              label: o.orderStatus,
                              variant: orderStatusVariant(o.orderStatus),
                              showDot: false,
                            ),
                            const SizedBox(width: 4),
                            AppBadge(
                              label: o.paymentStatus,
                              variant: paymentStatusVariant(o.paymentStatus),
                              showDot: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Payment history tab ───────────────────────────────────────────────────────

class _PaymentHistoryTab extends StatelessWidget {
  final LocaleState locale;
  const _PaymentHistoryTab({required this.locale});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with Firestore stream query on payments subcollection
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: mockPayments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = mockPayments[i];
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dairyGreen100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.dairyGreen700,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.invoiceNo, style: AppTextStyles.captionBold),
                    Text(
                      '${p.method} • ${p.date}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${p.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.dairyGreen700,
                    ),
                  ),
                  AppBadge(
                    label: p.status,
                    variant: paymentStatusVariant(p.status),
                    showDot: false,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
