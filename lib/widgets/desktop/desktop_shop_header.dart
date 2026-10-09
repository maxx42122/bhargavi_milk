import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/shop_service.dart';
import '../../state/locale_state.dart';
import '../language_picker.dart';
import '../bvh_logo_widget.dart';
import '../../screens/auth/login_screen.dart';

class DesktopShopHeader extends StatelessWidget {
  final int selectedNavIndex;
  final ValueChanged<int> onSelectNav;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final List<String> categories;
  final int cartCount;
  final double cartTotal;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? cutoffText;
  final ShopProfile? shopProfile;
  final VoidCallback? onOpenCart;

  const DesktopShopHeader({
    super.key,
    required this.selectedNavIndex,
    required this.onSelectNav,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.categories,
    required this.cartCount,
    required this.cartTotal,
    required this.searchQuery,
    required this.onSearchChanged,
    this.cutoffText,
    this.shopProfile,
    this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final shopName = shopProfile?.shopName ?? 'Milk Partner';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Bar ───────────────────────────────────────────────────────
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Brand Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.milkBlue50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const BvhLogoWidget(
                        size: 32,
                        showCard: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              locale.t('app_name'),
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkNavy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SHOP',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          shopName,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.ink600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(width: 32),

                // Search Box
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: onSearchChanged,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search fresh milk, paneer, curd, butter...',
                        hintStyle: AppTextStyles.caption.copyWith(
                          color: AppColors.ink400,
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.ink500,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Cutoff Alert Pill if available
                if (cutoffText != null && cutoffText!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.amber300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 15,
                          color: AppColors.amber700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cutoffText!,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.amber800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: 16),

                // Language Picker
                const LanguagePillButton(),

                const SizedBox(width: 16),

                // Cart CTA Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onOpenCart ?? () => onSelectNav(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.gradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              if (cartCount > 0)
                                Positioned(
                                  right: -6,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.red500,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$cartCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locale.t('nav_cart'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${cartTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // User / Logout Popup
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'profile') {
                      onSelectNav(4);
                    } else if (val == 'orders') {
                      onSelectNav(3);
                    } else if (val == 'logout') {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(locale.t('nav_profile')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'orders',
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(locale.t('nav_history')),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 18,
                            color: AppColors.red600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            locale.t('logout'),
                            style: const TextStyle(color: AppColors.red600),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.ink50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.ink700,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category Navigation Ribbon ────────────────────────────────────
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.storefront_rounded,
                  label: locale.t('nav_home'),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.inventory_2_rounded,
                  label: locale.t('nav_products'),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.receipt_long_rounded,
                  label: locale.t('nav_history'),
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: locale.t('nav_profile'),
                ),

                const VerticalDivider(
                  indent: 10,
                  endIndent: 10,
                  width: 32,
                  color: AppColors.border,
                ),

                // Category Chips
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final cat = categories[idx];
                      final isSelected = selectedCategory == cat;

                      return Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onSelectCategory(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.ink50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                locale.translateCategory(cat),
                                style: AppTextStyles.captionBold.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectNav(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.primaryBlue : AppColors.ink500,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isSelected ? AppColors.primaryBlue : AppColors.ink700,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
