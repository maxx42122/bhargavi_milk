import 'package:flutter/material.dart';
import '../l10n/translations.dart';

/// Supported language codes.
enum AppLanguage { en, hi, mr }

extension AppLanguageExt on AppLanguage {
  String get code => name; // 'en' / 'hi' / 'mr'
  String get label =>
      const {'en': 'English', 'hi': 'हिंदी', 'mr': 'मराठी'}[name]!;
  String get nativeLabel =>
      const {'en': 'English', 'hi': 'हिंदी', 'mr': 'मराठी'}[name]!;
}

/// ChangeNotifier that holds the current language and exposes t() helper.
class LocaleState extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (lang == _language) return;
    _language = lang;
    notifyListeners();
  }

  /// Look up translation. Falls back to English, then the raw key.
  String t(String key) {
    final entry = translations[key];
    if (entry == null) return key;
    return entry[_language.code] ?? entry['en'] ?? key;
  }
}

/// InheritedNotifier for app-wide access without BuildContext drilling.
class LocaleScope extends InheritedNotifier<LocaleState> {
  const LocaleScope({
    super.key,
    required LocaleState state,
    required super.child,
  }) : super(notifier: state);

  static LocaleState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'No LocaleScope found in widget tree.');
    return scope!.notifier!;
  }
}
