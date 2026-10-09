import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/distributor_settings_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/gradient_header.dart';
import 'order_success_screen.dart';
import 'shop_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String distributorId;
  final List<(Product, int)> cartItems;
  final double total;
  final VoidCallback? onOrderPlaced;

  const CheckoutScreen({
    super.key,
    required this.distributorId,
    required this.cartItems,
    required this.total,
    this.onOrderPlaced,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ============================================================
  // PAYMENT
  // ============================================================

  String _paymentMethod = 'upi';

  late final TextEditingController _addressCtrl;
  late final Razorpay _razorpay;

  String _deliveryDate = 'Tomorrow Morning';
  final String _deliveryTime = 'Morning (6–9 AM)';

  bool _addressInitialized = false;
  bool _isPlacingOrder = false;

  // ============================================================
  // PENDING RAZORPAY ORDER INFORMATION
  // ============================================================

  String? _pendingDistributorId;
  String? _pendingShopId;

  String? _pendingShopName;
  String? _pendingShopOwner;
  String? _pendingShopMobile;
  String? _pendingAddress;

  List<OrderItem>? _pendingOrderItems;

  double? _pendingSubtotal;
  double? _pendingDeliveryCharge;
  double? _pendingDiscount;
  double? _pendingTotalAmount;

  int? _pendingTotalQuantity;

  // ============================================================
  // PAYMENT METHODS
  // ============================================================

  static const _methods = [
    ('upi', Icons.qr_code_2, 'pay_upi'),
    ('cod', Icons.money, 'pay_cod'),
    ('bank', Icons.account_balance_outlined, 'pay_bank'),
    ('credit', Icons.credit_card_outlined, 'pay_credit'),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _addressCtrl = TextEditingController();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_addressInitialized) {
      final auth = AuthStateScope.of(context);
      final shop = auth.shopProfile;

      if (shop != null && shop.address.isNotEmpty) {
        _addressCtrl.text = shop.address;
        _addressInitialized = true;
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _razorpay.clear();
    _addressCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // MAIN PLACE ORDER
  // ============================================================

  Future<void> _handlePlaceOrder(LocaleState locale, AuthState auth) async {
    final address = _addressCtrl.text.trim();

    // ----------------------------------------------------------
    // ADDRESS VALIDATION
    // ----------------------------------------------------------

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.t('delivery_address')),
          backgroundColor: AppColors.red500,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CURRENT LOGGED-IN USER
    // ----------------------------------------------------------

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before placing an order.'),
          backgroundColor: AppColors.red500,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CURRENT LOGGED-IN SHOP ID
    // ----------------------------------------------------------

    final shopId = user.uid;

    debugPrint('========================================');
    debugPrint('CHECKOUT');
    debugPrint('Current Firebase UID: $shopId');
    debugPrint('========================================');

    // ----------------------------------------------------------
    // DISTRIBUTOR ID
    // ----------------------------------------------------------

    final distributorId = widget.distributorId.isNotEmpty
        ? widget.distributorId
        : (auth.distributorId ?? auth.shopProfile?.distributorId ?? '');

    if (distributorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account error: Distributor ID not found.'),
          backgroundColor: AppColors.red500,
        ),
      );

      return;
    }

    debugPrint('Distributor ID: $distributorId');

    // ----------------------------------------------------------
    // VALIDATE DISTRIBUTOR ORDERING RULES (TIMING & PENDING PAYMENT)
    // ----------------------------------------------------------
    final settings = await DistributorSettingsService.fetchSettings(distributorId);
    final shopProfile = auth.shopProfile;
    final eligibility = DistributorSettingsService.checkEligibility(
      shopProfile: shopProfile,
      settings: settings,
    );

    if (!eligibility.canOrder) {
      if (!mounted) return;

      if (eligibility.isPaymentBlocked) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.red600),
                const SizedBox(width: 10),
                Text(locale.t('pending_payment_blocked_title')),
              ],
            ),
            content: Text(eligibility.statusMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(locale.t('close')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopPaymentScreen(
                        amountDue: eligibility.pendingAmount,
                        distributorId: distributorId,
                      ),
                    ),
                  );
                },
                child: Text(locale.t('pay_bills_now')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(eligibility.statusMessage),
            backgroundColor: AppColors.amber700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // --------------------------------------------------------
      // SHOP INFORMATION
      // --------------------------------------------------------

      final shopProfile = auth.shopProfile;

      final shopName = shopProfile?.shopName.isNotEmpty == true
          ? shopProfile!.shopName
          : 'My Dairy Shop';

      final shopOwner = shopProfile?.ownerName ?? '';

      final shopMobile = shopProfile?.mobile ?? '';

      // --------------------------------------------------------
      // ORDER ITEMS
      // --------------------------------------------------------

      final orderItems = widget.cartItems.map((t) {
        return OrderItem(
          productId: t.$1.id,
          productName: t.$1.name,
          category: t.$1.category,
          packSize: t.$1.packSize,
          unit: t.$1.unit,
          price: t.$1.price,
          quantity: t.$2,
          emoji: t.$1.emoji,
          subtotal: t.$1.price * t.$2,
        );
      }).toList();

      // --------------------------------------------------------
      // CALCULATIONS
      // --------------------------------------------------------

      const deliveryCharge = 0.0;
      const discount = 0.0;

      final subtotal = widget.cartItems.fold<double>(0.0, (acc, item) {
        return acc + (item.$1.price * item.$2);
      });

      final totalAmount = widget.total;

      final totalQty = widget.cartItems.fold<int>(0, (acc, item) {
        return acc + item.$2;
      });

      // --------------------------------------------------------
      // UPI
      // --------------------------------------------------------

      if (_paymentMethod == 'upi') {
        await _startRazorpayPayment(
          distributorId: distributorId,
          shopId: shopId,
          shopName: shopName,
          shopOwner: shopOwner,
          shopMobile: shopMobile,
          orderItems: orderItems,
          subtotal: subtotal,
          deliveryCharge: deliveryCharge,
          discount: discount,
          totalAmount: totalAmount,
          totalQuantity: totalQty,
          address: address,
        );

        return;
      }

      // --------------------------------------------------------
      // COD / BANK / CREDIT
      // --------------------------------------------------------

      final orderNumber = await _saveOrderToFirestore(
        distributorId: distributorId,
        shopId: shopId,
        shopName: shopName,
        shopOwner: shopOwner,
        shopMobile: shopMobile,
        items: orderItems,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
        discount: discount,
        totalAmount: totalAmount,
        deliveryAddress: address,
        deliveryDate: _deliveryDate,
        deliveryTime: _deliveryTime,
        paymentMethod: _paymentMethod,
        paymentStatus: 'Pending',
        status: 'pending',
      );

      debugPrint('ORDER CREATED SUCCESSFULLY: $orderNumber');

      // --------------------------------------------------------
      // CLEAR CART
      // --------------------------------------------------------

      widget.onOrderPlaced?.call();

      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS SCREEN
      // --------------------------------------------------------

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderNumber,
            total: widget.total,
            deliveryDate:
                '${locale.translateDate(_deliveryDate)}, '
                '${locale.translateDate(_deliveryTime)}',
            itemCount: totalQty,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('PLACE ORDER ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.red500,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // ============================================================
  // START RAZORPAY
  // ============================================================

  Future<void> _startRazorpayPayment({
    required String distributorId,
    required String shopId,
    required String shopName,
    required String shopOwner,
    required String shopMobile,
    required List<OrderItem> orderItems,
    required double subtotal,
    required double deliveryCharge,
    required double discount,
    required double totalAmount,
    required int totalQuantity,
    required String address,
  }) async {
    try {
      debugPrint('========================================');
      debugPrint('STARTING RAZORPAY');
      debugPrint('Distributor: $distributorId');
      debugPrint('Shop UID: $shopId');
      debugPrint('Amount: ₹$totalAmount');
      debugPrint('========================================');

      // --------------------------------------------------------
      // AMOUNT IN PAISE
      // --------------------------------------------------------

      final amountInPaise = (totalAmount * 100).round();

      if (amountInPaise <= 0) {
        throw Exception('Invalid payment amount.');
      }

      // --------------------------------------------------------
      // SAVE PENDING INFORMATION
      // --------------------------------------------------------

      _pendingDistributorId = distributorId;
      _pendingShopId = shopId;

      _pendingShopName = shopName;
      _pendingShopOwner = shopOwner;
      _pendingShopMobile = shopMobile;
      _pendingAddress = address;

      _pendingOrderItems = orderItems;

      _pendingSubtotal = subtotal;
      _pendingDeliveryCharge = deliveryCharge;
      _pendingDiscount = discount;
      _pendingTotalAmount = totalAmount;
      _pendingTotalQuantity = totalQuantity;

      // --------------------------------------------------------
      // FIREBASE CLOUD FUNCTION
      // --------------------------------------------------------

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final callable = functions.httpsCallable('createRazorpayOrder');

      final result = await callable.call({'amount': amountInPaise});

      final data = Map<String, dynamic>.from(result.data as Map);

      final success = data['success'] == true;

      if (!success) {
        throw Exception('Unable to create Razorpay order.');
      }

      final razorpayOrderId = data['orderId']?.toString();

      final razorpayKeyId = data['keyId']?.toString();

      final returnedAmount = data['amount'];

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        throw Exception('Razorpay Order ID was not returned.');
      }

      if (razorpayKeyId == null || razorpayKeyId.isEmpty) {
        throw Exception('Razorpay Key ID was not returned.');
      }

      if (returnedAmount == null) {
        throw Exception('Razorpay amount was not returned.');
      }

      debugPrint('Razorpay Order ID: $razorpayOrderId');

      debugPrint('Razorpay Amount: $returnedAmount paise');

      // --------------------------------------------------------
      // RAZORPAY OPTIONS
      // --------------------------------------------------------

      final options = {
        'key': razorpayKeyId,
        'amount': returnedAmount,
        'currency': 'INR',
        'name': 'Bhargavi Milk',
        'description': 'Milk Order Payment',
        'order_id': razorpayOrderId,
        'timeout': 300,

        'prefill': {
          'contact': shopMobile,
          'name': shopOwner.isNotEmpty ? shopOwner : shopName,
        },

        'theme': {'color': '#2196F3'},
      };

      debugPrint('Opening Razorpay Checkout...');

      _razorpay.open(options);
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('RAZORPAY START ERROR');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      _clearPendingPayment();

      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to start payment: $e'),
            backgroundColor: AppColors.red500,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // ============================================================
  // RAZORPAY SUCCESS
  // ============================================================

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('========================================');
    debugPrint('RAZORPAY PAYMENT SUCCESS');
    debugPrint('Payment ID: ${response.paymentId}');
    debugPrint('Razorpay Order ID: ${response.orderId}');
    debugPrint('Signature: ${response.signature}');
    debugPrint('========================================');

    if (!mounted) return;

    try {
      setState(() {
        _isPlacingOrder = true;
      });

      // --------------------------------------------------------
      // CHECK PENDING DATA
      // --------------------------------------------------------

      if (_pendingDistributorId == null ||
          _pendingShopId == null ||
          _pendingOrderItems == null ||
          _pendingSubtotal == null ||
          _pendingDeliveryCharge == null ||
          _pendingDiscount == null ||
          _pendingTotalAmount == null ||
          _pendingAddress == null) {
        throw Exception('Payment succeeded but order information was lost.');
      }

      // --------------------------------------------------------
      // CURRENT LOGGED-IN USER
      // --------------------------------------------------------

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User is no longer authenticated.');
      }

      final currentShopId = user.uid;

      debugPrint('Current Firebase UID: $currentShopId');

      debugPrint('Pending Shop UID: $_pendingShopId');

      // --------------------------------------------------------
      // SECURITY CHECK
      // --------------------------------------------------------

      if (currentShopId != _pendingShopId) {
        throw Exception('Logged-in account changed during payment.');
      }

      // --------------------------------------------------------
      // SAVE PAID ORDER
      // --------------------------------------------------------

      final orderNumber = await _saveOrderToFirestore(
        distributorId: _pendingDistributorId!,
        shopId: currentShopId,

        shopName: _pendingShopName ?? 'My Dairy Shop',

        shopOwner: _pendingShopOwner ?? '',

        shopMobile: _pendingShopMobile ?? '',

        items: _pendingOrderItems!,

        subtotal: _pendingSubtotal!,

        deliveryCharge: _pendingDeliveryCharge!,

        discount: _pendingDiscount!,

        totalAmount: _pendingTotalAmount!,

        deliveryAddress: _pendingAddress!,

        deliveryDate: _deliveryDate,

        deliveryTime: _deliveryTime,

        paymentMethod: 'upi',

        paymentStatus: 'Paid',

        status: 'pending',

        razorpayPaymentId: response.paymentId,

        razorpayOrderId: response.orderId,

        razorpaySignature: response.signature,
      );

      debugPrint('========================================');
      debugPrint('PAID ORDER SAVED');
      debugPrint('Order ID: $orderNumber');
      debugPrint('========================================');

      // --------------------------------------------------------
      // CLEAR CART
      // --------------------------------------------------------

      widget.onOrderPlaced?.call();

      final totalQty = _pendingTotalQuantity ?? 0;

      _clearPendingPayment();

      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS SCREEN
      // --------------------------------------------------------

      final locale = LocaleScope.of(context);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderNumber,
            total: widget.total,
            deliveryDate:
                '${locale.translateDate(_deliveryDate)}, '
                '${locale.translateDate(_deliveryTime)}',
            itemCount: totalQty,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('ERROR SAVING PAID ORDER');
      debugPrint('$e');
      debugPrint('$stackTrace');
      debugPrint('========================================');

      _clearPendingPayment();

      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment was successful, but order saving failed: $e',
            ),
            backgroundColor: AppColors.red500,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  // ============================================================
  // SAVE ORDER TO FIRESTORE
  // ============================================================

  Future<String> _saveOrderToFirestore({
    required String distributorId,
    required String shopId,
    required String shopName,
    required String shopOwner,
    required String shopMobile,
    required List<OrderItem> items,
    required double subtotal,
    required double deliveryCharge,
    required double discount,
    required double totalAmount,
    required String deliveryAddress,
    required String deliveryDate,
    required String deliveryTime,
    required String paymentMethod,
    required String paymentStatus,
    required String status,

    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    // ----------------------------------------------------------
    // CHECK AUTHENTICATION
    // ----------------------------------------------------------

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    // ----------------------------------------------------------
    // ALWAYS USE CURRENT USER UID
    // ----------------------------------------------------------

    final currentUid = user.uid;

    if (currentUid != shopId) {
      throw Exception('Shop ID does not match current logged-in user.');
    }

    debugPrint('========================================');
    debugPrint('SAVING FIRESTORE ORDER');
    debugPrint('Current UID: $currentUid');
    debugPrint('Distributor ID: $distributorId');
    debugPrint('Shop ID: $shopId');
    debugPrint('Status: $status');
    debugPrint('Payment Status: $paymentStatus');
    debugPrint('Payment Method: $paymentMethod');
    debugPrint('Total Amount: $totalAmount');
    debugPrint('========================================');

    // ----------------------------------------------------------
    // FIRESTORE ORDER REFERENCE
    // ----------------------------------------------------------

    final orderRef = FirebaseFirestore.instance
        .collection('distributor')
        .doc(distributorId)
        .collection('orders')
        .doc();

    // ----------------------------------------------------------
    // ITEMS
    // ----------------------------------------------------------

    final itemsData = items.map((item) {
      return {
        'productId': item.productId,

        'productName': item.productName,

        'category': item.category,

        'packSize': item.packSize,

        'unit': item.unit,

        'price': item.price,

        'quantity': item.quantity,

        'emoji': item.emoji,

        'subtotal': item.subtotal,
      };
    }).toList();

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final orderNumber =
        '#ORD-${suffix.length > 5 ? suffix.substring(suffix.length - 5) : suffix}';

    final List<String> productsList = items
        .map((i) => '${i.productName} × ${i.quantity}')
        .toList();

    final orderData = <String, dynamic>{
      // Order identifiers
      'id': orderRef.id,
      'orderId': orderRef.id,
      'orderNumber': orderNumber,

      'distributorId': distributorId,

      // IMPORTANT:
      // CURRENT LOGGED-IN USER
      'shopId': currentUid,

      // Shop information
      'shopName': shopName,
      'shopOwner': shopOwner,
      'shopMobile': shopMobile,

      // Items
      'items': itemsData,
      'products': productsList,

      // Amounts
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'totalAmount': totalAmount,
      'total': totalAmount,

      'totalQuantity': items.fold<int>(0, (acc, item) => acc + item.quantity),

      // Delivery
      'deliveryAddress': deliveryAddress,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,

      // Payment
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,

      // Order status
      'status': status,
      'orderStatus': status,

      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ----------------------------------------------------------
    // RAZORPAY DATA
    // ----------------------------------------------------------

    if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) {
      orderData['razorpayPaymentId'] = razorpayPaymentId;
    }

    if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
      orderData['razorpayOrderId'] = razorpayOrderId;
    }

    if (razorpaySignature != null && razorpaySignature.isNotEmpty) {
      orderData['razorpaySignature'] = razorpaySignature;
    }

    // ----------------------------------------------------------
    // WRITE TO FIRESTORE
    // ----------------------------------------------------------

    debugPrint('Firestore path: ${orderRef.path}');
    debugPrint('Writing order...');

    await orderRef.set(orderData);

    // ----------------------------------------------------------
    // SUCCESS
    // ----------------------------------------------------------

    debugPrint('========================================');
    debugPrint('FIRESTORE WRITE SUCCESS');
    debugPrint('Path: ${orderRef.path}');
    debugPrint('Order Number: $orderNumber');
    debugPrint('Shop UID: $currentUid');
    debugPrint('========================================');

    return orderNumber;
  }

  // ============================================================
  // RAZORPAY PAYMENT ERROR
  // ============================================================

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('========================================');
    debugPrint('RAZORPAY PAYMENT FAILED');
    debugPrint('Code: ${response.code}');
    debugPrint('Message: ${response.message}');
    debugPrint('========================================');

    _clearPendingPayment();

    if (mounted) {
      setState(() {
        _isPlacingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: '
            '${response.message ?? 'Please try again.'}',
          ),
          backgroundColor: AppColors.red500,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ============================================================
  // EXTERNAL WALLET
  // ============================================================

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint(
      'External wallet selected: '
      '${response.walletName}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'External wallet: '
            '${response.walletName ?? 'Selected'}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CLEAR PENDING PAYMENT
  // ============================================================

  void _clearPendingPayment() {
    _pendingDistributorId = null;
    _pendingShopId = null;

    _pendingShopName = null;
    _pendingShopOwner = null;
    _pendingShopMobile = null;
    _pendingAddress = null;

    _pendingOrderItems = null;

    _pendingSubtotal = null;
    _pendingDeliveryCharge = null;
    _pendingDiscount = null;
    _pendingTotalAmount = null;
    _pendingTotalQuantity = null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    final auth = AuthStateScope.of(context);

    // ----------------------------------------------------------
    // ADDRESS
    // ----------------------------------------------------------

    if (!_addressInitialized && auth.shopProfile?.address.isNotEmpty == true) {
      _addressCtrl.text = auth.shopProfile!.address;

      _addressInitialized = true;
    }

    // ----------------------------------------------------------
    // SUBTOTAL
    // ----------------------------------------------------------

    final double subtotal = widget.cartItems.fold<double>(0.0, (acc, item) {
      return acc + (item.$1.price * item.$2);
    });

    // ----------------------------------------------------------
    // UI
    // ----------------------------------------------------------

    return Scaffold(
      backgroundColor: AppColors.background,

      body: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          GradientHeader(
            title: locale.t('checkout'),

            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _isPlacingOrder ? null : () => Navigator.pop(context),
            ),

            showLanguagePicker: false,
          ),

          // ======================================================
          // BODY
          // ======================================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // ORDER SUMMARY
                  // ==================================================
                  _sectionCard(
                    title: 'Order Summary',

                    child: Column(
                      children: [
                        ...widget.cartItems.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),

                            child: Row(
                              children: [
                                Text(
                                  t.$1.emoji.isNotEmpty ? t.$1.emoji : '🥛',

                                  style: const TextStyle(fontSize: 20),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        locale.translateProduct(t.$1.name),

                                        style: AppTextStyles.body,
                                      ),

                                      Text(
                                        '${t.$1.packSize} • '
                                        '${locale.translateUnit(t.$1.unit)}',

                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.ink500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text('×${t.$2}', style: AppTextStyles.caption),

                                const SizedBox(width: 10),

                                Text(
                                  '₹${(t.$1.price * t.$2).toStringAsFixed(0)}',

                                  style: AppTextStyles.bodyBold,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 16),

                        _row(
                          locale.t('subtotal'),
                          '₹${subtotal.toStringAsFixed(subtotal % 1 == 0 ? 0 : 2)}',
                        ),

                        const Divider(height: 10),

                        _row(
                          locale.t('grand_total'),
                          '₹${widget.total.toStringAsFixed(widget.total % 1 == 0 ? 0 : 2)}',
                          bold: true,
                          color: AppColors.milkBlue700,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // DELIVERY ADDRESS
                  // ==================================================
                  _sectionCard(
                    title: locale.t('delivery_address'),

                    child: TextField(
                      controller: _addressCtrl,

                      maxLines: 2,

                      enabled: !_isPlacingOrder,

                      decoration: InputDecoration(
                        hintText: locale.t('address'),

                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.ink500,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // DELIVERY DATE / TIME
                  // ==================================================
                  _sectionCard(
                    title: locale.t('delivery_date'),

                    child: Column(
                      children: [
                        _selectRow(
                          Icons.calendar_today_outlined,

                          locale.t('delivery_date'),

                          locale.translateDate(_deliveryDate),

                          () async {
                            if (_isPlacingOrder) {
                              return;
                            }

                            final picked = await showDatePicker(
                              context: context,

                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),

                              firstDate: DateTime.now(),

                              lastDate: DateTime.now().add(
                                const Duration(days: 14),
                              ),
                            );

                            if (picked != null) {
                              setState(() {
                                _deliveryDate =
                                    '${picked.day}/'
                                    '${picked.month}/'
                                    '${picked.year}';
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        _selectRow(
                          Icons.access_time_outlined,

                          locale.t('delivery_time'),

                          locale.translateDate(_deliveryTime),

                          () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // PAYMENT METHOD
                  // ==================================================
                  _sectionCard(
                    title: locale.t('payment_method'),

                    child: Column(
                      children: _methods.map((m) {
                        final selected = _paymentMethod == m.$1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),

                          child: GestureDetector(
                            onTap: _isPlacingOrder
                                ? null
                                : () {
                                    setState(() {
                                      _paymentMethod = m.$1;
                                    });
                                  },

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
                                  Container(
                                    padding: const EdgeInsets.all(7),

                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.milkBlue100
                                          : AppColors.border.withValues(
                                              alpha: 0.5,
                                            ),

                                      borderRadius: BorderRadius.circular(8),
                                    ),

                                    child: Icon(
                                      m.$2,

                                      color: selected
                                          ? AppColors.milkBlue700
                                          : AppColors.ink500,

                                      size: 18,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      locale.t(m.$3),

                                      style: AppTextStyles.body.copyWith(
                                        color: selected
                                            ? AppColors.milkBlue700
                                            : AppColors.ink700,
                                      ),
                                    ),
                                  ),

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
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ELIGIBILITY CHECK & PLACE ORDER BUTTON
                  // ==================================================
                  StreamBuilder<DistributorOrderSettings>(
                    stream: DistributorSettingsService.streamSettings(
                      widget.distributorId.isNotEmpty
                          ? widget.distributorId
                          : (auth.distributorId ?? auth.shopProfile?.distributorId ?? ''),
                    ),
                    builder: (context, settingsSnap) {
                      final settings = settingsSnap.data ?? const DistributorOrderSettings();
                      final eligibility = DistributorSettingsService.checkEligibility(
                        shopProfile: auth.shopProfile,
                        settings: settings,
                      );

                      if (eligibility.isTimeBlocked) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.amber50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.amber300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_clock_rounded, color: AppColors.amber800, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      eligibility.statusMessage,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.amber900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ink300,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: null,
                                child: Text(
                                  '${locale.t("ordering_closed")} (${settings.startTimeFormatted}–${settings.endTimeFormatted})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      if (eligibility.isPaymentBlocked) {
                        final formattedPending = eligibility.pendingAmount.toStringAsFixed(
                          eligibility.pendingAmount % 1 == 0 ? 0 : 2,
                        );

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.red50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.red300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.red600, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Previous payment is pending (₹$formattedPending). Clear bills to order.',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.red800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red600,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.payment_rounded, size: 20),
                                label: Text(
                                  '${locale.t("pay_bills_now")} (₹$formattedPending)',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ShopPaymentScreen(
                                        amountDue: eligibility.pendingAmount,
                                        distributorId: widget.distributorId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isPlacingOrder
                              ? null
                              : () => _handlePlaceOrder(locale, auth),
                          child: _isPlacingOrder
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _paymentMethod == 'upi'
                                      ? 'Pay ₹${widget.total.toStringAsFixed(0)}'
                                      : locale.t('place_order'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.cardSurface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(title, style: AppTextStyles.bodyBold),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // ROW
  // ============================================================

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = bold ? AppTextStyles.bodyBold : AppTextStyles.body;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),

      child: Row(
        children: [
          Text(label, style: style),

          const Spacer(),

          Text(value, style: style.copyWith(color: color)),
        ],
      ),
    );
  }

  // ============================================================
  // SELECT ROW
  // ============================================================

  Widget _selectRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(
          color: AppColors.background,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(color: AppColors.border),
        ),

        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.milkBlue600),

            const SizedBox(width: 10),

            Text(label, style: AppTextStyles.caption),

            const Spacer(),

            Text(value, style: AppTextStyles.captionBold),

            const SizedBox(width: 4),

            const Icon(Icons.chevron_right, size: 16, color: AppColors.ink300),
          ],
        ),
      ),
    );
  }
}
