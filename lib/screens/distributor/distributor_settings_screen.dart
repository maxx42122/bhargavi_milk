import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/distributor_settings_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/gradient_header.dart';

class DistributorSettingsScreen extends StatefulWidget {
  const DistributorSettingsScreen({super.key});

  @override
  State<DistributorSettingsScreen> createState() =>
      _DistributorSettingsScreenState();
}

class _DistributorSettingsScreenState extends State<DistributorSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _distributorId = '';

  // Timing settings
  bool _timingEnabled = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  List<int> _activeDays = [1, 2, 3, 4, 5, 6, 7];

  // Payment settings
  bool _blockOnPendingPayment = true;
  final TextEditingController _toleranceCtrl = TextEditingController(text: '0');

  // Custom notice
  final TextEditingController _noticeCtrl = TextEditingController();

  final List<(String, int)> _weekDays = const [
    ('Mon', 1),
    ('Tue', 2),
    ('Wed', 3),
    ('Thu', 4),
    ('Fri', 5),
    ('Sat', 6),
    ('Sun', 7),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _toleranceCtrl.dispose();
    _noticeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auth = AuthStateScope.of(context);
    final distId = auth.distributorId ?? AuthService.currentUser?.uid ?? '';
    _distributorId = distId;

    if (distId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final settings = await DistributorSettingsService.fetchSettings(distId);
      if (mounted) {
        setState(() {
          _timingEnabled = settings.orderTimingEnabled;
          _startTime = TimeOfDay(hour: settings.startHour, minute: settings.startMinute);
          _endTime = TimeOfDay(hour: settings.endHour, minute: settings.endMinute);
          _activeDays = List<int>.from(settings.activeDays);
          _blockOnPendingPayment = settings.blockOnPendingPayment;
          _toleranceCtrl.text = settings.maxPendingTolerance == 0
              ? '0'
              : settings.maxPendingTolerance.toStringAsFixed(0);
          _noticeCtrl.text = settings.customClosedNotice;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Select Ordering Start Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.milkBlue600,
              onPrimary: Colors.white,
              onSurface: AppColors.ink900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'Select Ordering End Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.milkBlue600,
              onPrimary: Colors.white,
              onSurface: AppColors.ink900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _applyPreset(int startH, int startM, int endH, int endM, bool enabled) {
    setState(() {
      _timingEnabled = enabled;
      _startTime = TimeOfDay(hour: startH, minute: startM);
      _endTime = TimeOfDay(hour: endH, minute: endM);
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour;
    final minute = tod.minute;
    return DistributorOrderSettings.formatTime(hour, minute);
  }

  Future<void> _saveSettings(LocaleState locale) async {
    if (_distributorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distributor ID not available'),
          backgroundColor: AppColors.red500,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double tolerance = double.tryParse(_toleranceCtrl.text.trim()) ?? 0.0;

      final updated = DistributorOrderSettings(
        orderTimingEnabled: _timingEnabled,
        startHour: _startTime.hour,
        startMinute: _startTime.minute,
        endHour: _endTime.hour,
        endMinute: _endTime.minute,
        startTimeFormatted: _formatTimeOfDay(_startTime),
        endTimeFormatted: _formatTimeOfDay(_endTime),
        blockOnPendingPayment: _blockOnPendingPayment,
        maxPendingTolerance: tolerance,
        customClosedNotice: _noticeCtrl.text.trim(),
        activeDays: _activeDays.isNotEmpty ? _activeDays : const [1, 2, 3, 4, 5, 6, 7],
      );

      await DistributorSettingsService.updateSettings(
        distributorId: _distributorId,
        settings: updated,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(locale.t('store_rules_saved')),
            ],
          ),
          backgroundColor: AppColors.dairyGreen600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: AppColors.red500,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);

    // Current live status calculation for preview
    final previewSettings = DistributorOrderSettings(
      orderTimingEnabled: _timingEnabled,
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      startTimeFormatted: _formatTimeOfDay(_startTime),
      endTimeFormatted: _formatTimeOfDay(_endTime),
      activeDays: _activeDays,
    );

    final statusInfo = DistributorSettingsService.isWithinOrderingHours(previewSettings);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: locale.t('order_settings'),
            subtitle: locale.t('ordering_hours_desc'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      // ── Live Status Preview Card ──────────────────────────────
                      _buildLiveStatusCard(locale, statusInfo.isOpen),

                      const SizedBox(height: 20),

                      // ── Section 1: Ordering Time Window ──────────────────────
                      _buildSectionHeader(
                        icon: Icons.schedule_rounded,
                        title: locale.t('ordering_hours'),
                        subtitle: locale.t('ordering_window_desc'),
                      ),
                      const SizedBox(height: 12),
                      _buildTimingCard(locale),

                      const SizedBox(height: 24),

                      // ── Section 2: Pending Payment Restrictions ──────────────
                      _buildSectionHeader(
                        icon: Icons.payments_outlined,
                        title: locale.t('payment_rules_title'),
                        subtitle: locale.t('payment_rules_desc'),
                      ),
                      const SizedBox(height: 12),
                      _buildPaymentRestrictionsCard(locale),

                      const SizedBox(height: 24),

                      // ── Section 3: Custom Announcement / Closed Notice ───────
                      _buildSectionHeader(
                        icon: Icons.campaign_outlined,
                        title: locale.t('store_notice_title'),
                        subtitle: locale.t('store_notice_desc'),
                      ),
                      const SizedBox(height: 12),
                      _buildNoticeCard(locale),
                    ],
                  ),
          ),
        ],
      ),
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.milkBlue600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isSaving ? null : () => _saveSettings(locale),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                locale.t('save_settings'),
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.milkBlue50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.milkBlue700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.ink900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatusCard(LocaleState locale, bool isOpen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOpen
              ? [
                  AppColors.dairyGreen50,
                  Colors.white,
                ]
              : [
                  AppColors.red50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen
              ? AppColors.dairyGreen500.withValues(alpha: 0.3)
              : AppColors.red500.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: (isOpen ? AppColors.dairyGreen600 : AppColors.red600)
                .withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.dairyGreen100 : AppColors.red100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
              color: isOpen ? AppColors.dairyGreen700 : AppColors.red600,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOpen
                          ? locale.t('ordering_open')
                          : locale.t('ordering_closed'),
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isOpen ? AppColors.dairyGreen800 : AppColors.red700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.dairyGreen600 : AppColors.red600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _timingEnabled
                      ? '${locale.t("allowed_hours")}: ${_formatTimeOfDay(_startTime)} – ${_formatTimeOfDay(_endTime)}'
                      : locale.t('timing_disabled_notice'),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(LocaleState locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink100),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Time Window
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.t('enable_ordering_window'),
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink900),
            ),
            subtitle: Text(
              locale.t('limit_ordering_time_desc'),
              style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
            ),
            value: _timingEnabled,
            activeTrackColor: AppColors.milkBlue600,
            onChanged: (v) => setState(() => _timingEnabled = v),
          ),

          if (_timingEnabled) ...[
            const Divider(height: 24),

            // Start and End Time pickers
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerTile(
                    label: locale.t('start_time'),
                    time: _startTime,
                    icon: Icons.wb_sunny_outlined,
                    color: AppColors.milkBlue700,
                    bgColor: AppColors.milkBlue50,
                    onTap: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePickerTile(
                    label: locale.t('end_time'),
                    time: _endTime,
                    icon: Icons.nightlight_outlined,
                    color: AppColors.milkBlue900,
                    bgColor: AppColors.milkBlue50,
                    onTap: _pickEndTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick Preset Buttons
            Text(
              locale.t('quick_presets'),
              style: AppTextStyles.captionBold.copyWith(color: AppColors.ink600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('11:00 AM – 08:00 PM', 11, 0, 20, 0),
                _buildPresetChip('06:00 AM – 09:00 PM', 6, 0, 21, 0),
                _buildPresetChip('08:00 AM – 06:00 PM', 8, 0, 18, 0),
                _buildPresetChip('09:00 AM – 11:00 PM', 9, 0, 23, 0),
              ],
            ),

            const SizedBox(height: 18),

            // Days of the week
            Text(
              locale.t('active_ordering_days'),
              style: AppTextStyles.captionBold.copyWith(color: AppColors.ink600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekDays.map((day) {
                final isSelected = _activeDays.contains(day.$2);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_activeDays.length > 1) {
                          _activeDays.remove(day.$2);
                        }
                      } else {
                        _activeDays.add(day.$2);
                        _activeDays.sort();
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.milkBlue600 : AppColors.ink50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.milkBlue700 : AppColors.ink200,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      day.$1,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.ink700,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final formatted = _formatTimeOfDay(time);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatted,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.ink900,
                    fontSize: 17,
                  ),
                ),
                Icon(Icons.edit_rounded, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int sH, int sM, int eH, int eM) {
    final isCurrent = _timingEnabled &&
        _startTime.hour == sH &&
        _startTime.minute == sM &&
        _endTime.hour == eH &&
        _endTime.minute == eM;

    return GestureDetector(
      onTap: () => _applyPreset(sH, sM, eH, eM, true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.milkBlue600 : AppColors.milkBlue50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? AppColors.milkBlue700 : AppColors.milkBlue200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? Colors.white : AppColors.milkBlue800,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRestrictionsCard(LocaleState locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink100),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              locale.t('block_pending_payment'),
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink900),
            ),
            subtitle: Text(
              locale.t('block_pending_payment_desc'),
              style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
            ),
            value: _blockOnPendingPayment,
            activeTrackColor: AppColors.red500,
            onChanged: (v) => setState(() => _blockOnPendingPayment = v),
          ),

          if (_blockOnPendingPayment) ...[
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.amber800,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locale.t('pending_payment_rule_info'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.amber900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              locale.t('credit_limit_tolerance'),
              style: AppTextStyles.captionBold.copyWith(color: AppColors.ink700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _toleranceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: AppTextStyles.bodyBold.copyWith(color: AppColors.ink800),
                hintText: '0 (Zero tolerance)',
                helperText: locale.t('tolerance_helper_text'),
                helperMaxLines: 2,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.ink200),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoticeCard(LocaleState locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink100),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.t('custom_closed_notice_label'),
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.ink900),
          ),
          const SizedBox(height: 4),
          Text(
            locale.t('custom_closed_notice_desc'),
            style: AppTextStyles.caption.copyWith(color: AppColors.ink500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Orders accepted between 11:00 AM and 08:00 PM for next-morning delivery.',
              hintStyle: AppTextStyles.caption.copyWith(color: AppColors.ink400),
              filled: true,
              fillColor: AppColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.ink200),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}
