import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import 'desktop_hover_card.dart';

class DesktopKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? deltaText;
  final bool deltaPositive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DesktopKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor = AppColors.primaryBlue,
    this.iconBg = AppColors.milkBlue50,
    this.deltaText,
    this.deltaPositive = true,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopHoverCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.ink600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (deltaText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: deltaPositive
                        ? AppColors.dairyGreen50
                        : AppColors.red50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: deltaPositive
                          ? AppColors.dairyGreen300
                          : AppColors.red300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        deltaPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: deltaPositive
                            ? AppColors.dairyGreen700
                            : AppColors.red600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deltaText!,
                        style: AppTextStyles.overline.copyWith(
                          color: deltaPositive
                              ? AppColors.dairyGreen700
                              : AppColors.red600,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink900,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
