import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/gradient_header.dart';
import 'order_success_screen.dart';

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
  String _paymentMethod = 'upi';
  late final TextEditingController _addressCtrl;
  String _deliveryDate = 'Tomorrow Morning';
  final String _deliveryTime = 'Morning (6–9 AM)';
  bool _addressInitialized = false;
  bool _isPlacingOrder = false;

  static const _methods = [
    ('upi', Icons.qr_code_2, 'pay_upi'),
    ('cod', Icons.money, 'pay_cod'),
    ('bank', Icons.account_balance_outlined, 'pay_bank'),
    ('credit', Icons.credit_card_outlined, 'pay_credit'),
  ];

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController();
  }

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

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder(BuildContext context, LocaleState locale, AuthState auth) async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.t('delivery_address')),
          backgroundColor: AppColors.red500,
        ),
      );
      return;
    }

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

    setState(() => _isPlacingOrder = true);

    try {
      final shopProfile = auth.shopProfile;
      final shopName = shopProfile?.shopName.isNotEmpty == true
          ? shopProfile!.shopName
          : 'My Dairy Shop';
      final shopOwner = shopProfile?.ownerName ?? '';
      final shopMobile = shopProfile?.mobile ?? '';

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

      const deliveryCharge = 20.0;
      const discount = 0.0;
      final subtotal = (widget.total - deliveryCharge + discount).clamp(0.0, double.infinity);

      final totalQty = widget.cartItems.fold(0, (sum, t) => sum + t.$2);

      final orderNumber = await OrderService.placeOrder(
        distributorId: distributorId,
        shopName: shopName,
        shopOwner: shopOwner,
        shopMobile: shopMobile,
        items: orderItems,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
        discount: discount,
        totalAmount: widget.total,
        deliveryAddress: address,
        deliveryDate: _deliveryDate,
        deliveryTime: _deliveryTime,
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentMethod == 'upi' ? 'Paid' : 'Pending',
        status: 'pending',
      );

      // Clear the shop cart
      widget.onOrderPlaced?.call();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: orderNumber,
            total: widget.total,
            deliveryDate: '$_deliveryDate, $_deliveryTime',
            itemCount: totalQty,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.red500,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final auth = AuthStateScope.of(context);

    // If not initialized yet, try to load current shop profile address
    if (!_addressInitialized && auth.shopProfile?.address.isNotEmpty == true) {
      _addressCtrl.text = auth.shopProfile!.address;
      _addressInitialized = true;
    }

    final double subtotal = (widget.total - 20).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('checkout'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            showLanguagePicker: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary
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
                                      Text(t.$1.name, style: AppTextStyles.body),
                                      Text(
                                        '${t.$1.packSize} • ${t.$1.unit}',
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
                          '₹${subtotal.toStringAsFixed(0)}',
                        ),
                        _row(locale.t('delivery_charge'), '₹20'),
                        _row(locale.t('discount'), '₹0'),
                        const Divider(height: 10),
                        _row(
                          locale.t('grand_total'),
                          '₹${widget.total.toStringAsFixed(0)}',
                          bold: true,
                          color: AppColors.milkBlue700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Delivery address
                  _sectionCard(
                    title: locale.t('delivery_address'),
                    child: TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
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

                  // Date/time
                  _sectionCard(
                    title: locale.t('delivery_date'),
                    child: Column(
                      children: [
                        _selectRow(
                          Icons.calendar_today_outlined,
                          locale.t('delivery_date'),
                          _deliveryDate,
                          () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 14)),
                            );
                            if (picked != null) {
                              setState(() {
                                _deliveryDate =
                                    '${picked.day}/${picked.month}/${picked.year}';
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _selectRow(
                          Icons.access_time_outlined,
                          locale.t('delivery_time'),
                          _deliveryTime,
                          () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment method
                  _sectionCard(
                    title: locale.t('payment_method'),
                    child: Column(
                      children: _methods.map((m) {
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

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder
                          ? null
                          : () => _handlePlaceOrder(context, locale, auth),
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
                              locale.t('place_order'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
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

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
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
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.ink300,
            ),
          ],
        ),
      ),
    );
  }
}
