import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../state/locale_state.dart';
import '../../widgets/gradient_header.dart';

class _Notif {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String typeKey;
  final String body;
  final String time;
  final bool unread;
  const _Notif({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.typeKey,
    required this.body,
    required this.time,
    this.unread = false,
  });
}

const _notifs = [
  _Notif(
    icon: Icons.receipt_long_rounded,
    iconColor: AppColors.milkBlue700,
    iconBg: AppColors.milkBlue100,
    typeKey: 'notif_new_order',
    body: 'Sharma Kirana placed a new order of ₹1,200',
    time: '2 min ago',
    unread: true,
  ),
  _Notif(
    icon: Icons.payments_rounded,
    iconColor: AppColors.dairyGreen700,
    iconBg: AppColors.dairyGreen100,
    typeKey: 'notif_payment_received',
    body: 'City Grocery paid ₹1,428 via UPI',
    time: '45 min ago',
    unread: true,
  ),
  _Notif(
    icon: Icons.warning_amber_rounded,
    iconColor: AppColors.amber600,
    iconBg: AppColors.amber100,
    typeKey: 'notif_low_stock',
    body: 'Buttermilk 500ml is running low — only 5 units left',
    time: '1 hr ago',
    unread: true,
  ),
  _Notif(
    icon: Icons.check_circle_rounded,
    iconColor: AppColors.dairyGreen700,
    iconBg: AppColors.dairyGreen100,
    typeKey: 'notif_order_confirmed',
    body: 'Order #ORD-1041 has been confirmed',
    time: '2 hr ago',
  ),
  _Notif(
    icon: Icons.local_shipping_rounded,
    iconColor: AppColors.milkBlue700,
    iconBg: AppColors.milkBlue100,
    typeKey: 'notif_delivery_update',
    body: 'Order #ORD-1040 is out for delivery',
    time: '3 hr ago',
  ),
  _Notif(
    icon: Icons.store_rounded,
    iconColor: AppColors.milkBlue700,
    iconBg: AppColors.milkBlue100,
    typeKey: 'notif_new_shop',
    body: 'New shop "Kumar Mart" has been added',
    time: 'Yesterday',
  ),
  _Notif(
    icon: Icons.hourglass_empty_rounded,
    iconColor: AppColors.red600,
    iconBg: AppColors.red100,
    typeKey: 'notif_payment_pending',
    body: 'Patel General Store has a pending payment of ₹720',
    time: 'Yesterday',
  ),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<bool> _read = List.generate(
    _notifs.length,
    (i) => !_notifs[i].unread,
  );

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final unreadCount = _read.where((r) => !r).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('notifications'),
            subtitle: unreadCount > 0
                ? '$unreadCount ${locale.t('unread')}'
                : locale.t('all_caught_up'),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  for (int i = 0; i < _read.length; i++) {
                    _read[i] = true;
                  }
                }),
                child: Text(
                  locale.t('mark_all_read'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifs.length,
              itemBuilder: (_, i) {
                final n = _notifs[i];
                final isRead = _read[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _read[i] = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead
                            ? AppColors.cardSurface
                            : AppColors.milkBlue50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRead
                              ? AppColors.border
                              : AppColors.milkBlue100,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: n.iconBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(n.icon, color: n.iconColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      locale.t(n.typeKey),
                                      style: AppTextStyles.captionBold,
                                    ),
                                    const Spacer(),
                                    Text(locale.translateRelativeTime(n.time), style: AppTextStyles.overline),
                                    if (!isRead) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.milkBlue600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.ink700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
