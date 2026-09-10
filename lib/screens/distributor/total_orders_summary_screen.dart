import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/shop_service.dart';
import '../../services/total_orders_summary_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

class TotalOrdersSummaryScreen extends StatefulWidget {
  final String? initialDistributorId;
  final String initialDateFilter;

  const TotalOrdersSummaryScreen({
    super.key,
    this.initialDistributorId,
    this.initialDateFilter = 'Today',
  });

  @override
  State<TotalOrdersSummaryScreen> createState() =>
      _TotalOrdersSummaryScreenState();
}

class _TotalOrdersSummaryScreenState extends State<TotalOrdersSummaryScreen>
    with SingleTickerProviderStateMixin {
  late String _dateFilter;
  DateTimeRange? _customDateRange;
  final String _statusFilter = 'All';
  String _customerDeliveryFilter = 'All'; // 'All', 'Pending', 'Delivered'
  String _search = '';
  bool _isGeneratingPdf = false;
  bool _isBatchUpdating = false;
  Map<String, String>? _distributorInfo;
  int _selectedTab = 0; // 0: Customer Checklist, 1: Brand Totals

  final List<String> _dateOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'All Time',
    'Custom Range',
  ];

  final Set<String> _collapsedBrands = {};

  @override
  void initState() {
    super.initState();
    _dateFilter = widget.initialDateFilter;
    _loadDistributorInfo();
  }

  Future<void> _loadDistributorInfo() async {
    final distId = widget.initialDistributorId ??
        AuthService.currentUser?.uid ??
        '';
    if (distId.isNotEmpty) {
      final info = await ShopService.fetchDistributorInfo(distId);
      if (mounted && info != null) {
        setState(() => _distributorInfo = info);
      }
    }
  }

  bool _isOrderInDateRange(OrderModel order) {
    final orderDate = order.createdAt ?? DateTime.now();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_dateFilter) {
      case 'Today':
        return orderDate.isAfter(
              todayStart.subtract(const Duration(seconds: 1)),
            ) &&
            orderDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
      case 'Yesterday':
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(
          yestStart.year,
          yestStart.month,
          yestStart.day,
          23,
          59,
          59,
        );
        return orderDate.isAfter(
              yestStart.subtract(const Duration(seconds: 1)),
            ) &&
            orderDate.isBefore(yestEnd.add(const Duration(seconds: 1)));
      case 'This Week':
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        return orderDate.isAfter(
          weekStart.subtract(const Duration(seconds: 1)),
        );
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return orderDate.isAfter(
          monthStart.subtract(const Duration(seconds: 1)),
        );
      case 'Custom Range':
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return orderDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
            orderDate.isBefore(end.add(const Duration(seconds: 1)));
      case 'All Time':
      default:
        return true;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final initial = _customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initial,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.milkBlue700,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: AppColors.ink900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = 'Custom Range';
      });
    }
  }

  String _getDateFilterLabel() {
    if (_dateFilter == 'Custom Range' && _customDateRange != null) {
      final df = DateFormat('dd MMM');
      return '${df.format(_customDateRange!.start)} - ${df.format(_customDateRange!.end)}';
    }
    return _dateFilter;
  }

  Future<void> _handleDownloadPdf(TotalOrdersReportData reportData) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final companyName =
          _distributorInfo?['companyName'] ?? 'Bhargavi Milk Distribution';
      final ownerName = _distributorInfo?['distributorName'] ?? '';
      final mobile = _distributorInfo?['mobile'] ?? '';
      final address = _distributorInfo?['address'] ?? '';

      await TotalOrdersSummaryService.downloadOrPrintPdf(
        report: reportData,
        distributorCompanyName: companyName,
        distributorOwnerName: ownerName,
        distributorMobile: mobile,
        distributorAddress: address,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSharePdf(TotalOrdersReportData reportData) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final companyName =
          _distributorInfo?['companyName'] ?? 'Bhargavi Milk Distribution';
      final ownerName = _distributorInfo?['distributorName'] ?? '';
      final mobile = _distributorInfo?['mobile'] ?? '';
      final address = _distributorInfo?['address'] ?? '';

      await TotalOrdersSummaryService.sharePdfReport(
        report: reportData,
        distributorCompanyName: companyName,
        distributorOwnerName: ownerName,
        distributorMobile: mobile,
        distributorAddress: address,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _toggleOrderChecklist(
    CustomerOrderSummary customer,
    String distributorId,
  ) async {
    final newStatus = customer.isChecked ? 'confirmed' : 'delivered';
    try {
      await OrderService.updateOrderStatus(
        distributorId: distributorId,
        orderId: customer.orderId,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'delivered'
                  ? 'Marked ${customer.shopName} as Delivered! ✓'
                  : 'Marked ${customer.shopName} as Pending',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: newStatus == 'delivered'
                ? AppColors.dairyGreen600
                : AppColors.milkBlue700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update status: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    }
  }

  Future<void> _toggleSelectAll(
    List<CustomerOrderSummary> displayedCustomers,
    String distributorId,
  ) async {
    if (displayedCustomers.isEmpty || _isBatchUpdating) return;

    final allDelivered = displayedCustomers.every((c) => c.isChecked);
    final targetStatus = allDelivered ? 'confirmed' : 'delivered';
    final targetCustomers = allDelivered
        ? displayedCustomers
        : displayedCustomers.where((c) => !c.isChecked).toList();

    if (targetCustomers.isEmpty) return;

    setState(() => _isBatchUpdating = true);

    try {
      final orderIds = targetCustomers.map((c) => c.orderId).toList();
      await OrderService.batchUpdateOrderStatus(
        distributorId: distributorId,
        orderIds: orderIds,
        newStatus: targetStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetStatus == 'delivered'
                  ? 'Marked ${targetCustomers.length} order(s) as Delivered! ✓'
                  : 'Marked ${targetCustomers.length} order(s) as Pending',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: targetStatus == 'delivered'
                ? AppColors.dairyGreen600
                : AppColors.milkBlue700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update orders: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBatchUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final auth = AuthStateScope.of(context);
    final distributorId = widget.initialDistributorId ??
        auth.distributorId ??
        AuthService.currentUser?.uid ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          GradientHeader(
            title: _dateFilter == 'Today'
                ? locale.t('total_today_orders')
                : locale.t('total_orders_summary'),
            subtitle: 'Customer Checklist & Brand Loading Summary',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isGeneratingPdf)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Segmented Navigation Tabs ────────────────────────────────────────
          Container(
            color: AppColors.cardSurface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? AppColors.milkBlue700
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: AppColors.milkBlue700.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checklist_rtl_rounded,
                              size: 18,
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : AppColors.ink700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale.t('customer_checklist'),
                              style: TextStyle(
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 12.5,
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? AppColors.milkBlue700
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: AppColors.milkBlue700.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart_rounded,
                              size: 18,
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : AppColors.ink700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale.t('brand_wise_summary'),
                              style: TextStyle(
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 12.5,
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : AppColors.ink700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Filters & Search Section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dateOptions.map((opt) {
                      final isSelected = _dateFilter == opt;
                      final label =
                          opt == 'Custom Range' &&
                              _customDateRange != null &&
                              isSelected
                          ? _getDateFilterLabel()
                          : opt;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: opt == 'Custom Range'
                              ? Icon(
                                  Icons.date_range_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.milkBlue700,
                                )
                              : null,
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (opt == 'Custom Range') {
                              _pickCustomDateRange();
                            } else {
                              setState(() {
                                _dateFilter = opt;
                                _customDateRange = null;
                              });
                            }
                          },
                          backgroundColor: AppColors.cardSurface,
                          selectedColor: AppColors.milkBlue700,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.ink700,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.milkBlue700
                                  : AppColors.border,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 6),

                // Search Bar
                AppSearchBar(
                  hint: _selectedTab == 0
                      ? '${locale.t("search")} customer, shop, phone, items…'
                      : '${locale.t("search")} brands, products, 500ml, 1L…',
                  onChanged: (val) =>
                      setState(() => _search = val.trim().toLowerCase()),
                ),
              ],
            ),
          ),

          // ── Content Stream ──────────────────────────────────────────────────
          Expanded(
            child: distributorId.isEmpty
                ? const Center(child: Text('Distributor login required'))
                : StreamBuilder<List<OrderModel>>(
                    stream: OrderService.streamDistributorOrders(
                      distributorId: distributorId,
                      statusFilter: _statusFilter,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allOrders = snapshot.data ?? [];
                      final dateFilteredOrders =
                          allOrders.where(_isOrderInDateRange).toList();

                      final reportData = TotalOrdersSummaryService.processOrders(
                        orders: dateFilteredOrders,
                        dateFilterName: _getDateFilterLabel(),
                        statusFilter: _statusFilter == 'All'
                            ? 'All Statuses'
                            : locale.translateStatus(_statusFilter),
                      );

                      if (dateFilteredOrders.isEmpty) {
                        return EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: locale.t('no_data'),
                          subtitle: _dateFilter == 'Today'
                              ? 'No orders placed today yet.'
                              : 'No orders found for the selected date range.',
                        );
                      }

                      final numberFormat = NumberFormat('#,##,##0.00', 'en_IN');

                      return Column(
                        children: [
                          Expanded(
                            child: _selectedTab == 0
                                ? _buildCustomerChecklistView(
                                    reportData: reportData,
                                    distributorId: distributorId,
                                    numberFormat: numberFormat,
                                    locale: locale,
                                  )
                                : _buildBrandWiseTotalsView(
                                    reportData: reportData,
                                    numberFormat: numberFormat,
                                    locale: locale,
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Bottom Fixed Action Bar ─────────────────────────────────────────────
      bottomSheet: distributorId.isEmpty
          ? null
          : StreamBuilder<List<OrderModel>>(
              stream: OrderService.streamDistributorOrders(
                distributorId: distributorId,
                statusFilter: _statusFilter,
              ),
              builder: (context, snapshot) {
                final allOrders = snapshot.data ?? [];
                final dateFilteredOrders =
                    allOrders.where(_isOrderInDateRange).toList();
                final reportData = TotalOrdersSummaryService.processOrders(
                  orders: dateFilteredOrders,
                  dateFilterName: _getDateFilterLabel(),
                  statusFilter: _statusFilter == 'All'
                      ? 'All Statuses'
                      : locale.translateStatus(_statusFilter),
                );

                if (dateFilteredOrders.isEmpty) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Share Button
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _handleSharePdf(reportData),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.milkBlue700,
                              side: const BorderSide(
                                color: AppColors.milkBlue700,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: Text(
                              locale.t('share'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Download PDF Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf
                                ? null
                                : () => _handleDownloadPdf(reportData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.milkBlue700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                            icon: _isGeneratingPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              locale.t('download_pdf'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // =========================================================================
  // TAB 1: CUSTOMER-WISE CHECKLIST VIEW
  // =========================================================================
  Widget _buildCustomerChecklistView({
    required TotalOrdersReportData reportData,
    required String distributorId,
    required NumberFormat numberFormat,
    required LocaleState locale,
  }) {
    final customers = reportData.customerSummaries;
    final totalCustomers = customers.length;
    final deliveredCount = customers.where((c) => c.isChecked).length;
    final progressPercent = totalCustomers > 0
        ? (deliveredCount / totalCustomers)
        : 0.0;

    // Filter customers by status filter & search
    final displayedCustomers = customers.where((c) {
      if (_customerDeliveryFilter == 'Pending' && c.isChecked) return false;
      if (_customerDeliveryFilter == 'Delivered' && !c.isChecked) return false;

      if (_search.isNotEmpty) {
        final q = _search;
        final matchShop = c.shopName.toLowerCase().contains(q);
        final matchOwner = c.shopOwner.toLowerCase().contains(q);
        final matchMobile = c.shopMobile.toLowerCase().contains(q);
        final matchAddr = c.deliveryAddress.toLowerCase().contains(q);
        final matchItems = c.items.any(
          (i) => i.productName.toLowerCase().contains(q),
        );
        return matchShop || matchOwner || matchMobile || matchAddr || matchItems;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 95),
      children: [
        // ── Checklist Progress Banner ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.milkBlue800, AppColors.milkBlue600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.milkBlue700.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Checklist Progress',
                        style: AppTextStyles.captionBold.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$deliveredCount / $totalCustomers Done',
                      style: const TextStyle(
                        color: AppColors.milkBlue800,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.dairyGreen500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progressPercent * 100).toInt()}% Delivered',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Total: ${reportData.grandTotalQuantity} Pkts • ₹${numberFormat.format(reportData.grandTotalRupees)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Delivery Status Quick Filter Chips ────────────────────────────────
        Row(
          children: [
            _deliveryFilterChip(
              label: 'All ($totalCustomers)',
              selected: _customerDeliveryFilter == 'All',
              onTap: () => setState(() => _customerDeliveryFilter = 'All'),
            ),
            const SizedBox(width: 8),
            _deliveryFilterChip(
              label: 'Pending (${totalCustomers - deliveredCount})',
              selected: _customerDeliveryFilter == 'Pending',
              color: AppColors.amber600,
              onTap: () => setState(() => _customerDeliveryFilter = 'Pending'),
            ),
            const SizedBox(width: 8),
            _deliveryFilterChip(
              label: 'Delivered ($deliveredCount)',
              selected: _customerDeliveryFilter == 'Delivered',
              color: AppColors.dairyGreen600,
              onTap: () =>
                  setState(() => _customerDeliveryFilter = 'Delivered'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Section Title & Select All Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Orders (${displayedCustomers.length})',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.ink900,
                fontSize: 14,
              ),
            ),
            if (displayedCustomers.isNotEmpty)
              _buildSelectAllButton(
                displayedCustomers: displayedCustomers,
                distributorId: distributorId,
                locale: locale,
              )
            else
              Text(
                'Tap [✓] to mark delivery',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.milkBlue700,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Customer Cards List
        if (displayedCustomers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'No customer orders matching "$_customerDeliveryFilter".',
              style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
            ),
          )
        else
          ...displayedCustomers.map((cust) {
            return _buildCustomerCard(
              customer: cust,
              distributorId: distributorId,
              numberFormat: numberFormat,
              locale: locale,
            );
          }),
      ],
    );
  }

  Widget _buildSelectAllButton({
    required List<CustomerOrderSummary> displayedCustomers,
    required String distributorId,
    required LocaleState locale,
  }) {
    final allDelivered = displayedCustomers.isNotEmpty &&
        displayedCustomers.every((c) => c.isChecked);
    final someDelivered = displayedCustomers.any((c) => c.isChecked);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isBatchUpdating
            ? null
            : () => _toggleSelectAll(displayedCustomers, distributorId),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: allDelivered
                ? AppColors.dairyGreen100
                : AppColors.milkBlue100.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: allDelivered
                  ? AppColors.dairyGreen600
                  : AppColors.milkBlue700,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isBatchUpdating)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.milkBlue700,
                  ),
                )
              else
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: allDelivered
                        ? true
                        : (someDelivered ? null : false),
                    tristate: true,
                    activeColor: AppColors.dairyGreen600,
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: _isBatchUpdating
                        ? null
                        : (_) => _toggleSelectAll(
                              displayedCustomers,
                              distributorId,
                            ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                allDelivered
                    ? locale.t('deselect_all')
                    : locale.t('select_all'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allDelivered
                      ? AppColors.dairyGreen700
                      : AppColors.milkBlue800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deliveryFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.milkBlue700;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard({
    required CustomerOrderSummary customer,
    required String distributorId,
    required NumberFormat numberFormat,
    required LocaleState locale,
  }) {
    final isDelivered = customer.isChecked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDelivered ? AppColors.dairyGreen500 : AppColors.border,
          width: isDelivered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDelivered
                  ? AppColors.dairyGreen100.withValues(alpha: 0.5)
                  : AppColors.milkBlue100.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                // Interactive Checkbox
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isDelivered,
                    activeColor: AppColors.dairyGreen600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: _isBatchUpdating
                        ? null
                        : (val) {
                            _toggleOrderChecklist(customer, distributorId);
                          },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.shopName,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 13.5,
                          color: AppColors.ink900,
                        ),
                      ),
                      if (customer.shopOwner.isNotEmpty &&
                          customer.shopOwner != customer.shopName)
                        Text(
                          'Prop: ${customer.shopOwner}',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.ink500,
                          ),
                        ),
                    ],
                  ),
                ),
                AppBadge(
                  label: isDelivered ? 'DELIVERED' : 'PENDING',
                  variant: isDelivered
                      ? BadgeVariant.success
                      : BadgeVariant.warning,
                  showDot: true,
                ),
              ],
            ),
          ),

          // Customer Details & Products
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone & Address
                if (customer.shopMobile.isNotEmpty ||
                    customer.deliveryAddress.isNotEmpty)
                  Row(
                    children: [
                      if (customer.shopMobile.isNotEmpty) ...[
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: AppColors.ink500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          customer.shopMobile,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.milkBlue800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (customer.deliveryAddress.isNotEmpty) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.ink500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.deliveryAddress,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Product Items List
                Text(
                  'Items Ordered:',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),

                ...customer.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${locale.translateProduct(item.productName)} (${item.packSize})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '× ${item.quantity} ${item.unit}',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.milkBlue800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${numberFormat.format(item.subtotal)}',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.ink900,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Bottom summary row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${customer.totalQuantity} Units',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.milkBlue700,
                      ),
                    ),
                    Row(
                      children: [
                        AppBadge(
                          label: locale.translateStatus(customer.paymentStatus),
                          variant: paymentStatusVariant(customer.paymentStatus),
                          showDot: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${numberFormat.format(customer.totalAmount)}',
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 14,
                            color: AppColors.dairyGreen700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: BRAND-WISE TOTALS VIEW
  // =========================================================================
  Widget _buildBrandWiseTotalsView({
    required TotalOrdersReportData reportData,
    required NumberFormat numberFormat,
    required LocaleState locale,
  }) {
    final displayedBrands = reportData.brandSummaries.where((brand) {
      if (_search.isEmpty) return true;
      final matchesBrand = brand.brandName.toLowerCase().contains(_search);
      final matchesVariant = brand.variantList.any(
        (v) =>
            v.productName.toLowerCase().contains(_search) ||
            v.packSize.toLowerCase().contains(_search),
      );
      return matchesBrand || matchesVariant;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
      children: [
        // ── Top KPI Overview Cards ─────────────────────
        _buildKpiGrid(reportData, numberFormat, locale),

        const SizedBox(height: 14),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale.t('total_orders_brand_summary'),
              style: AppTextStyles.h4.copyWith(
                color: AppColors.ink900,
                fontSize: 14,
              ),
            ),
            Text(
              '${displayedBrands.length} Brands',
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.milkBlue700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Brand Cards List ───────────────────────────
        ...displayedBrands.map((brand) {
          final isCollapsed = _collapsedBrands.contains(brand.brandName);
          return _buildBrandCard(
            brand: brand,
            isCollapsed: isCollapsed,
            numberFormat: numberFormat,
            locale: locale,
            onToggle: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedBrands.remove(brand.brandName);
                } else {
                  _collapsedBrands.add(brand.brandName);
                }
              });
            },
          );
        }),

        const SizedBox(height: 14),

        // ── Grand Total Banner Box ─────────────────────
        _buildGrandTotalCard(reportData, numberFormat, locale),
      ],
    );
  }

  // ── KPI Summary Cards Grid ──────────────────────────────────────────────────
  Widget _buildKpiGrid(
    TotalOrdersReportData data,
    NumberFormat nf,
    LocaleState locale,
  ) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            title: locale.t('total_orders'),
            value: '${data.totalOrdersCount}',
            unit: 'Orders',
            icon: Icons.receipt_long_rounded,
            color: AppColors.milkBlue700,
            bgColor: AppColors.milkBlue100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard(
            title: 'Total Quantity',
            value: '${data.grandTotalQuantity}',
            unit: 'Pkts/Units',
            icon: Icons.inventory_2_rounded,
            color: AppColors.dairyGreen700,
            bgColor: AppColors.dairyGreen100,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiCard(
            title: 'Total Revenue',
            value: '₹${nf.format(data.grandTotalRupees)}',
            unit: 'Rupees',
            icon: Icons.currency_rupee_rounded,
            color: AppColors.milkBlue900,
            bgColor: AppColors.amber100,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Text(
                unit,
                style: AppTextStyles.overline.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.captionBold.copyWith(
              color: color,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: AppTextStyles.overline.copyWith(color: AppColors.ink500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Brand Breakdown Card ───────────────────────────────────────────────────
  Widget _buildBrandCard({
    required BrandSummary brand,
    required bool isCollapsed,
    required NumberFormat numberFormat,
    required LocaleState locale,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.milkBlue700,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BRAND',
                      style: AppTextStyles.overline.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      brand.brandName.toUpperCase(),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.milkBlue900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${brand.totalQuantity} Units',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.ink900,
                        ),
                      ),
                      Text(
                        '₹${numberFormat.format(brand.totalRupees)}',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.dairyGreen700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.ink500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Product Variant Table
          if (!isCollapsed) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.background.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Product / Variant',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.ink500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Pack Size',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.ink500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Qty',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.ink500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Total (₹)',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.ink500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brand.variantList.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 14, endIndent: 14),
              itemBuilder: (_, i) {
                final v = brand.variantList[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          locale.translateProduct(v.productName),
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.ink900,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.milkBlue100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            v.packSize,
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.milkBlue800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${v.totalQuantity} ${v.unit}',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.milkBlue800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${numberFormat.format(v.totalRupees)}',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.dairyGreen700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── Grand Total Banner Card ────────────────────────────────────────────────
  Widget _buildGrandTotalCard(
    TotalOrdersReportData report,
    NumberFormat numberFormat,
    LocaleState locale,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.milkBlue100.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.milkBlue700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRAND TOTAL SUMMARY',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.milkBlue900,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.milkBlue700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${report.totalOrdersCount} Orders',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Quantity',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.grandTotalQuantity} Pkts/Units',
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 16,
                      color: AppColors.milkBlue900,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${numberFormat.format(report.grandTotalRupees)}',
                    style: AppTextStyles.h4.copyWith(
                      fontSize: 18,
                      color: AppColors.dairyGreen700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
