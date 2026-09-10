import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/pdf_receipt_service.dart';
import '../../services/shop_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/gradient_header.dart';

class ShopPaymentScreen extends StatefulWidget {
  final OrderModel? order;
  final double? amountDue;
  final String? distributorId;
  final String? distributorName;
  final String? invoiceId;

  const ShopPaymentScreen({
    super.key,
    this.order,
    this.amountDue,
    this.distributorId,
    this.distributorName,
    this.invoiceId,
  });

  @override
  State<ShopPaymentScreen> createState() => _ShopPaymentScreenState();
}

class _ShopPaymentScreenState extends State<ShopPaymentScreen> {
  String _paymentMethod = 'upi';
  bool _isProcessing = false;
  bool _paid = false;

  late final Razorpay _razorpay;
  String? _lastTransactionId;
  OrderModel? _lastPaidOrder;
  double _lastPaidAmount = 0.0;
  double _lastRemainingBalance = 0.0;

  // Selected order to pay if multiple pending orders exist
  String _selectedOrderId = 'ALL';

  // Active transaction temporary memory for Razorpay SDK callback
  List<String> _pendingOrderIds = [];
  List<String> _pendingOrderNumbers = [];
  double _pendingAmount = 0.0;
  double _pendingRemaining = 0.0;
  OrderModel? _pendingOrder;

  Map<String, String>? _distributorInfo;

  static const _methods = [
    ('upi', Icons.qr_code_2, 'pay_upi'),
    ('cod', Icons.money, 'pay_cod'),
    ('bank', Icons.account_balance_outlined, 'pay_bank'),
    ('credit', Icons.credit_card_outlined, 'pay_credit'),
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadDistributorDetails();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadDistributorDetails() async {
    final distId = widget.distributorId ??
        widget.order?.distributorId ??
        '';
    if (distId.isNotEmpty) {
      final info = await ShopService.fetchDistributorInfo(distId);
      if (mounted) setState(() => _distributorInfo = info);
    }
  }

  String _resolveDistributorId(BuildContext context) {
    if (widget.distributorId != null && widget.distributorId!.isNotEmpty) {
      return widget.distributorId!;
    }
    if (widget.order != null && widget.order!.distributorId.isNotEmpty) {
      return widget.order!.distributorId;
    }
    try {
      final auth = AuthStateScope.of(context);
      if (auth.distributorId != null && auth.distributorId!.isNotEmpty) {
        return auth.distributorId!;
      }
      if (auth.shopProfile?.distributorId.isNotEmpty == true) {
        return auth.shopProfile!.distributorId;
      }
    } catch (_) {}
    return '';
  }

  String _resolveShopUid() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final distributorId = _resolveDistributorId(context);
    final shopUid = _resolveShopUid();

    final inv = widget.order?.orderNumber ??
        widget.invoiceId ??
        (widget.amountDue != null ? 'Pending Balance' : '#DUE-SETTLEMENT');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('nav_payments'),
            subtitle: '${locale.t("invoice_no")} $inv',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _paid
                ? _buildSuccessView(context, locale)
                : StreamBuilder<List<OrderModel>>(
                    stream: OrderService.streamShopOrders(
                      distributorId: distributorId,
                      shopUid: shopUid,
                    ),
                    builder: (context, ordersSnap) {
                      final allShopOrders = ordersSnap.data ?? [];
                      final pendingOrders = allShopOrders
                          .where((o) =>
                              o.paymentStatus.toLowerCase() == 'pending')
                          .toList();

                      return _buildPaymentView(
                        context: context,
                        locale: locale,
                        distributorId: distributorId,
                        shopUid: shopUid,
                        pendingOrders: pendingOrders,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentView({
    required BuildContext context,
    required LocaleState locale,
    required String distributorId,
    required String shopUid,
    required List<OrderModel> pendingOrders,
  }) {
    final auth = AuthStateScope.of(context);
    final profile = auth.shopProfile;

    // Calculate pending dues
    final double totalPendingDues = pendingOrders.fold<double>(
      0.0,
      (sum, o) => sum + o.totalAmount,
    );

    double payableAmount = 0.0;
    OrderModel? targetOrder = widget.order;

    if (widget.order != null) {
      payableAmount = widget.order!.totalAmount;
      targetOrder = widget.order;
    } else if (widget.amountDue != null && widget.amountDue! > 0) {
      payableAmount = widget.amountDue!;
    } else if (_selectedOrderId != 'ALL') {
      final match = pendingOrders.where((o) => o.id == _selectedOrderId).firstOrNull;
      if (match != null) {
        payableAmount = match.totalAmount;
        targetOrder = match;
      } else {
        payableAmount = totalPendingDues;
      }
    } else {
      payableAmount = totalPendingDues > 0
          ? totalPendingDues
          : (profile?.outstanding ?? 0.0);
    }

    final numberFormat = NumberFormat('#,##,##0', 'en_IN');
    final formattedPayable = '₹${numberFormat.format(payableAmount)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice / Dues info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.milkBlue700, AppColors.milkBlue500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.milkBlue700.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
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
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            targetOrder?.orderNumber ??
                                widget.invoiceId ??
                                (pendingOrders.isNotEmpty
                                    ? '${pendingOrders.length} Unpaid Orders'
                                    : '#SETTLEMENT'),
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
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _invoiceCell(
                      locale.t('amount_due'),
                      formattedPayable,
                      Colors.white70,
                      Colors.white,
                    ),
                    _invoiceCell(
                      locale.t('prev_outstanding'),
                      '₹${numberFormat.format(totalPendingDues > 0 ? totalPendingDues : (profile?.outstanding ?? 0.0))}',
                      Colors.white70,
                      Colors.white,
                    ),
                    _invoiceCell(
                      locale.t('total_payable'),
                      formattedPayable,
                      Colors.white70,
                      Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Multiple pending orders selector (if no specific order was passed)
          if (widget.order == null && pendingOrders.length > 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Pending Order to Pay',
                    style: AppTextStyles.bodyBold,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedOrderId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text(
                          'Pay All Unpaid Orders (₹${numberFormat.format(totalPendingDues)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...pendingOrders.map(
                        (o) => DropdownMenuItem(
                          value: o.id,
                          child: Text(
                            '${o.orderNumber} - ₹${numberFormat.format(o.totalAmount)} (${o.items.length} items)',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedOrderId = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],

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

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing || payableAmount <= 0
                  ? null
                  : () => _initiatePayment(
                        context: context,
                        distributorId: distributorId,
                        shopUid: shopUid,
                        payableAmount: payableAmount,
                        pendingOrders: pendingOrders,
                        targetOrder: targetOrder,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dairyGreen600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      '${locale.t('confirm')} $formattedPayable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiatePayment({
    required BuildContext context,
    required String distributorId,
    required String shopUid,
    required double payableAmount,
    required List<OrderModel> pendingOrders,
    OrderModel? targetOrder,
  }) async {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account error: Distributor ID or Shop ID missing.'),
          backgroundColor: AppColors.red500,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final auth = AuthStateScope.of(context);
    final shopProfile = auth.shopProfile;

    setState(() => _isProcessing = true);

    try {
      // Determine order IDs to settle
      List<String> orderIdsToSettle = [];
      List<String> orderNumbersToSettle = [];

      if (targetOrder != null) {
        orderIdsToSettle = [targetOrder.id];
        orderNumbersToSettle = [targetOrder.orderNumber];
      } else if (_selectedOrderId != 'ALL') {
        final match = pendingOrders.where((o) => o.id == _selectedOrderId).firstOrNull;
        if (match != null) {
          orderIdsToSettle = [match.id];
          orderNumbersToSettle = [match.orderNumber];
          targetOrder = match;
        }
      } else {
        orderIdsToSettle = pendingOrders.map((o) => o.id).toList();
        orderNumbersToSettle = pendingOrders.map((o) => o.orderNumber).toList();
        if (pendingOrders.isNotEmpty) {
          targetOrder = pendingOrders.first;
        }
      }

      final updatedTotalPending = (pendingOrders.fold<double>(0.0, (s, o) => s + o.totalAmount) - payableAmount).clamp(0.0, double.infinity);

      // 1. UPI / Razorpay Online Flow
      if (_paymentMethod == 'upi') {
        _pendingOrderIds = orderIdsToSettle;
        _pendingOrderNumbers = orderNumbersToSettle;
        _pendingAmount = payableAmount;
        _pendingRemaining = updatedTotalPending;
        _pendingOrder = targetOrder;

        final amountInPaise = (payableAmount * 100).round();
        final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
        final callable = functions.httpsCallable('createRazorpayOrder');

        final result = await callable.call({'amount': amountInPaise});
        final data = Map<String, dynamic>.from(result.data as Map);

        if (data['success'] != true) {
          throw Exception('Unable to create Razorpay payment order.');
        }

        final razorpayOrderId = data['orderId']?.toString();
        final razorpayKeyId = data['keyId']?.toString();
        final returnedAmount = data['amount'];

        final options = {
          'key': razorpayKeyId,
          'amount': returnedAmount,
          'currency': 'INR',
          'name': 'Bhargavi Milk',
          'description': 'Milk Dues Payment',
          'order_id': razorpayOrderId,
          'timeout': 300,
          'prefill': {
            'contact': shopProfile?.mobile ?? '',
            'name': shopProfile?.ownerName.isNotEmpty == true
                ? shopProfile!.ownerName
                : (shopProfile?.shopName ?? 'Shop'),
          },
          'theme': {'color': '#0047FF'},
        };

        // Open Razorpay Sheet
        _razorpay.open(options);
        return;
      }

      // 2. Offline / Cash / Bank / Credit Direct Settlement Flow
      final txnId = await PaymentService.recordPayment(
        distributorId: distributorId,
        shopId: shopUid,
        shopName: shopProfile?.shopName ?? 'My Dairy Shop',
        shopOwner: shopProfile?.ownerName ?? '',
        shopMobile: shopProfile?.mobile ?? '',
        orderIds: orderIdsToSettle,
        orderNumbers: orderNumbersToSettle,
        amount: payableAmount,
        paymentMethod: _paymentMethod,
        paymentStatus: 'Paid',
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _paid = true;
          _lastTransactionId = txnId;
          _lastPaidAmount = payableAmount;
          _lastRemainingBalance = updatedTotalPending;
          _lastPaidOrder = targetOrder;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = AuthStateScope.of(context);
    final shopProfile = auth.shopProfile;
    final distributorId = _resolveDistributorId(context);
    final shopUid = _resolveShopUid();

    final orderIds = _pendingOrderIds.isNotEmpty
        ? _pendingOrderIds
        : (widget.order != null ? [widget.order!.id] : <String>[]);
    final orderNumbers = _pendingOrderNumbers.isNotEmpty
        ? _pendingOrderNumbers
        : (widget.order != null ? [widget.order!.orderNumber] : <String>[]);
    final amount = _pendingAmount > 0
        ? _pendingAmount
        : (widget.amountDue ?? widget.order?.totalAmount ?? 0.0);
    final remaining = _pendingRemaining;
    final paidOrder = _pendingOrder ?? widget.order;

    try {
      final txnId = await PaymentService.recordPayment(
        distributorId: distributorId,
        shopId: shopUid,
        shopName: shopProfile?.shopName ?? 'My Dairy Shop',
        shopOwner: shopProfile?.ownerName ?? '',
        shopMobile: shopProfile?.mobile ?? '',
        orderIds: orderIds,
        orderNumbers: orderNumbers,
        amount: amount,
        paymentMethod: 'upi',
        paymentStatus: 'Paid',
        transactionId: response.paymentId,
        razorpayPaymentId: response.paymentId,
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _paid = true;
          _lastTransactionId = txnId;
          _lastPaidAmount = amount;
          _lastRemainingBalance = remaining;
          _lastPaidOrder = paidOrder;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Payment succeeded but saving failed: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Cancelled"}'),
          backgroundColor: AppColors.red500,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet: ${response.walletName ?? "Selected"}')),
      );
    }
  }

  Widget _buildSuccessView(BuildContext context, LocaleState locale) {
    final numberFormat = NumberFormat('#,##,##0', 'en_IN');
    final formattedPaid = '₹${numberFormat.format(_lastPaidAmount)}';
    final formattedBalance = '₹${numberFormat.format(_lastRemainingBalance)}';
    final txn = _lastTransactionId ?? 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.dairyGreen500, AppColors.dairyGreen700],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.dairyGreen500.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            locale.t('payment_success'),
            style: AppTextStyles.h3.copyWith(color: AppColors.dairyGreen700),
          ),
          const SizedBox(height: 6),
          Text(
            locale.t('payment_processed_success'),
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dairyGreen100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dairyGreen300),
            ),
            child: Column(
              children: [
                _detailRow(locale.t('transaction_id'), txn),
                const Divider(height: 16),
                _detailRow(
                  locale.t('amount_paid'),
                  formattedPaid,
                  valueColor: AppColors.dairyGreen700,
                ),
                const Divider(height: 16),
                _detailRow(
                  locale.t('remaining_balance'),
                  formattedBalance,
                  valueColor: _lastRemainingBalance > 0
                      ? AppColors.amber700
                      : AppColors.dairyGreen700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Receipt Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final orderToPrint = _lastPaidOrder ??
                        OrderModel(
                          id: txn,
                          orderNumber: '#$txn',
                          shopId: _resolveShopUid(),
                          shopName: AuthStateScope.of(context).shopProfile?.shopName ?? 'My Shop',
                          distributorId: _resolveDistributorId(context),
                          items: const [],
                          products: ['Settlement Payment ($formattedPaid)'],
                          totalQuantity: 1,
                          subtotal: _lastPaidAmount,
                          deliveryCharge: 0.0,
                          discount: 0.0,
                          totalAmount: _lastPaidAmount,
                          status: 'completed',
                          deliveryAddress: AuthStateScope.of(context).shopProfile?.address ?? '',
                          deliveryDate: 'Today',
                          deliveryTime: 'Immediate',
                          paymentMethod: _paymentMethod,
                          paymentStatus: 'Paid',
                          createdAt: DateTime.now(),
                        );

                    PdfReceiptService.previewReceipt(
                      context: context,
                      order: orderToPrint,
                      distributorInfo: _distributorInfo,
                      transactionId: txn,
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
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
                  onPressed: () {
                    final orderToPrint = _lastPaidOrder ??
                        OrderModel(
                          id: txn,
                          orderNumber: '#$txn',
                          shopId: _resolveShopUid(),
                          shopName: AuthStateScope.of(context).shopProfile?.shopName ?? 'My Shop',
                          distributorId: _resolveDistributorId(context),
                          items: const [],
                          products: ['Settlement Payment ($formattedPaid)'],
                          totalQuantity: 1,
                          subtotal: _lastPaidAmount,
                          deliveryCharge: 0.0,
                          discount: 0.0,
                          totalAmount: _lastPaidAmount,
                          status: 'completed',
                          deliveryAddress: AuthStateScope.of(context).shopProfile?.address ?? '',
                          deliveryDate: 'Today',
                          deliveryTime: 'Immediate',
                          paymentMethod: _paymentMethod,
                          paymentStatus: 'Paid',
                          createdAt: DateTime.now(),
                        );

                    PdfReceiptService.printReceipt(
                      order: orderToPrint,
                      distributorInfo: _distributorInfo,
                      transactionId: txn,
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: Text(locale.t('print')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.milkBlue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.t('back')),
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
          const SizedBox(height: 2),
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
