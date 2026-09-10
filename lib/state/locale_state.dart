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

/// ChangeNotifier that holds the current language and exposes smart translation helpers.
class LocaleState extends ChangeNotifier {
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  void setLanguage(AppLanguage lang) {
    if (lang == _language) return;
    _language = lang;
    notifyListeners();
  }

  /// Look up direct translation key. Falls back to English, then the raw key.
  String t(String key) {
    final entry = translations[key];
    if (entry == null) return key;
    return entry[_language.code] ?? entry['en'] ?? key;
  }

  /// Translate product names (e.g. "Full Cream Milk", "Toned Milk 500ml", "Fresh Curd").
  String translateProduct(String name) {
    if (name.isEmpty) return name;
    if (_language == AppLanguage.en) return name;

    final trimmed = name.trim();

    // Direct mapping dictionary
    final Map<String, Map<String, String>> directNames = {
      'full cream milk': {
        'hi': 'फुल क्रीम दूध',
        'mr': 'फुल क्रीम दूध',
      },
      'toned milk': {
        'hi': 'टोन्ड दूध',
        'mr': 'टोन्ड दूध',
      },
      'fresh curd': {
        'hi': 'ताज़ा दही',
        'mr': 'ताजे दही',
      },
      'curd': {
        'hi': 'दही',
        'mr': 'दही',
      },
      'buttermilk': {
        'hi': 'छाछ',
        'mr': 'ताक',
      },
      'paneer': {
        'hi': 'पनीर',
        'mr': 'पनीर',
      },
      'white butter': {
        'hi': 'सफेद मक्खन',
        'mr': 'पांढरे लोणी',
      },
      'butter': {
        'hi': 'मक्खन',
        'mr': 'लोणी',
      },
      'ghee': {
        'hi': 'घी',
        'mr': 'तूप',
      },
      'cow milk': {
        'hi': 'गाय का दूध',
        'mr': 'गायीचे दूध',
      },
      'buffalo milk': {
        'hi': 'भैंस का दूध',
        'mr': 'म्हशीचे दूध',
      },
      'cream': {
        'hi': 'मलाई',
        'mr': 'साय',
      },
      'sweets': {
        'hi': 'मिठाई',
        'mr': 'मिठाई',
      },
    };

    final lower = trimmed.toLowerCase();
    if (directNames.containsKey(lower)) {
      return directNames[lower]?[_language.code] ?? name;
    }

    // Check composite names with pack sizes (e.g., "Full Cream Milk 1L", "Curd 500g")
    for (final entry in directNames.entries) {
      if (lower.startsWith(entry.key)) {
        final remainder = trimmed.substring(entry.key.length).trim();
        final base = entry.value[_language.code] ?? entry.key;
        return remainder.isNotEmpty ? '$base $remainder' : base;
      }
    }

    return name;
  }

  /// Translate product categories.
  String translateCategory(String category) {
    if (category.isEmpty) return category;
    final key = category.trim().toLowerCase();
    final Map<String, String> catKeys = {
      'all': 'cat_all',
      'milk': 'cat_milk',
      'curd': 'cat_curd',
      'butter': 'cat_butter',
      'paneer': 'cat_paneer',
      'ghee': 'cat_ghee',
      'buttermilk': 'cat_buttermilk',
      'other': 'cat_other',
    };

    if (catKeys.containsKey(key)) {
      return t(catKeys[key]!);
    }
    return category;
  }

  /// Translate measurement units (e.g. "Pouch", "Bottle", "Cup", "Pack", "Kg", "Litre", "L", "ml", "g").
  String translateUnit(String unit) {
    if (unit.isEmpty) return unit;
    final lower = unit.trim().toLowerCase();
    final Map<String, String> unitKeys = {
      'pouch': 'unit_pouch',
      'packet': 'unit_pouch',
      'bottle': 'unit_bottle',
      'cup': 'unit_cup',
      'pack': 'unit_pack',
      'can': 'unit_can',
      'kg': 'unit_kg',
      'litre': 'unit_litre',
      'liter': 'unit_litre',
      'l': 'unit_l',
      'ml': 'unit_ml',
      'g': 'unit_g',
      'pcs': 'unit_pcs',
      'boxes': 'unit_boxes',
    };

    if (unitKeys.containsKey(lower)) {
      return t(unitKeys[lower]!);
    }
    return unit;
  }

  /// Translate statuses (Order, Payment, Product, Shop status).
  String translateStatus(String status) {
    if (status.isEmpty) return status;
    final lower = status.trim().toLowerCase();

    final Map<String, String> statusKeys = {
      'new': 'order_new',
      'confirmed': 'order_confirmed',
      'packed': 'order_packed',
      'prepared': 'order_prepared',
      'out for delivery': 'order_out_delivery',
      'out_for_delivery': 'order_out_delivery',
      'delivered': 'order_delivered',
      'completed': 'order_completed',
      'cancelled': 'order_cancelled',
      'rejected': 'order_rejected',
      'paid': 'pay_paid',
      'partially paid': 'pay_partial',
      'partially_paid': 'pay_partial',
      'pending': 'pay_pending',
      'failed': 'pay_failed',
      'overdue': 'overdue',
      'active': 'shop_active',
      'inactive': 'shop_inactive',
      'low stock': 'low_stock_label',
      'low_stock': 'low_stock_label',
      'all': 'all',
      'approved': 'approved_partner',
    };

    if (statusKeys.containsKey(lower)) {
      return t(statusKeys[lower]!);
    }
    return status;
  }

  /// Translate payment methods.
  String translatePaymentMethod(String method) {
    if (method.isEmpty) return method;
    final lower = method.trim().toLowerCase();

    final Map<String, String> methodKeys = {
      'upi': 'pay_upi',
      'cod': 'pay_cod',
      'cash on delivery': 'pay_cod',
      'cash': 'pay_cash',
      'bank': 'pay_bank',
      'bank transfer': 'pay_bank',
      'credit': 'pay_credit',
      'credit / outstanding': 'pay_credit',
      'card': 'pay_card',
      'cheque': 'pay_cheque',
    };

    if (methodKeys.containsKey(lower)) {
      return t(methodKeys[lower]!);
    }
    return method;
  }

  /// Translate days of week and months in dates (e.g. "Mon", "23 Aug 2026", "Tomorrow Morning").
  String translateDate(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    if (_language == AppLanguage.en) return dateStr;

    String result = dateStr;

    // Relative dates
    final Map<String, String> relativeMap = {
      'today': t('today'),
      'yesterday': t('yesterday'),
      'tomorrow': t('tomorrow'),
      'tomorrow morning': t('tomorrow_morning'),
      'morning (6–9 am)': t('morning_slot'),
      'recently': t('recently'),
      'just now': t('just_now'),
    };

    final lower = dateStr.trim().toLowerCase();
    if (relativeMap.containsKey(lower)) {
      return relativeMap[lower]!;
    }

    // Days
    final Map<String, String> days = {
      'Mon': t('day_mon'),
      'Tue': t('day_tue'),
      'Wed': t('day_wed'),
      'Thu': t('day_thu'),
      'Fri': t('day_fri'),
      'Sat': t('day_sat'),
      'Sun': t('day_sun'),
    };

    for (final e in days.entries) {
      result = result.replaceAll(e.key, e.value);
    }

    // Months
    final Map<String, String> months = {
      'Jan': t('month_jan'),
      'Feb': t('month_feb'),
      'Mar': t('month_mar'),
      'Apr': t('month_apr'),
      'May': t('month_may'),
      'Jun': t('month_jun'),
      'Jul': t('month_jul'),
      'Aug': t('month_aug'),
      'Sep': t('month_sep'),
      'Oct': t('month_oct'),
      'Nov': t('month_nov'),
      'Dec': t('month_dec'),
    };

    for (final e in months.entries) {
      result = result.replaceAll(e.key, e.value);
    }

    return result;
  }

  /// Translate relative time (e.g. "2 min ago", "45 min ago", "1 hr ago", "Yesterday").
  String translateRelativeTime(String timeStr) {
    if (timeStr.isEmpty) return timeStr;
    if (_language == AppLanguage.en) return timeStr;

    final lower = timeStr.trim().toLowerCase();
    if (lower == 'yesterday') return t('yesterday');
    if (lower == 'today') return t('today');
    if (lower == 'just now') return t('just_now');

    if (_language == AppLanguage.hi) {
      return timeStr
          .replaceAll(RegExp(r'\bmin ago\b', caseSensitive: false), 'मिनट पहले')
          .replaceAll(RegExp(r'\bmins ago\b', caseSensitive: false), 'मिनट पहले')
          .replaceAll(RegExp(r'\bhr ago\b', caseSensitive: false), 'घंटे पहले')
          .replaceAll(RegExp(r'\bhrs ago\b', caseSensitive: false), 'घंटे पहले')
          .replaceAll(RegExp(r'\bYesterday\b', caseSensitive: false), 'कल');
    } else if (_language == AppLanguage.mr) {
      return timeStr
          .replaceAll(RegExp(r'\bmin ago\b', caseSensitive: false), 'मिनिटांपूर्वी')
          .replaceAll(RegExp(r'\bmins ago\b', caseSensitive: false), 'मिनिटांपूर्वी')
          .replaceAll(RegExp(r'\bhr ago\b', caseSensitive: false), 'तासांपूर्वी')
          .replaceAll(RegExp(r'\bhrs ago\b', caseSensitive: false), 'तासांपूर्वी')
          .replaceAll(RegExp(r'\bYesterday\b', caseSensitive: false), 'काल');
    }

    return timeStr;
  }

  /// Translate statement descriptions (e.g. "Opening Balance", "Invoice — Full Cream Milk", "Payment Received").
  String translateStatementDesc(String desc) {
    if (desc.isEmpty) return desc;
    if (_language == AppLanguage.en) return desc;

    final trimmed = desc.trim();

    if (trimmed.toLowerCase() == 'opening balance') {
      return t('opening_balance');
    }
    if (trimmed.toLowerCase() == 'closing balance') {
      return t('closing_balance');
    }
    if (trimmed.toLowerCase() == 'payment received') {
      return t('payment_received');
    }

    if (trimmed.startsWith('Invoice — ') || trimmed.startsWith('Invoice - ')) {
      final item = trimmed.substring(10).trim();
      final invoiceWord = t('invoice');
      final translatedItem = translateProduct(item);
      return '$invoiceWord — $translatedItem';
    }

    return desc;
  }

  /// Translate broadcast tags (e.g. "Notice", "Delivery", "Stock", "Urgent", "Offer", "Price").
  String translateBroadcastTag(String tag) {
    if (tag.isEmpty) return tag;
    final lower = tag.trim().toLowerCase();
    final Map<String, String> tagKeys = {
      'notice': 'tag_notice',
      'delivery': 'tag_delivery',
      'stock': 'tag_stock',
      'urgent': 'tag_urgent',
      'offer': 'tag_offer',
      'price': 'tag_price',
      'holiday': 'tag_holiday',
      'rate': 'tag_rate',
    };

    if (tagKeys.containsKey(lower)) {
      return t(tagKeys[lower]!);
    }
    return tag;
  }

  /// General smart fallback translator for any common UI or data phrase.
  String translateData(String text) {
    if (text.isEmpty) return text;
    if (_language == AppLanguage.en) return text;

    final lower = text.trim().toLowerCase();

    // Check direct translation dictionary
    if (translations.containsKey(lower)) {
      return t(lower);
    }

    // Common phrases
    if (_language == AppLanguage.hi) {
      if (lower.endsWith('orders')) {
        final numPart = text.split(' ')[0];
        return '$numPart ऑर्डर';
      }
      if (lower.endsWith('sold')) {
        final numPart = text.split(' ')[0];
        return '$numPart बिके';
      }
      if (lower.endsWith('items in cart')) {
        final numPart = text.split(' ')[0];
        return '$numPart आइटम कार्ट में';
      }
      if (lower.endsWith('unread')) {
        final numPart = text.split(' ')[0];
        return '$numPart अपठित';
      }
    } else if (_language == AppLanguage.mr) {
      if (lower.endsWith('orders')) {
        final numPart = text.split(' ')[0];
        return '$numPart ऑर्डर';
      }
      if (lower.endsWith('sold')) {
        final numPart = text.split(' ')[0];
        return '$numPart विकले';
      }
      if (lower.endsWith('items in cart')) {
        final numPart = text.split(' ')[0];
        return '$numPart आयटम कार्टमध्ये';
      }
      if (lower.endsWith('unread')) {
        final numPart = text.split(' ')[0];
        return '$numPart न वाचलेले';
      }
    }

    return text;
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
