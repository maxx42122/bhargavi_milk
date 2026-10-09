import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/locale_state.dart';
import '../bvh_logo_widget.dart';
import '../../screens/distributor/distributor_profile_screen.dart';
import '../../screens/distributor/distributor_settings_screen.dart';
import '../../screens/distributor/invoice_screen.dart';
import '../../screens/distributor/reports_screen.dart';
import '../../screens/distributor/statement_screen.dart';
import '../../screens/distributor/total_orders_summary_screen.dart';
import '../../screens/auth/login_screen.dart';

class DesktopDistributorSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final LocaleState locale;
  final int pendingOrdersCount;

  const DesktopDistributorSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.locale,
    this.pendingOrdersCount = 0,
  });

  String _getInitials() {
    final name = AuthService.currentUser?.displayName ?? '';
    if (name.isEmpty) return 'D';
    return name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: AppColors.milkBlue900,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003087), Color(0xFF0047FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white12,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const BvhLogoWidget(
                    size: 34,
                    showCard: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            locale.t('app_name'),
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF00E5FF),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Color(0xFFE2F9FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Distributor Portal',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFB7E2FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              children: [
                _buildSectionHeader('CORE OPERATIONS'),
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: locale.t('nav_dashboard'),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  label: locale.t('nav_orders'),
                  badgeCount: pendingOrdersCount,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.inventory_2_rounded,
                  label: locale.t('nav_products'),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.store_rounded,
                  label: locale.t('nav_customers'),
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.payments_rounded,
                  label: locale.t('nav_payments'),
                ),

                const SizedBox(height: 18),
                _buildSectionHeader('MANAGEMENT & INSIGHTS'),
                _buildActionItem(
                  icon: Icons.table_chart_rounded,
                  label: 'Orders Matrix',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TotalOrdersSummaryScreen(),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.description_rounded,
                  label: locale.t('nav_bills'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const InvoiceScreen(),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: locale.t('nav_statements'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatementScreen(shopName: 'All Shops'),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.bar_chart_rounded,
                  label: locale.t('nav_reports'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportsScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                _buildSectionHeader('SYSTEM & PREFERENCES'),
                _buildActionItem(
                  icon: Icons.tune_rounded,
                  label: locale.t('nav_settings'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DistributorSettingsScreen(),
                    ),
                  ),
                ),
                _buildActionItem(
                  icon: Icons.person_rounded,
                  label: locale.t('nav_profile'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DistributorProfileScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Profile & Logout Card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1336),
              border: Border(
                top: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.milkBlue600,
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AuthService.currentUser?.displayName ?? 'Distributor',
                        style: AppTextStyles.captionBold.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AuthService.currentUser?.email ?? 'Active Account',
                        style: AppTextStyles.overline.copyWith(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white60,
                    size: 19,
                  ),
                  tooltip: locale.t('logout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF6B7A99),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final active = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.milkBlue600 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.milkBlue600.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF9EABCC),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: active ? Colors.white : const Color(0xFFC7D3E8),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : AppColors.amber500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: active ? AppColors.milkBlue900 : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF9EABCC),
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: const Color(0xFFB5C3DE),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white24,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
