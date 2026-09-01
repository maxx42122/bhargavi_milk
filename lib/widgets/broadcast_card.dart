import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';
import '../services/auth_service.dart';
import '../services/broadcast_service.dart';
import '../state/locale_state.dart';

class DistributorBroadcastCard extends StatefulWidget {
  const DistributorBroadcastCard({super.key});

  @override
  State<DistributorBroadcastCard> createState() =>
      _DistributorBroadcastCardState();
}

class _DistributorBroadcastCardState extends State<DistributorBroadcastCard> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String _selectedTag = 'Notice';
  bool _isSubmitting = false;
  bool _showComposer = true;

  final List<(String, String, IconData, Color)> _tags = [
    ('Notice', '📢 Notice', Icons.campaign_rounded, AppColors.milkBlue600),
    ('Delivery', '🚚 Delivery', Icons.local_shipping_rounded, AppColors.milkBlue700),
    ('Stock', '🥛 Stock', Icons.inventory_2_rounded, AppColors.dairyGreen600),
    ('Urgent', '⚡ Urgent', Icons.warning_amber_rounded, AppColors.red600),
    ('Offer', '🎉 Offer', Icons.local_offer_rounded, AppColors.amber600),
    ('Price', '📋 Price', Icons.receipt_long_rounded, AppColors.ink700),
  ];

  final List<(String, String)> _templates = [
    ('🚚 Delivery', 'Morning milk delivery will be delayed by 30 mins today.'),
    ('🥛 Stock', 'Fresh Paneer & Curd stock is now available for ordering!'),
    ('🛑 Holiday', 'Dairy will be closed tomorrow. Please place bulk orders today.'),
    ('📋 Rate', 'New rates for milk & dairy products have been updated in the catalog.'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast(String distributorId, LocaleState locale) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.t('broadcast_hint')),
          backgroundColor: AppColors.red600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await BroadcastService.sendBroadcast(
        distributorId: distributorId,
        message: message,
        title: _titleController.text.trim(),
        tag: _selectedTag,
        active: true,
      );

      if (mounted) {
        _messageController.clear();
        _titleController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(locale.t('broadcast_sent'))),
              ],
            ),
            backgroundColor: AppColors.dairyGreen600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: AppColors.red600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _clearBroadcast(String distributorId, LocaleState locale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.t('clear_broadcast')),
        content: const Text('Are you sure you want to stop displaying this broadcast to all shops?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(locale.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            child: Text(locale.t('confirm')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await BroadcastService.clearBroadcast(distributorId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.t('broadcast_cleared')),
            backgroundColor: AppColors.ink700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing broadcast: $e'),
            backgroundColor: AppColors.red600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'urgent':
        return AppColors.red600;
      case 'delivery':
        return AppColors.milkBlue600;
      case 'stock':
        return AppColors.dairyGreen600;
      case 'offer':
        return AppColors.amber600;
      default:
        return AppColors.milkBlue700;
    }
  }

  Color _getTagBg(String tag) {
    switch (tag.toLowerCase()) {
      case 'urgent':
        return AppColors.red100;
      case 'delivery':
        return AppColors.milkBlue100;
      case 'stock':
        return AppColors.dairyGreen100;
      case 'offer':
        return AppColors.amber100;
      default:
        return AppColors.milkBlue100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final distributorId = AuthService.currentUser?.uid ?? '';

    if (distributorId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<BroadcastModel?>(
      stream: BroadcastService.streamCurrentBroadcast(distributorId),
      builder: (context, snapshot) {
        final currentBroadcast = snapshot.data;
        final hasActiveBroadcast = currentBroadcast != null &&
            currentBroadcast.active &&
            currentBroadcast.message.isNotEmpty;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasActiveBroadcast
                  ? AppColors.milkBlue300
                  : AppColors.border,
              width: hasActiveBroadcast ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: hasActiveBroadcast
                    ? AppColors.milkBlue600.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasActiveBroadcast
                              ? [AppColors.milkBlue600, AppColors.milkBlue800]
                              : [AppColors.milkBlue400, AppColors.milkBlue600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.t('broadcast_to_shops'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasActiveBroadcast
                                ? 'Broadcast is live on all shop dashboards'
                                : 'Send instant message or notice to all shops',
                            style: AppTextStyles.caption.copyWith(
                              color: hasActiveBroadcast
                                  ? AppColors.dairyGreen700
                                  : AppColors.ink500,
                              fontWeight: hasActiveBroadcast
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasActiveBroadcast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dairyGreen100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.dairyGreen300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.dairyGreen600,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LIVE',
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.dairyGreen700,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Active Broadcast Display (if active) ───────────────────
              if (hasActiveBroadcast)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTagBg(currentBroadcast.tag),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTagColor(currentBroadcast.tag).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getTagColor(currentBroadcast.tag),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentBroadcast.tag.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (currentBroadcast.title.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentBroadcast.title,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.ink900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Spacer(),
                          // Clear button
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.red600,
                            ),
                            tooltip: locale.t('clear_broadcast'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _clearBroadcast(distributorId, locale),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentBroadcast.message,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Visible to all connected shops',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.ink500,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _messageController.text = currentBroadcast.message;
                                _titleController.text = currentBroadcast.title;
                                _selectedTag = currentBroadcast.tag;
                                _showComposer = true;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.edit_rounded,
                                    size: 13,
                                    color: AppColors.milkBlue700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    locale.t('edit'),
                                    style: AppTextStyles.overline.copyWith(
                                      color: AppColors.milkBlue700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Broadcast Composer ─────────────────────────────────────
              if (_showComposer) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag selector
                      Text(
                        locale.t('broadcast_quick_tags'),
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.ink700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tags.map((t) {
                            final isSelected = _selectedTag == t.$1;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      t.$3,
                                      size: 14,
                                      color: isSelected ? Colors.white : t.$4,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(t.$2),
                                  ],
                                ),
                                selected: isSelected,
                                selectedColor: t.$4,
                                backgroundColor: AppColors.background,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.ink700,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedTag = t.$1);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Message Input
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 2,
                          style: AppTextStyles.body,
                          decoration: InputDecoration(
                            hintText: locale.t('broadcast_hint'),
                            hintStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.ink400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            suffixIcon: _messageController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() => _messageController.clear());
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Quick templates chips
                      Text(
                        locale.t('broadcast_templates'),
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.ink500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _templates.map((tpl) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _messageController.text = tpl.$2;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.milkBlue50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.milkBlue200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tpl.$1,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.milkBlue800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _sendBroadcast(distributorId, locale),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.milkBlue700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.campaign_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      locale.t('send_broadcast'),
                                      style: AppTextStyles.label.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
