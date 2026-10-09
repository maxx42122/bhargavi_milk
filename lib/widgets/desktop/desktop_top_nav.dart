import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../language_picker.dart';

class DesktopTopNav extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final ValueChanged<String>? onSearch;
  final String? searchHint;
  final bool showLiveBadge;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final Widget? trailingCustom;

  const DesktopTopNav({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onSearch,
    this.searchHint,
    this.showLiveBadge = true,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.trailingCustom,
  });

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],

          // Title & Subtitle / Live Badge
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: AppTextStyles.desktopH2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink900,
                      fontSize: 20,
                    ),
                  ),
                  if (showLiveBadge) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dairyGreen50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dairyGreen500.withValues(alpha: 0.4),
                          width: 1,
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
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Search Box if provided
          if (onSearch != null) ...[
            Container(
              width: 260,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: onSearch,
                style: AppTextStyles.body.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search anything...',
                  hintStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.ink400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.ink500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          // Date Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.ink50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.ink600,
                ),
                const SizedBox(width: 6),
                Text(
                  nowStr,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.ink700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Notification Bell
          if (onNotificationTap != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onNotificationTap,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.ink700,
                    size: 22,
                  ),
                  tooltip: 'Notifications',
                ),
                if (unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.red600,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(width: 8),

          // Language Selector Pill
          const LanguagePillButton(),

          if (actions != null) ...[
            const SizedBox(width: 12),
            ...actions!,
          ],

          if (trailingCustom != null) ...[
            const SizedBox(width: 16),
            trailingCustom!,
          ],
        ],
      ),
    );
  }
}
