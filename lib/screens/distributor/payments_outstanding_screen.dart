import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_reminder_service.dart';
import '../../services/shop_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/kpi_card.dart';

class PaymentsOutstandingScreen extends StatefulWidget {
  const PaymentsOutstandingScreen({super.key});

  @override
  State<PaymentsOutstandingScreen> createState() =>
      _PaymentsOutstandingScreenState();
}

class _ShopPendingGroup {
  final String shopId;
  final String shopName;
  final String shopOwner;
  final String shopMobile;
  final String deliveryAddress;
  final List<OrderModel> orders;
  double totalOutstanding = 0.0;
  bool hasOverdue = false;

  _ShopPendingGroup({
    required this.shopId,
    required this.shopName,
    required this.shopOwner,
    required this.shopMobile,
    required this.deliveryAddress,
    required this.orders,
  });
}

class _PaymentsOutstandingScreenState extends State<PaymentsOutstandingScreen> {
  String _search = '';
  bool _isSendingReminder = false;
  Map<String, String>? _distributorInfo;

  @override
  void initState() {
    super.initState();
    _loadDistributorInfo();
  }

  Future<void> _loadDistributorInfo() async {
    final distId = AuthService.currentUser?.uid ?? '';
    if (distId.isNotEmpty) {
      final info = await ShopService.fetchDistributorInfo(distId);
      if (mounted && info != null) {
        setState(() => _distributorInfo = info);
      }
    }
  }

  Future<void> _handleSendReminderToAll({
    required String distributorId,
    required double totalOutstanding,
    required int pendingShopsCount,
    required LocaleState locale,
  }) async {
    if (pendingShopsCount == 0 || _isSendingReminder) return;

    final numberFormat = NumberFormat('#,##,##0', 'en_IN');
    final distName =
        _distributorInfo?['companyName'] ??
        _distributorInfo?['distributorName'] ??
        AuthService.currentUser?.displayName ??
        'MilkRoute Distribution';
    final distPhone = _distributorInfo?['mobile'] ?? '';

    final defaultMessage =
        'Dear Shop Partner, please clear your pending payment dues for uninterrupted milk supply. Thank you!';
    final messageController = TextEditingController(text: defaultMessage);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.amber600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locale.t('send_reminder_all'),
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber600.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Summary',
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.ink500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pendingShopsCount Shops • ₹${numberFormat.format(totalOutstanding)} Due',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.ink900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reminder Message:',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter reminder message…',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.milkBlue700,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                locale.t('cancel'),
                style: TextStyle(color: AppColors.ink500),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                locale.t('send_reminder'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSendingReminder = true);
    try {
      await PaymentReminderService.sendReminderToAll(
        distributorId: distributorId,
        distributorName: distName,
        distributorPhone: distPhone,
        totalAmount: totalOutstanding,
        pendingShopsCount: pendingShopsCount,
        message: messageController.text.trim().isNotEmpty
            ? messageController.text.trim()
            : defaultMessage,
        title: 'Payment Due Notice',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.t('reminder_sent_all')),
            backgroundColor: AppColors.dairyGreen600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminders: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReminder = false);
    }
  }

  Future<void> _handleSendReminderToSingleShop({
    required String distributorId,
    required _ShopPendingGroup group,
    required LocaleState locale,
  }) async {
    final numberFormat = NumberFormat('#,##,##0', 'en_IN');
    final distName =
        _distributorInfo?['companyName'] ??
        _distributorInfo?['distributorName'] ??
        AuthService.currentUser?.displayName ??
        'MilkRoute Distribution';
    final distPhone = _distributorInfo?['mobile'] ?? '';

    final defaultMessage =
        'Dear ${group.shopName}, kindly clear your pending balance of ₹${numberFormat.format(group.totalOutstanding)} for ongoing milk supply. Thank you!';
    final messageController = TextEditingController(text: defaultMessage);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.milkBlue100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.milkBlue700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Send Reminder to ${group.shopName}',
                  style: AppTextStyles.h4.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Due: ₹${numberFormat.format(group.totalOutstanding)} (${group.orders.length} orders)',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.red600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Message:',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter reminder message…',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.milkBlue700,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                locale.t('cancel'),
                style: TextStyle(color: AppColors.ink500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.milkBlue700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                locale.t('send_reminder'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await PaymentReminderService.sendReminderToShop(
        distributorId: distributorId,
        shopUid: group.shopId,
        shopName: group.shopName,
        distributorName: distName,
        distributorPhone: distPhone,
        amount: group.totalOutstanding,
        pendingOrdersCount: group.orders.length,
        message: messageController.text.trim().isNotEmpty
            ? messageController.text.trim()
            : defaultMessage,
        title: 'Payment Due Notice',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.t('reminder_sent_shop')),
            backgroundColor: AppColors.dairyGreen600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminder: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    }
  }

  Future<void> _handleRecordPayment({
    required String distributorId,
    required _ShopPendingGroup group,
    required LocaleState locale,
  }) async {
    final numberFormat = NumberFormat('#,##,##0', 'en_IN');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Record Payment for ${group.shopName}',
            style: AppTextStyles.h4.copyWith(fontSize: 16),
          ),
          content: Text(
            'Mark ${group.orders.length} pending order(s) totaling ₹${numberFormat.format(group.totalOutstanding)} as Paid?',
            style: AppTextStyles.body.copyWith(color: AppColors.ink700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                locale.t('cancel'),
                style: TextStyle(color: AppColors.ink500),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dairyGreen600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Mark as Paid',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final orderIds = group.orders.map((o) => o.id).toList();
      await OrderService.batchUpdateOrderStatus(
        distributorId: distributorId,
        orderIds: orderIds,
        newStatus: 'completed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded for ${group.shopName}! ✓'),
            backgroundColor: AppColors.dairyGreen600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final auth = AuthStateScope.of(context);
    final distributorId =
        auth.distributorId ?? AuthService.currentUser?.uid ?? '';

    if (distributorId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(locale.t('loading'))),
      );
    }

    final numberFormat = NumberFormat('#,##,##0', 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService.streamDistributorOrders(
          distributorId: distributorId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data ?? [];
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final sevenDaysAgo = now.subtract(const Duration(days: 7));

          double totalCollected = 0.0;
          double todaysCollection = 0.0;
          double totalPending = 0.0;
          double totalOverdue = 0.0;

          // Group pending orders by shop
          final Map<String, _ShopPendingGroup> shopPendingMap = {};

          for (final order in allOrders) {
            final pStatus = order.paymentStatus.trim().toLowerCase();
            final oStatus = order.status.trim().toLowerCase();
            final isPaid = pStatus == 'paid' || oStatus == 'completed';
            final isOverdue =
                pStatus == 'overdue' ||
                (!isPaid &&
                    order.createdAt != null &&
                    order.createdAt!.isBefore(sevenDaysAgo));

            if (isPaid) {
              totalCollected += order.totalAmount;
              if (order.createdAt != null &&
                  order.createdAt!.isAfter(todayStart)) {
                todaysCollection += order.totalAmount;
              }
            } else {
              totalPending += order.totalAmount;
              if (isOverdue) {
                totalOverdue += order.totalAmount;
              }

              final shopKey = order.shopId.isNotEmpty
                  ? order.shopId
                  : order.shopName.toLowerCase().trim();

              final group = shopPendingMap.putIfAbsent(
                shopKey,
                () => _ShopPendingGroup(
                  shopId: order.shopId,
                  shopName: order.shopName.isNotEmpty
                      ? order.shopName
                      : (order.shopOwner.isNotEmpty
                            ? order.shopOwner
                            : 'Customer'),
                  shopOwner: order.shopOwner,
                  shopMobile: order.shopMobile,
                  deliveryAddress: order.deliveryAddress,
                  orders: [],
                ),
              );

              group.orders.add(order);
              group.totalOutstanding += order.totalAmount;
              if (isOverdue) group.hasOverdue = true;
            }
          }

          final pendingShopsList = shopPendingMap.values.toList()
            ..sort((a, b) => b.totalOutstanding.compareTo(a.totalOutstanding));

          // Filter by search query
          final filteredShops = pendingShopsList.where((g) {
            if (_search.isEmpty) return true;
            final q = _search.toLowerCase();
            final matchName = g.shopName.toLowerCase().contains(q);
            final matchOwner = g.shopOwner.toLowerCase().contains(q);
            final matchMobile = g.shopMobile.toLowerCase().contains(q);
            final matchOrderNum = g.orders.any(
              (o) => o.orderNumber.toLowerCase().contains(q),
            );
            return matchName || matchOwner || matchMobile || matchOrderNum;
          }).toList();

          return Column(
            children: [
              GradientHeader(
                title: locale.t('nav_payments'),
                subtitle: locale.t('pending_payments'),
                // leading: IconButton(
                //   icon: const Icon(
                //     Icons.arrow_back_rounded,
                //     color: Colors.white,
                //   ),
                //   onPressed: () => Navigator.of(context).pop(),
                // ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // KPI Row
                    SizedBox(
                      height: 130,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(
                            width: 170,
                            child: KpiCard(
                              label: locale.t('total_collected'),
                              value: '₹${numberFormat.format(totalCollected)}',
                              icon: Icons.check_circle_outline,
                              iconColor: AppColors.dairyGreen700,
                              iconBg: AppColors.dairyGreen100,
                              delta: 'All Time',
                              deltaPositive: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 170,
                            child: KpiCard(
                              label: locale.t('todays_collection'),
                              value:
                                  '₹${numberFormat.format(todaysCollection)}',
                              icon: Icons.today_rounded,
                              delta: 'Today',
                              deltaPositive: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 170,
                            child: KpiCard(
                              label: locale.t('pending_payments'),
                              value: '₹${numberFormat.format(totalPending)}',
                              icon: Icons.hourglass_empty,
                              iconColor: AppColors.amber600,
                              iconBg: AppColors.amber100,
                              delta: '${pendingShopsList.length} Shops',
                              deltaPositive: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 170,
                            child: KpiCard(
                              label: locale.t('outstanding_amount'),
                              value: '₹${numberFormat.format(totalPending)}',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.red600,
                              iconBg: AppColors.red100,
                              delta: totalOverdue > 0
                                  ? '₹${numberFormat.format(totalOverdue)} overdue'
                                  : 'All clear',
                              deltaPositive: totalOverdue == 0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Hero "Send Reminder to All" Action Banner ─────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.milkBlue800,
                            AppColors.milkBlue600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.milkBlue800.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Send Payment Reminders',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pendingShopsList.isNotEmpty
                                      ? '${pendingShopsList.length} shops with ₹${numberFormat.format(totalPending)} pending'
                                      : 'No pending payments at this time',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed:
                                (_isSendingReminder || pendingShopsList.isEmpty)
                                ? null
                                : () => _handleSendReminderToAll(
                                    distributorId: distributorId,
                                    totalOutstanding: totalPending,
                                    pendingShopsCount: pendingShopsList.length,
                                    locale: locale,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.milkBlue900,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isSendingReminder
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.milkBlue700,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 16),
                            label: Text(
                              locale.t('send_reminder_all'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search Bar
                    AppSearchBar(
                      hint: '${locale.t("search")} shop, invoice, phone…',
                      onChanged: (v) =>
                          setState(() => _search = v.trim().toLowerCase()),
                    ),

                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Shops (${filteredShops.length})',
                          style: AppTextStyles.h4.copyWith(fontSize: 14),
                        ),
                        Text(
                          'Total Due: ₹${numberFormat.format(totalPending)}',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.red600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Payments List
                    if (filteredShops.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: EmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'All Clear!',
                          subtitle: _search.isNotEmpty
                              ? 'No pending payments matching "$_search".'
                              : 'All shops have cleared their payments.',
                        ),
                      )
                    else
                      ...filteredShops.map((group) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ShopPendingCard(
                            group: group,
                            numberFormat: numberFormat,
                            locale: locale,
                            onSendReminder: () =>
                                _handleSendReminderToSingleShop(
                                  distributorId: distributorId,
                                  group: group,
                                  locale: locale,
                                ),
                            onRecordPayment: () => _handleRecordPayment(
                              distributorId: distributorId,
                              group: group,
                              locale: locale,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShopPendingCard extends StatelessWidget {
  final _ShopPendingGroup group;
  final NumberFormat numberFormat;
  final LocaleState locale;
  final VoidCallback onSendReminder;
  final VoidCallback onRecordPayment;

  const _ShopPendingCard({
    required this.group,
    required this.numberFormat,
    required this.locale,
    required this.onSendReminder,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: group.hasOverdue
              ? AppColors.red500.withValues(alpha: 0.5)
              : AppColors.border,
          width: group.hasOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: group.hasOverdue
                      ? AppColors.red100
                      : AppColors.amber100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  group.hasOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.hourglass_top_rounded,
                  color: group.hasOverdue
                      ? AppColors.red600
                      : AppColors.amber600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.shopName,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                    ),
                    if (group.shopOwner.isNotEmpty &&
                        group.shopOwner != group.shopName)
                      Text(
                        'Prop: ${group.shopOwner}${group.shopMobile.isNotEmpty ? " • ${group.shopMobile}" : ""}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${numberFormat.format(group.totalOutstanding)}',
                    style: AppTextStyles.data.copyWith(
                      color: group.hasOverdue
                          ? AppColors.red600
                          : AppColors.dairyGreen700,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppBadge(
                    label: group.hasOverdue ? 'OVERDUE' : 'PENDING',
                    variant: group.hasOverdue
                        ? BadgeVariant.error
                        : BadgeVariant.warning,
                    showDot: true,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Orders breakdown list
          Text(
            'Pending Orders (${group.orders.length}):',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.ink500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...group.orders.take(3).map((order) {
            final dateStr = order.createdAt != null
                ? dateFormat.format(order.createdAt!)
                : '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.orderNumber} ${dateStr.isNotEmpty ? "($dateStr)" : ""}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.milkBlue900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${numberFormat.format(order.totalAmount)}',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.ink700,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (group.orders.length > 3) ...[
            const SizedBox(height: 2),
            Text(
              '+ ${group.orders.length - 3} more orders',
              style: AppTextStyles.overline.copyWith(
                color: AppColors.ink500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Action Buttons: Record Payment & Send Reminder
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRecordPayment,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dairyGreen700,
                    side: const BorderSide(
                      color: AppColors.dairyGreen600,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    locale.t('record_payment'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSendReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: Text(
                    locale.t('send_reminder'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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
}
