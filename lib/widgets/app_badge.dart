import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';

enum BadgeVariant { success, warning, error, info, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final bool showDot;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _variantColors(variant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(color: colors.$2),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _variantColors(BadgeVariant v) {
    return switch (v) {
      BadgeVariant.success => (
        AppColors.dairyGreen100,
        AppColors.dairyGreen700,
      ),
      BadgeVariant.warning => (AppColors.amber100, AppColors.amber600),
      BadgeVariant.error => (AppColors.red100, AppColors.red600),
      BadgeVariant.info => (AppColors.milkBlue100, AppColors.milkBlue700),
      BadgeVariant.neutral => (const Color(0xFFF0F2F5), AppColors.ink700),
    };
  }
}

/// Maps common status strings to badge variants.
BadgeVariant orderStatusVariant(String status) {
  return switch (status.toLowerCase()) {
    'delivered' || 'completed' => BadgeVariant.success,
    'confirmed' || 'prepared' || 'packed' => BadgeVariant.info,
    'pending' || 'out for delivery' => BadgeVariant.warning,
    'cancelled' || 'rejected' => BadgeVariant.error,
    _ => BadgeVariant.neutral, // new or other
  };
}

BadgeVariant paymentStatusVariant(String status) {
  return switch (status.toLowerCase()) {
    'paid' => BadgeVariant.success,
    'partially paid' => BadgeVariant.warning,
    'pending' => BadgeVariant.error,
    _ => BadgeVariant.neutral,
  };
}
