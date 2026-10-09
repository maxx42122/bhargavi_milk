import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'order_service.dart';
import 'shop_service.dart';

/// Model representing distributor's store and ordering rules/settings.
class DistributorOrderSettings {
  final bool orderTimingEnabled;
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour; // 0-23
  final int endMinute; // 0-59
  final String startTimeFormatted; // e.g. "11:00 AM"
  final String endTimeFormatted; // e.g. "08:00 PM"
  final bool blockOnPendingPayment;
  final double maxPendingTolerance; // e.g. 0.0 (any outstanding balance blocks)
  final String customClosedNotice;
  final List<int> activeDays; // 1 = Monday, 7 = Sunday
  final DateTime? updatedAt;

  const DistributorOrderSettings({
    this.orderTimingEnabled = true,
    this.startHour = 11,
    this.startMinute = 0,
    this.endHour = 20,
    this.endMinute = 0,
    this.startTimeFormatted = '11:00 AM',
    this.endTimeFormatted = '08:00 PM',
    this.blockOnPendingPayment = true,
    this.maxPendingTolerance = 0.0,
    this.customClosedNotice = '',
    this.activeDays = const [1, 2, 3, 4, 5, 6, 7],
    this.updatedAt,
  });

  /// Formats TimeOfDay into standard 12-hour AM/PM string e.g. "11:00 AM" or "08:00 PM".
  static String formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final hStr = h < 10 ? '0$h' : '$h';
    final mStr = minute < 10 ? '0$minute' : '$minute';
    return '$hStr:$mStr $period';
  }

  /// Parses time string like "11:00 AM", "8:00 PM", "20:00", etc. into (hour, minute).
  static (int, int) parseTimeString(String str, int defaultHour, int defaultMinute) {
    final trimmed = str.trim().toUpperCase();
    if (trimmed.isEmpty) return (defaultHour, defaultMinute);

    try {
      final isPm = trimmed.contains('PM');
      final isAm = trimmed.contains('AM');
      final clean = trimmed.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = clean.split(':');
      if (parts.isNotEmpty) {
        int hour = int.parse(parts[0].trim());
        int minute = parts.length > 1 ? int.parse(parts[1].trim()) : 0;
        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;
        return (hour.clamp(0, 23), minute.clamp(0, 59));
      }
    } catch (_) {}
    return (defaultHour, defaultMinute);
  }

  factory DistributorOrderSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const DistributorOrderSettings();
    }

    final rawTiming = data['orderTimingEnabled'] ?? data['timingEnabled'];
    final bool timingEnabled = rawTiming is bool ? rawTiming : true;

    final rawBlockPayment = data['blockOnPendingPayment'] ?? data['blockPendingPayment'];
    final bool blockPayment = rawBlockPayment is bool ? rawBlockPayment : true;

    final rawTolerance = data['maxPendingTolerance'] ?? data['pendingTolerance'];
    final double tolerance = (rawTolerance is num)
        ? rawTolerance.toDouble()
        : (double.tryParse(rawTolerance?.toString() ?? '0') ?? 0.0);

    final rawStartStr = (data['orderStartTime'] ?? '11:00 AM').toString().trim();
    final rawEndStr = (data['orderEndTime'] ?? '08:00 PM').toString().trim();

    final int startH = (data['orderStartHour'] is num)
        ? (data['orderStartHour'] as num).toInt()
        : parseTimeString(rawStartStr, 11, 0).$1;

    final int startM = (data['orderStartMinute'] is num)
        ? (data['orderStartMinute'] as num).toInt()
        : parseTimeString(rawStartStr, 11, 0).$2;

    final int endH = (data['orderEndHour'] is num)
        ? (data['orderEndHour'] as num).toInt()
        : parseTimeString(rawEndStr, 20, 0).$1;

    final int endM = (data['orderEndMinute'] is num)
        ? (data['orderEndMinute'] as num).toInt()
        : parseTimeString(rawEndStr, 20, 0).$2;

    final List<dynamic>? rawDays = data['activeDays'] as List<dynamic>?;
    final List<int> days = rawDays != null
        ? rawDays.map((d) => (d is num) ? d.toInt() : (int.tryParse(d.toString()) ?? 1)).toList()
        : const [1, 2, 3, 4, 5, 6, 7];

    DateTime? updatedAt;
    if (data['settingsUpdatedAt'] is Timestamp) {
      updatedAt = (data['settingsUpdatedAt'] as Timestamp).toDate();
    } else if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    return DistributorOrderSettings(
      orderTimingEnabled: timingEnabled,
      startHour: startH,
      startMinute: startM,
      endHour: endH,
      endMinute: endM,
      startTimeFormatted: formatTime(startH, startM),
      endTimeFormatted: formatTime(endH, endM),
      blockOnPendingPayment: blockPayment,
      maxPendingTolerance: tolerance,
      customClosedNotice: (data['customClosedNotice'] ?? data['orderingNotice'] ?? '').toString().trim(),
      activeDays: days.isNotEmpty ? days : const [1, 2, 3, 4, 5, 6, 7],
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderTimingEnabled': orderTimingEnabled,
      'orderStartHour': startHour,
      'orderStartMinute': startMinute,
      'orderEndHour': endHour,
      'orderEndMinute': endMinute,
      'orderStartTime': formatTime(startHour, startMinute),
      'orderEndTime': formatTime(endHour, endMinute),
      'blockOnPendingPayment': blockOnPendingPayment,
      'maxPendingTolerance': maxPendingTolerance,
      'customClosedNotice': customClosedNotice,
      'activeDays': activeDays,
      'settingsUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  DistributorOrderSettings copyWith({
    bool? orderTimingEnabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? blockOnPendingPayment,
    double? maxPendingTolerance,
    String? customClosedNotice,
    List<int>? activeDays,
  }) {
    final sH = startHour ?? this.startHour;
    final sM = startMinute ?? this.startMinute;
    final eH = endHour ?? this.endHour;
    final eM = endMinute ?? this.endMinute;

    return DistributorOrderSettings(
      orderTimingEnabled: orderTimingEnabled ?? this.orderTimingEnabled,
      startHour: sH,
      startMinute: sM,
      endHour: eH,
      endMinute: eM,
      startTimeFormatted: formatTime(sH, sM),
      endTimeFormatted: formatTime(eH, eM),
      blockOnPendingPayment: blockOnPendingPayment ?? this.blockOnPendingPayment,
      maxPendingTolerance: maxPendingTolerance ?? this.maxPendingTolerance,
      customClosedNotice: customClosedNotice ?? this.customClosedNotice,
      activeDays: activeDays ?? this.activeDays,
      updatedAt: DateTime.now(),
    );
  }
}

/// Result of ordering eligibility evaluation.
class OrderingEligibilityResult {
  final bool canOrder;
  final bool isTimeBlocked;
  final bool isPaymentBlocked;
  final String statusMessage;
  final String? timeWindowString;
  final double pendingAmount;

  const OrderingEligibilityResult({
    required this.canOrder,
    this.isTimeBlocked = false,
    this.isPaymentBlocked = false,
    required this.statusMessage,
    this.timeWindowString,
    this.pendingAmount = 0.0,
  });

  bool get isBlocked => !canOrder;
}

class DistributorSettingsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Real-time stream of distributor order & store settings.
  static Stream<DistributorOrderSettings> streamSettings(String distributorId) {
    if (distributorId.trim().isEmpty) {
      return Stream.value(const DistributorOrderSettings());
    }

    return _db
        .collection('distributor')
        .doc(distributorId.trim())
        .snapshots()
        .map((doc) {
          if (!doc.exists) return const DistributorOrderSettings();
          return DistributorOrderSettings.fromMap(doc.data());
        });
  }

  /// One-time fetch of distributor order settings.
  static Future<DistributorOrderSettings> fetchSettings(String distributorId) async {
    if (distributorId.trim().isEmpty) {
      return const DistributorOrderSettings();
    }

    try {
      final doc = await _db.collection('distributor').doc(distributorId.trim()).get();
      if (!doc.exists) return const DistributorOrderSettings();
      return DistributorOrderSettings.fromMap(doc.data());
    } catch (e) {
      debugPrint('fetchSettings error: $e');
      return const DistributorOrderSettings();
    }
  }

  /// Save / Update distributor settings in Firestore document `/distributor/{distributorId}`.
  static Future<void> updateSettings({
    required String distributorId,
    required DistributorOrderSettings settings,
  }) async {
    if (distributorId.trim().isEmpty) {
      throw Exception('Distributor ID is required to save settings.');
    }

    try {
      await _db
          .collection('distributor')
          .doc(distributorId.trim())
          .set(settings.toMap(), SetOptions(merge: true));
      debugPrint('Distributor settings updated for $distributorId');
    } catch (e) {
      debugPrint('updateSettings error: $e');
      rethrow;
    }
  }

  /// Checks whether current time falls within distributor's ordering window.
  static ({bool isOpen, String timeRangeText, String message}) isWithinOrderingHours(
    DistributorOrderSettings settings, [
    DateTime? checkTime,
  ]) {
    final time = checkTime ?? DateTime.now();
    final timeRange = '${settings.startTimeFormatted} to ${settings.endTimeFormatted}';

    if (!settings.orderTimingEnabled) {
      return (
        isOpen: true,
        timeRangeText: timeRange,
        message: 'Ordering is Open (24/7)',
      );
    }

    // Check active day of week (1 = Monday, 7 = Sunday)
    if (!settings.activeDays.contains(time.weekday)) {
      return (
        isOpen: false,
        timeRangeText: timeRange,
        message: 'Ordering is closed today',
      );
    }

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = settings.startHour * 60 + settings.startMinute;
    final endMinutes = settings.endHour * 60 + settings.endMinute;

    bool isOpen = false;
    if (startMinutes <= endMinutes) {
      // Standard daytime window (e.g. 11:00 AM [660] to 08:00 PM [1200])
      isOpen = currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight window (e.g. 08:00 PM [1200] to 06:00 AM [360] next morning)
      isOpen = currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }

    final msg = isOpen
        ? 'Ordering Open (${settings.startTimeFormatted} – ${settings.endTimeFormatted})'
        : 'Ordering Closed. Orders accepted between ${settings.startTimeFormatted} and ${settings.endTimeFormatted}';

    return (
      isOpen: isOpen,
      timeRangeText: timeRange,
      message: msg,
    );
  }

  /// Evaluates both time window and pending payments to determine if a shop can place orders.
  static OrderingEligibilityResult checkEligibility({
    required ShopProfile? shopProfile,
    required DistributorOrderSettings settings,
    List<OrderModel>? shopOrders,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();

    // 1. Check Ordering Time Window
    final timeCheck = isWithinOrderingHours(settings, now);
    if (!timeCheck.isOpen) {
      final customMsg = settings.customClosedNotice.isNotEmpty
          ? settings.customClosedNotice
          : 'Ordering is closed. Daily order window is ${settings.startTimeFormatted} to ${settings.endTimeFormatted}.';

      return OrderingEligibilityResult(
        canOrder: false,
        isTimeBlocked: true,
        isPaymentBlocked: false,
        statusMessage: customMsg,
        timeWindowString: timeCheck.timeRangeText,
      );
    }

    // 2. Check Pending Payment & Unpaid Bills
    if (settings.blockOnPendingPayment && shopProfile != null) {
      double pendingAmount = shopProfile.outstanding;

      // Also compute from unpaid orders if available and outstanding is not recorded yet
      if (pendingAmount <= settings.maxPendingTolerance && shopOrders != null && shopOrders.isNotEmpty) {
        final unpaidSum = shopOrders
            .where((o) =>
                o.paymentStatus.toLowerCase() == 'pending' &&
                o.status.toLowerCase() != 'rejected' &&
                o.status.toLowerCase() != 'cancelled')
            .fold<double>(0.0, (acc, o) => acc + o.totalAmount);
        if (unpaidSum > pendingAmount) {
          pendingAmount = unpaidSum;
        }
      }

      if (pendingAmount > settings.maxPendingTolerance) {
        final formattedPending = pendingAmount.toStringAsFixed(
          pendingAmount % 1 == 0 ? 0 : 2,
        );

        return OrderingEligibilityResult(
          canOrder: false,
          isTimeBlocked: false,
          isPaymentBlocked: true,
          statusMessage:
              'Previous payment pending (₹$formattedPending). Please clear your pending bills to place new orders.',
          timeWindowString: timeCheck.timeRangeText,
          pendingAmount: pendingAmount,
        );
      }
    }

    return OrderingEligibilityResult(
      canOrder: true,
      isTimeBlocked: false,
      isPaymentBlocked: false,
      statusMessage: 'Ordering is Open',
      timeWindowString: timeCheck.timeRangeText,
    );
  }
}
