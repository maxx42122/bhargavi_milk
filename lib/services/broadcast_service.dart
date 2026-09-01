import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BroadcastModel {
  final String id;
  final String distributorId;
  final String message;
  final String title;
  final String tag; // e.g. 'Notice', 'Urgent', 'Stock', 'Delivery', 'Offer'
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BroadcastModel({
    required this.id,
    required this.distributorId,
    required this.message,
    this.title = '',
    this.tag = 'Notice',
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BroadcastModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String distributorId,
  ) {
    final data = doc.data() ?? {};
    return BroadcastModel(
      id: doc.id,
      distributorId:
          (data['distributorId'] ?? distributorId).toString().trim(),
      message: (data['message'] ?? '').toString().trim(),
      title: (data['title'] ?? '').toString().trim(),
      tag: (data['tag'] ?? 'Notice').toString().trim(),
      active: data['active'] == true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorId': distributorId,
      'message': message.trim(),
      'title': title.trim(),
      'tag': tag.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class BroadcastService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _broadcastDoc(
    String distributorId,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('broadcasts')
        .doc('current');
  }

  /// Real-time stream of the current broadcast for a distributor.
  static Stream<BroadcastModel?> streamCurrentBroadcast(String distributorId) {
    if (distributorId.isEmpty) {
      return Stream.value(null);
    }
    return _broadcastDoc(distributorId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return BroadcastModel.fromFirestore(doc, distributorId);
        })
        .handleError((error) {
          debugPrint('streamCurrentBroadcast error: $error');
          return null;
        });
  }

  /// One-time fetch of current broadcast.
  static Future<BroadcastModel?> fetchCurrentBroadcast(
    String distributorId,
  ) async {
    if (distributorId.isEmpty) return null;
    try {
      final doc = await _broadcastDoc(distributorId).get();
      if (!doc.exists || doc.data() == null) return null;
      return BroadcastModel.fromFirestore(doc, distributorId);
    } catch (e) {
      debugPrint('fetchCurrentBroadcast error: $e');
      return null;
    }
  }

  /// Sends or updates active broadcast message for all shops under this distributor.
  static Future<void> sendBroadcast({
    required String distributorId,
    required String message,
    String title = '',
    String tag = 'Notice',
    bool active = true,
  }) async {
    if (distributorId.isEmpty || message.trim().isEmpty) return;

    try {
      final docRef = _broadcastDoc(distributorId);
      final snapshot = await docRef.get();

      final data = {
        'distributorId': distributorId,
        'message': message.trim(),
        'title': title.trim(),
        'tag': tag.trim(),
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      } else {
        await docRef.set(data, SetOptions(merge: true));
      }

      // Also log to broadcasts history collection
      await _db
          .collection('distributor')
          .doc(distributorId)
          .collection('broadcast_history')
          .add({
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('sendBroadcast error: $e');
      rethrow;
    }
  }

  /// Clears/deactivates the broadcast message.
  static Future<void> clearBroadcast(String distributorId) async {
    if (distributorId.isEmpty) return;
    try {
      await _broadcastDoc(distributorId).set({
        'active': false,
        'message': '',
        'title': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('clearBroadcast error: $e');
      rethrow;
    }
  }
}
