import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PaymentRecord {
  final String id;
  final String distributorId;
  final String shopId;
  final String shopName;
  final String shopOwner;
  final String shopMobile;
  final String orderId;
  final String orderNumber;
  final double amount;
  final String paymentMethod; // 'upi', 'cod', 'cash', 'bank', 'credit'
  final String paymentStatus; // 'Paid', 'Pending', 'Failed'
  final String transactionId;
  final String? razorpayPaymentId;
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String? notes;
  final DateTime? createdAt;

  const PaymentRecord({
    required this.id,
    required this.distributorId,
    required this.shopId,
    required this.shopName,
    this.shopOwner = '',
    this.shopMobile = '',
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.paymentMethod,
    this.paymentStatus = 'Paid',
    required this.transactionId,
    this.razorpayPaymentId,
    this.razorpayOrderId,
    this.razorpaySignature,
    this.notes,
    this.createdAt,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final amtRaw = data['amount'];
    final double amount = (amtRaw is num)
        ? amtRaw.toDouble()
        : (double.tryParse(amtRaw?.toString() ?? '0') ?? 0.0);

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return PaymentRecord(
      id: doc.id,
      distributorId: (data['distributorId'] ?? '').toString(),
      shopId: (data['shopId'] ?? '').toString(),
      shopName: (data['shopName'] ?? 'Shop').toString(),
      shopOwner: (data['shopOwner'] ?? '').toString(),
      shopMobile: (data['shopMobile'] ?? '').toString(),
      orderId: (data['orderId'] ?? '').toString(),
      orderNumber: (data['orderNumber'] ?? '').toString(),
      amount: amount,
      paymentMethod: (data['paymentMethod'] ?? 'upi').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Paid').toString(),
      transactionId: (data['transactionId'] ?? doc.id).toString(),
      razorpayPaymentId: data['razorpayPaymentId']?.toString(),
      razorpayOrderId: data['razorpayOrderId']?.toString(),
      razorpaySignature: data['razorpaySignature']?.toString(),
      notes: data['notes']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'distributorId': distributorId,
      'shopId': shopId,
      'shopName': shopName,
      'shopOwner': shopOwner,
      'shopMobile': shopMobile,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
      if (notes != null) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class PaymentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Helper getter for payments collection:
  /// `/distributor/{distributorId}/payments`
  static CollectionReference<Map<String, dynamic>> _paymentsRef(
    String distributorId,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('payments');
  }

  /// Records a completed payment in Firestore, updates corresponding order(s)
  /// to 'Paid', and updates shop ledger (paidAmount & outstanding).
  static Future<String> recordPayment({
    required String distributorId,
    required String shopId,
    required String shopName,
    String shopOwner = '',
    String shopMobile = '',
    required List<String> orderIds,
    required List<String> orderNumbers,
    required double amount,
    required String paymentMethod,
    String paymentStatus = 'Paid',
    String? transactionId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
    String? notes,
  }) async {
    String resolvedDistributorId = distributorId.trim();
    String resolvedShopId = shopId.trim();

    // 1. Fallback resolution for shopId if empty
    if (resolvedShopId.isEmpty) {
      resolvedShopId = FirebaseAuth.instance.currentUser?.uid ?? '';
    }

    // 2. Fallback resolution for distributorId if empty
    if (resolvedDistributorId.isEmpty && resolvedShopId.isNotEmpty) {
      try {
        final shopDoc = await _db.collection('shop_accounts').doc(resolvedShopId).get();
        if (shopDoc.exists) {
          resolvedDistributorId = (shopDoc.data()?['distributorId'] ?? '').toString().trim();
        }
      } catch (_) {}
    }

    final txnId = transactionId ??
        'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}';

    // 3. Update Order Document(s) to 'Paid'
    // We update each order explicitly to ensure the payment status is always persisted
    for (final orderId in orderIds) {
      if (orderId.trim().isEmpty) continue;

      // If distributorId was empty, try to find the order document across distributors
      String distIdForOrder = resolvedDistributorId;
      if (distIdForOrder.isEmpty) {
        try {
          final groupQuery = await _db.collectionGroup('orders').where('id', isEqualTo: orderId.trim()).get();
          if (groupQuery.docs.isNotEmpty) {
            distIdForOrder = (groupQuery.docs.first.data()['distributorId'] ?? '').toString().trim();
            if (resolvedDistributorId.isEmpty) {
              resolvedDistributorId = distIdForOrder;
            }
          }
        } catch (_) {}
      }

      if (distIdForOrder.isNotEmpty) {
        try {
          final orderDocRef = _db
              .collection('distributor')
              .doc(distIdForOrder)
              .collection('orders')
              .doc(orderId.trim());

          await orderDocRef.set({
            'paymentStatus': 'Paid',
            'paymentMethod': paymentMethod,
            if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty)
              'razorpayPaymentId': razorpayPaymentId,
            if (razorpayOrderId != null && razorpayOrderId.isNotEmpty)
              'razorpayOrderId': razorpayOrderId,
            if (razorpaySignature != null && razorpaySignature.isNotEmpty)
              'razorpaySignature': razorpaySignature,
            'paidAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          debugPrint('Order $orderId marked as Paid under distributor $distIdForOrder');
        } catch (e) {
          debugPrint('Error updating order $orderId: $e');
        }
      }
    }

    // 4. Write Payment Record Document
    if (resolvedDistributorId.isNotEmpty) {
      try {
        final paymentDocRef = _paymentsRef(resolvedDistributorId).doc();
        final paymentId = paymentDocRef.id;

        final paymentData = <String, dynamic>{
          'id': paymentId,
          'distributorId': resolvedDistributorId,
          'shopId': resolvedShopId,
          'shopName': shopName,
          'shopOwner': shopOwner,
          'shopMobile': shopMobile,
          'orderId': orderIds.isNotEmpty ? orderIds.first : '',
          'orderIds': orderIds,
          'orderNumber': orderNumbers.isNotEmpty ? orderNumbers.join(', ') : '',
          'orderNumbers': orderNumbers,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentStatus,
          'transactionId': txnId,
          if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty)
            'razorpayPaymentId': razorpayPaymentId,
          if (razorpayOrderId != null && razorpayOrderId.isNotEmpty)
            'razorpayOrderId': razorpayOrderId,
          if (razorpaySignature != null && razorpaySignature.isNotEmpty)
            'razorpaySignature': razorpaySignature,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await paymentDocRef.set(paymentData);
        debugPrint('Payment record $paymentId created for $txnId');
      } catch (e) {
        debugPrint('Payment record save notice: $e');
      }
    }

    // 5. Update Shop Profile Ledger
    if (resolvedDistributorId.isNotEmpty && resolvedShopId.isNotEmpty) {
      try {
        final shopDocRef = _db
            .collection('distributor')
            .doc(resolvedDistributorId)
            .collection('shops')
            .doc(resolvedShopId);

        await shopDocRef.set(
          {
            'paidAmount': FieldValue.increment(amount),
            'outstanding': FieldValue.increment(-amount),
            'lastPaymentAt': FieldValue.serverTimestamp(),
            'lastPaymentAmount': amount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Shop ledger update note: $e');
      }
    }

    // 6. Update /shop_accounts/{shopId} ledger if applicable
    if (resolvedShopId.isNotEmpty) {
      try {
        final shopAccRef = _db.collection('shop_accounts').doc(resolvedShopId);
        await shopAccRef.set(
          {
            'paidAmount': FieldValue.increment(amount),
            'outstanding': FieldValue.increment(-amount),
            'lastPaymentAt': FieldValue.serverTimestamp(),
            'lastPaymentAmount': amount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }

    debugPrint('Payment processing completed: $txnId (₹$amount) for shop $resolvedShopId');
    return txnId;
  }

  /// Stream payments for a specific shop
  static Stream<List<PaymentRecord>> streamShopPayments({
    required String distributorId,
    required String shopId,
  }) {
    if (distributorId.isEmpty || shopId.isEmpty) {
      return Stream.value([]);
    }

    return _paymentsRef(distributorId)
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PaymentRecord.fromFirestore(doc))
              .toList();

          list.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

  /// Stream all payments under a distributor
  static Stream<List<PaymentRecord>> streamDistributorPayments(
    String distributorId,
  ) {
    if (distributorId.isEmpty) {
      return Stream.value([]);
    }

    return _paymentsRef(distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentRecord.fromFirestore(doc)).toList());
  }
}
