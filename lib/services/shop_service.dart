import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ShopProfile {
  final String id;
  final String distributorId;
  final String shopName;
  final String ownerName;
  final String mobile;
  final String address;
  final String email;
  final String status; // 'active', 'pending', 'rejected'
  final int totalOrders;
  final double totalPurchase;
  final double paidAmount;
  final double outstanding;
  final DateTime? createdAt;

  const ShopProfile({
    required this.id,
    required this.distributorId,
    required this.shopName,
    required this.ownerName,
    required this.mobile,
    required this.address,
    required this.email,
    this.status = 'pending',
    this.totalOrders = 0,
    this.totalPurchase = 0.0,
    this.paidAmount = 0.0,
    this.outstanding = 0.0,
    this.createdAt,
  });

  factory ShopProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    String? fallbackDistributorId,
  ]) {
    final data = doc.data() ?? {};

    final purchaseRaw = data['totalPurchase'];
    final double purchase = (purchaseRaw is num)
        ? purchaseRaw.toDouble()
        : (double.tryParse(purchaseRaw?.toString() ?? '0') ?? 0.0);

    final paidRaw = data['paidAmount'];
    final double paid = (paidRaw is num)
        ? paidRaw.toDouble()
        : (double.tryParse(paidRaw?.toString() ?? '0') ?? 0.0);

    final outRaw = data['outstanding'];
    final double out = (outRaw is num)
        ? outRaw.toDouble()
        : (double.tryParse(outRaw?.toString() ?? '0') ?? 0.0);

    final ordersRaw = data['totalOrders'];
    final int orders = (ordersRaw is num)
        ? ordersRaw.toInt()
        : (int.tryParse(ordersRaw?.toString() ?? '0') ?? 0);

    return ShopProfile(
      id: doc.id,
      distributorId: (data['distributorId'] ?? fallbackDistributorId ?? '').toString(),
      shopName: (data['shopName'] ?? data['name'] ?? 'My Shop').toString().trim(),
      ownerName: (data['ownerName'] ?? data['contactPerson'] ?? '').toString().trim(),
      mobile: (data['mobile'] ?? data['phone'] ?? '').toString().trim(),
      address: (data['address'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString().trim(),
      status: (data['status'] ?? 'pending').toString().trim(),
      totalOrders: orders,
      totalPurchase: purchase,
      paidAmount: paid,
      outstanding: out,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  ShopProfile copyWith({
    String? shopName,
    String? ownerName,
    String? mobile,
    String? address,
    String? email,
  }) {
    return ShopProfile(
      id: id,
      distributorId: distributorId,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      status: status,
      totalOrders: totalOrders,
      totalPurchase: totalPurchase,
      paidAmount: paidAmount,
      outstanding: outstanding,
      createdAt: createdAt,
    );
  }
}

class ShopService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Real-time stream of the current shop's profile from:
  /// /distributor/{distributorId}/shops/{shopUid}
  static Stream<ShopProfile?> streamShopProfile({
    required String distributorId,
    required String shopUid,
  }) {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      return Stream.value(null);
    }

    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .doc(shopUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ShopProfile.fromFirestore(doc, distributorId);
        });
  }

  /// One-time fetch of shop profile
  static Future<ShopProfile?> fetchShopProfile({
    required String distributorId,
    required String shopUid,
  }) async {
    if (distributorId.isEmpty || shopUid.isEmpty) return null;

    try {
      final doc = await _db
          .collection('distributor')
          .doc(distributorId)
          .collection('shops')
          .doc(shopUid)
          .get();

      if (!doc.exists) return null;
      return ShopProfile.fromFirestore(doc, distributorId);
    } catch (e) {
      debugPrint('fetchShopProfile error: $e');
      return null;
    }
  }

  /// Update shop profile details
  static Future<void> updateShopProfile({
    required String distributorId,
    required String shopUid,
    required String shopName,
    required String ownerName,
    required String mobile,
    required String address,
  }) async {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      throw Exception('Distributor ID and Shop UID are required.');
    }

    final data = {
      'shopName': shopName.trim(),
      'ownerName': ownerName.trim(),
      'mobile': mobile.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Update in /distributor/{distributorId}/shops/{shopUid}
    await _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .doc(shopUid)
        .update(data);
  }

  /// Fetch distributor details (company name, owner name, phone, address)
  static Future<Map<String, String>?> fetchDistributorInfo(
    String distributorId,
  ) async {
    if (distributorId.isEmpty) return null;

    try {
      final doc = await _db.collection('distributor').doc(distributorId).get();
      if (!doc.exists) return null;

      final data = doc.data() ?? {};
      return {
        'id': doc.id,
        'companyName': (data['companyName'] ?? data['name'] ?? 'Dairy Distributor').toString(),
        'distributorName': (data['distributorName'] ?? data['ownerName'] ?? '').toString(),
        'mobile': (data['mobile'] ?? data['phone'] ?? '').toString(),
        'address': (data['address'] ?? '').toString(),
        'email': (data['email'] ?? '').toString(),
      };
    } catch (e) {
      debugPrint('fetchDistributorInfo error: $e');
      return null;
    }
  }

  /// Get current logged in shop UID
  static String? get currentShopUid => FirebaseAuth.instance.currentUser?.uid;
}
