import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/shop_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/gradient_header.dart';
import '../auth/login_screen.dart';
import 'shop_payment_screen.dart';

class ShopProfileScreen extends StatefulWidget {
  final String distributorId;
  final String shopUid;

  const ShopProfileScreen({
    super.key,
    required this.distributorId,
    required this.shopUid,
  });

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  Map<String, String>? _distributorInfo;
  bool _loadingDistributor = true;

  @override
  void initState() {
    super.initState();
    _loadDistributor();
  }

  Future<void> _loadDistributor() async {
    if (widget.distributorId.isEmpty) return;
    final info = await ShopService.fetchDistributorInfo(widget.distributorId);
    if (mounted) {
      setState(() {
        _distributorInfo = info;
        _loadingDistributor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<ShopProfile?>(
        stream: ShopService.streamShopProfile(
          distributorId: widget.distributorId,
          shopUid: widget.shopUid,
        ),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              profile == null;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final shopName = profile?.shopName.isNotEmpty == true
              ? profile!.shopName
              : 'My Dairy Shop';
          final ownerName = profile?.ownerName ?? 'Shop Owner';

          return Column(
            children: [
              GradientHeader(
                title: locale.t('nav_profile'),
                subtitle: shopName,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: locale.t('logout'),
                    onPressed: () => _confirmLogout(context, locale),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<OrderModel>>(
                  stream: OrderService.streamShopOrders(
                    distributorId: widget.distributorId,
                    shopUid: widget.shopUid,
                  ),
                  builder: (context, ordersSnapshot) {
                    final orders = ordersSnapshot.data ?? [];

                    final computedOrdersCount =
                        orders.isNotEmpty ? orders.length : (profile?.totalOrders ?? 0);

                    final double computedTotalPurchase = orders.isNotEmpty
                        ? orders.fold<double>(0.0, (acc, o) => acc + o.totalAmount)
                        : (profile?.totalPurchase ?? 0.0);

                    final double computedOutstanding = orders.isNotEmpty
                        ? orders
                            .where((o) =>
                                o.paymentStatus.toLowerCase() == 'pending')
                            .fold<double>(0.0, (acc, o) => acc + o.totalAmount)
                        : (profile?.outstanding ?? 0.0);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      children: [
                        // SHOP IDENTITY CARD
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.milkBlue900.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.milkBlue50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.milkBlue100),
                                ),
                                child: Center(
                                  child: Text(
                                    shopName.isNotEmpty
                                        ? shopName[0].toUpperCase()
                                        : '🏪',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.milkBlue700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopName,
                                      style: AppTextStyles.h4,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ownerName,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.ink700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AppBadge(
                                      label: profile?.status == 'active'
                                          ? locale.t('approved_partner')
                                          : '${locale.t('status')}: ${locale.translateStatus(profile?.status ?? "pending")}',
                                      variant: profile?.status == 'active'
                                          ? BadgeVariant.success
                                          : BadgeVariant.neutral,
                                      showDot: true,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.milkBlue600,
                                ),
                                tooltip: locale.t('edit_profile'),
                                onPressed: profile != null
                                    ? () => _showEditProfileModal(context, profile)
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        // OUTSTANDING DUES ACTION BANNER (IF ANY)
                        if (computedOutstanding > 0) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.amber500.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Outstanding Balance',
                                        style: AppTextStyles.captionBold.copyWith(
                                          color: AppColors.amber800,
                                        ),
                                      ),
                                      Text(
                                        '₹${computedOutstanding.toStringAsFixed(0)}',
                                        style: AppTextStyles.h3.copyWith(
                                          color: AppColors.amber900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ShopPaymentScreen(
                                        amountDue: computedOutstanding,
                                        distributorId: widget.distributorId,
                                        distributorName: _distributorInfo?['companyName'],
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.milkBlue600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(locale.t('pay_now')),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // ACCOUNT SUMMARY (ORDERS, SPENT, OUTSTANDING)
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
                              Text(locale.t('account_summary'), style: AppTextStyles.label),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statItem(
                                    title: locale.t('total_orders'),
                                    value: '$computedOrdersCount',
                                    color: AppColors.milkBlue700,
                                    icon: Icons.receipt_long_outlined,
                                  ),
                                  _divider(),
                                  _statItem(
                                    title: locale.t('total_purchase'),
                                    value:
                                        '₹${computedTotalPurchase.toStringAsFixed(0)}',
                                    color: AppColors.dairyGreen700,
                                    icon: Icons.shopping_bag_outlined,
                                  ),
                                  _divider(),
                                  _statItem(
                                    title: locale.t('outstanding'),
                                    value:
                                        '₹${computedOutstanding.toStringAsFixed(0)}',
                                    color: computedOutstanding > 0
                                        ? AppColors.amber600
                                        : AppColors.ink500,
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ASSIGNED DISTRIBUTOR CARD
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
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping_outlined,
                                    color: AppColors.milkBlue600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    locale.t('assigned_distributor'),
                                    style: AppTextStyles.bodyBold,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              if (_loadingDistributor)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else if (_distributorInfo == null)
                                Text(
                                  'Distributor ID: ${widget.distributorId}',
                                  style: AppTextStyles.caption,
                                )
                              else ...[
                                _infoRow(
                                  Icons.business_outlined,
                                  locale.t('company'),
                                  _distributorInfo!['companyName'] ?? '',
                                ),
                                const SizedBox(height: 8),
                                _infoRow(
                                  Icons.person_outline,
                                  locale.t('contact_person'),
                                  _distributorInfo!['distributorName'] ?? '',
                                ),
                                if (_distributorInfo!['mobile']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _copyPhone(_distributorInfo!['mobile']!),
                                    child: _infoRow(
                                      Icons.phone_outlined,
                                      '${locale.t('phone')} (tap to copy)',
                                      _distributorInfo!['mobile']!,
                                      color: AppColors.milkBlue600,
                                    ),
                                  ),
                                ],
                                if (_distributorInfo!['address']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    Icons.location_on_outlined,
                                    locale.t('location'),
                                    _distributorInfo!['address']!,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // SHOP CONTACT & DELIVERY DETAILS
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
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.milkBlue600,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    locale.t('shop_details'),
                                    style: AppTextStyles.bodyBold,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              _infoRow(
                                Icons.person_outline,
                                locale.t('owner_name'),
                                ownerName,
                              ),
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.phone_outlined,
                                locale.t('phone'),
                                profile?.mobile ?? '',
                              ),
                              if (profile?.email.isNotEmpty == true) ...[
                                const SizedBox(height: 8),
                                _infoRow(
                                  Icons.email_outlined,
                                  'Email',
                                  profile!.email,
                                ),
                              ],
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.location_on_outlined,
                                locale.t('delivery_address'),
                                profile?.address ?? '',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.ink500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.ink500),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: AppTextStyles.captionBold.copyWith(color: AppColors.ink700),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: color ?? AppColors.ink900,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $phone to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, ShopProfile profile) {
    final shopNameCtrl = TextEditingController(text: profile.shopName);
    final ownerNameCtrl = TextEditingController(text: profile.ownerName);
    final phoneCtrl = TextEditingController(text: profile.mobile);
    final addressCtrl = TextEditingController(text: profile.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Edit Shop Profile', style: AppTextStyles.h4),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              TextField(
                controller: shopNameCtrl,
                decoration: const InputDecoration(labelText: 'Shop Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ownerNameCtrl,
                decoration: const InputDecoration(labelText: 'Owner Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Phone *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Delivery Address *'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.milkBlue600,
                  ),
                  onPressed: () async {
                    if (shopNameCtrl.text.trim().isEmpty ||
                        ownerNameCtrl.text.trim().isEmpty ||
                        addressCtrl.text.trim().isEmpty) {
                      return;
                    }

                    await ShopService.updateShopProfile(
                      distributorId: widget.distributorId,
                      shopUid: widget.shopUid,
                      shopName: shopNameCtrl.text.trim(),
                      ownerName: ownerNameCtrl.text.trim(),
                      mobile: phoneCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, LocaleState locale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.red500),
            const SizedBox(width: 8),
            Text(locale.t('logout')),
          ],
        ),
        content: Text(
          locale.t('logout_shop_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(locale.t('logout')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await AuthService.signOut();
        if (context.mounted) {
          try {
            AuthStateScope.of(context).clear();
          } catch (_) {}

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: AppColors.red500,
            ),
          );
        }
      }
    }
  }
}
