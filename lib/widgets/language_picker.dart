import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/text_styles.dart';
import '../state/locale_state.dart';

/// Compact pill button shown in app headers to open language picker.
class LanguagePillButton extends StatelessWidget {
  const LanguagePillButton({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              locale.language.nativeLabel,
              style: AppTextStyles.captionBold.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same pill but on a light surface (e.g., inside white card headers).
class LanguagePillButtonLight extends StatelessWidget {
  const LanguagePillButtonLight({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.milkBlue100,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 15, color: AppColors.milkBlue700),
            const SizedBox(width: 5),
            Text(
              locale.language.nativeLabel,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.milkBlue700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context, LocaleState locale) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _LanguagePickerSheet(locale: locale);
    },
  );
}

class _LanguagePickerSheet extends StatelessWidget {
  final LocaleState locale;
  const _LanguagePickerSheet({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(locale.t('language'), style: AppTextStyles.h4),
          const SizedBox(height: 16),
          ...AppLanguage.values.map((lang) {
            final selected = locale.language == lang;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  locale.setLanguage(lang);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.milkBlue100
                        : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.milkBlue600
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang.nativeLabel,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: selected
                              ? AppColors.milkBlue700
                              : AppColors.ink900,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.milkBlue600,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
