import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../data/mock_data.dart';
import '../../state/locale_state.dart';

class StatementScreen extends StatefulWidget {
  final String shopName;
  final bool embedded;
  const StatementScreen({
    super.key,
    required this.shopName,
    this.embedded = false,
  });

  @override
  State<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends State<StatementScreen> {
  final String _fromDate = '01 Aug 2026';
  final String _toDate = '23 Aug 2026';

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (!widget.embedded) _buildHeader(context, locale),
          // Summary card
          _buildSummaryCard(locale),
          // Date filter
          _buildDateFilter(locale),
          // Table
          Expanded(child: _buildTable(locale)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LocaleState locale) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.t('statement'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  widget.shopName,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _iconBtn(Icons.download_outlined, () {}),
          _iconBtn(Icons.print_outlined, () {}),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LocaleState locale) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.milkBlue700, AppColors.milkBlue500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell(
              locale.t('opening_balance'),
              '₹1,500',
              Colors.white70,
              Colors.white,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _summaryCell(
              locale.t('outstanding'),
              '₹2,240',
              Colors.white70,
              Colors.white,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          Expanded(
            child: _summaryCell(
              locale.t('closing_balance'),
              '₹2,240',
              Colors.white70,
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.bodyBold.copyWith(color: valueColor)),
        Text(
          label,
          style: AppTextStyles.overline.copyWith(color: labelColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateFilter(LocaleState locale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _dateField(locale.t('from_date'), _fromDate, () {})),
          const SizedBox(width: 10),
          Expanded(child: _dateField(locale.t('to_date'), _toDate, () {})),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.milkBlue600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.ink500,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.overline),
                Text(value, style: AppTextStyles.captionBold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(LocaleState locale) {
    return Column(
      children: [
        // Table header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.milkBlue50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('date').toUpperCase(),
                  style: AppTextStyles.overline,
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  locale.t('desc').toUpperCase(),
                  style: AppTextStyles.overline,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('debit').toUpperCase(),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('credit').toUpperCase(),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  locale.t('balance').toUpperCase(),
                  style: AppTextStyles.overline,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: mockStatement.length,
            itemBuilder: (_, i) {
              final e = mockStatement[i];
              final isDebit = e.debit != null && e.debit! > 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: i.isEven
                      ? AppColors.cardSurface
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${e.date.split(' ')[0]}\n${e.date.split(' ')[1]}',
                        style: AppTextStyles.overline,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.description,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (e.refId != '—')
                            Text(
                              e.refId,
                              style: AppTextStyles.overline.copyWith(
                                color: AppColors.milkBlue600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.debit != null
                            ? '₹${e.debit!.toStringAsFixed(0)}'
                            : '—',
                        style: AppTextStyles.captionBold.copyWith(
                          color: isDebit ? AppColors.red600 : AppColors.ink300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.credit != null
                            ? '₹${e.credit!.toStringAsFixed(0)}'
                            : '—',
                        style: AppTextStyles.captionBold.copyWith(
                          color: e.credit != null
                              ? AppColors.dairyGreen700
                              : AppColors.ink300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${e.balance.toStringAsFixed(0)}',
                        style: AppTextStyles.captionBold.copyWith(
                          color: e.balance > 0
                              ? AppColors.red600
                              : AppColors.dairyGreen700,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
