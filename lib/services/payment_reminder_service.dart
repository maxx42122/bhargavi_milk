import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentReminderModel {
  final String id;
  final String distributorId;
  final String distributorName;
  final String distributorPhone;
  final String shopId; // 'all' or specific shopUid
  final String shopName;
  final double amount;
  final int pendingOrdersCount;
  final String title;
  final String message;
  final bool active;
  final DateTime? createdAt;
  final List<String> dismissedBy;

  const PaymentReminderModel({
    required this.id,
    required this.distributorId,
    this.distributorName = '',
    this.distributorPhone = '',
    this.shopId = 'all',
    this.shopName = '',
    this.amount = 0.0,
    this.pendingOrdersCount = 0,
    this.title = 'Payment Due Reminder',
    required this.message,
    this.active = true,
    this.createdAt,
    this.dismissedBy = const [],
  });

  factory PaymentReminderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String distributorId,
  ) {
    final data = doc.data() ?? {};
    final amtRaw = data['amount'];
    final double amount = (amtRaw is num)
        ? amtRaw.toDouble()
        : (double.tryParse(amtRaw?.toString() ?? '0') ?? 0.0);

    final cntRaw = data['pendingOrdersCount'] ?? data['ordersCount'];
    final int cnt = (cntRaw is num)
        ? cntRaw.toInt()
        : (int.tryParse(cntRaw?.toString() ?? '0') ?? 0);

    final dismissedRaw = data['dismissedBy'] as List<dynamic>? ?? [];
    final dismissedBy = dismissedRaw.map((e) => e.toString()).toList();

    return PaymentReminderModel(
      id: doc.id,
      distributorId: (data['distributorId'] ?? distributorId).toString(),
      distributorName: (data['distributorName'] ?? '').toString(),
      distributorPhone: (data['distributorPhone'] ?? '').toString(),
      shopId: (data['shopId'] ?? 'all').toString(),
      shopName: (data['shopName'] ?? '').toString(),
      amount: amount,
      pendingOrdersCount: cnt,
      title: (data['title'] ?? 'Payment Due Reminder').toString(),
      message: (data['message'] ?? '').toString(),
      active: data['active'] == true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      dismissedBy: dismissedBy,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorId': distributorId,
      'distributorName': distributorName,
      'distributorPhone': distributorPhone,
      'shopId': shopId,
      'shopName': shopName,
      'amount': amount,
      'pendingOrdersCount': pendingOrdersCount,
      'title': title,
      'message': message,
      'active': active,
      'dismissedBy': dismissedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class PaymentReminderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Global reminder document for all shops under a distributor:
  /// `/distributor/{distributorId}/payment_reminders/global`
  static DocumentReference<Map<String, dynamic>> _globalReminderDoc(
    String distributorId,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('payment_reminders')
        .doc('global');
  }

  /// Shop-specific reminder document:
  /// `/distributor/{distributorId}/shops/{shopUid}/payment_reminders/latest`
  static DocumentReference<Map<String, dynamic>> _shopReminderDoc(
    String distributorId,
    String shopUid,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .doc(shopUid)
        .collection('payment_reminders')
        .doc('latest');
  }

  /// Send broadcast payment reminder to all pending shops
  static Future<void> sendReminderToAll({
    required String distributorId,
    required String distributorName,
    String distributorPhone = '',
    required double totalAmount,
    required int pendingShopsCount,
    required String message,
    String title = 'Payment Due Reminder',
  }) async {
    if (distributorId.isEmpty) return;

    final docRef = _globalReminderDoc(distributorId);
    final data = {
      'distributorId': distributorId,
      'distributorName': distributorName.trim(),
      'distributorPhone': distributorPhone.trim(),
      'shopId': 'all',
      'shopName': 'All Pending Shops',
      'amount': totalAmount,
      'pendingOrdersCount': pendingShopsCount,
      'title': title.trim(),
      'message': message.trim(),
      'active': true,
      'dismissedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));

    // Also log to history (non-blocking)
    try {
      await _db
          .collection('distributor')
          .doc(distributorId)
          .collection('payment_reminders_history')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('History logging note: $e');
    }
  }

  /// Send payment reminder specifically to one shop
  static Future<void> sendReminderToShop({
    required String distributorId,
    required String shopUid,
    required String shopName,
    required String distributorName,
    String distributorPhone = '',
    required double amount,
    int pendingOrdersCount = 1,
    required String message,
    String title = 'Payment Due Reminder',
  }) async {
    if (distributorId.isEmpty || shopUid.isEmpty) return;

    final docRef = _shopReminderDoc(distributorId, shopUid);
    final data = {
      'distributorId': distributorId,
      'shopId': shopUid,
      'shopName': shopName.trim(),
      'distributorName': distributorName.trim(),
      'distributorPhone': distributorPhone.trim(),
      'amount': amount,
      'pendingOrdersCount': pendingOrdersCount,
      'title': title.trim(),
      'message': message.trim(),
      'active': true,
      'dismissedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));

    // Also log to history (non-blocking)
    try {
      await _db
          .collection('distributor')
          .doc(distributorId)
          .collection('payment_reminders_history')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('History logging note: $e');
    }
  }

  /// Real-time stream of the active payment reminder for a specific shop.
  /// Checks shop-specific reminder first; if none, checks global reminder.
  static Stream<PaymentReminderModel?> streamShopPaymentReminder({
    required String distributorId,
    required String shopUid,
  }) {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      return Stream.value(null);
    }

    // Stream the shop-specific reminder
    return _shopReminderDoc(distributorId, shopUid)
        .snapshots()
        .asyncMap((shopDoc) async {
      if (shopDoc.exists && shopDoc.data() != null) {
        final model =
            PaymentReminderModel.fromFirestore(shopDoc, distributorId);
        if (model.active && !model.dismissedBy.contains(shopUid)) {
          return model;
        }
      }

      // Check global reminder
      try {
        final globalDoc = await _globalReminderDoc(distributorId).get();
        if (globalDoc.exists && globalDoc.data() != null) {
          final globalModel =
              PaymentReminderModel.fromFirestore(globalDoc, distributorId);
          if (globalModel.active &&
              !globalModel.dismissedBy.contains(shopUid)) {
            return globalModel;
          }
        }
      } catch (e) {
        debugPrint('Error reading global payment reminder: $e');
      }

      return null;
    }).handleError((error) {
      debugPrint('streamShopPaymentReminder error: $error');
      return null;
    });
  }

  /// Dismiss the reminder for the shop so it won't pop up again
  static Future<void> dismissReminderForShop({
    required String distributorId,
    required String shopUid,
    required PaymentReminderModel reminder,
  }) async {
    if (distributorId.isEmpty || shopUid.isEmpty) return;

    try {
      if (reminder.shopId == shopUid) {
        // Shop-specific reminder: deactivate and mark dismissed
        await _shopReminderDoc(distributorId, shopUid).set({
          'active': false,
          'dismissedBy': FieldValue.arrayUnion([shopUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Global reminder: add shopUid to dismissedBy list
        await _globalReminderDoc(distributorId).set({
          'dismissedBy': FieldValue.arrayUnion([shopUid]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('dismissReminderForShop error: $e');
    }
  }
}
