import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../state/locale_state.dart';
import 'shop_home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double total;
  final String deliveryDate;
  final int itemCount;

  const OrderSuccessScreen({
    super.key,
    this.orderId = '#ORD-1043',
    this.total = 0.0,
    this.deliveryDate = 'Tomorrow Morning',
    this.itemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success checkmark
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.dairyGreen500, AppColors.dairyGreen700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dairyGreen500.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                locale.t('order_placed'),
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.dairyGreen700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                locale.t('order_placed_msg'),
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Order summary chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dairyGreen100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dairyGreen300),
                ),
                child: Column(
                  children: [
                    _row('Order ID', orderId),
                    if (itemCount > 0) ...[
                      const SizedBox(height: 8),
                      _row('Items', '$itemCount items'),
                    ],
                    const SizedBox(height: 8),
                    _row(
                      'Total Amount',
                      '₹${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}',
                      valueStyle: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.dairyGreen700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Expected Delivery', deliveryDate),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const ShopHomeScreen()),
                    (route) => false,
                  ),
                  child: Text(locale.t('continue_shopping')),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Navigate back to home screen on the History tab (index 3)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const ShopHomeScreen(initialTabIndex: 3),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  locale.t('view_receipt'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.caption),
        const Spacer(),
        Text(
          value,
          style:
              valueStyle ??
              AppTextStyles.captionBold.copyWith(color: AppColors.ink900),
        ),
      ],
    );
  }
}
