import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class BroadcastModel {
  final String id;
  final String distributorId;
  final String message;
  final String title;
  final String tag; // e.g. 'Notice', 'Urgent', 'Stock', 'Delivery', 'Offer'
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const BroadcastModel({
    required this.id,
    required this.distributorId,
    required this.message,
    this.title = '',
    this.tag = 'Notice',
    this.active = true,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
  });

  factory BroadcastModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String distributorId,
  ) {
    final data = doc.data() ?? {};
    final createdAt = (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final updatedAt = (data['updatedAt'] is Timestamp)
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;

    DateTime? expiresAt;
    if (data['expiresAt'] is Timestamp) {
      expiresAt = (data['expiresAt'] as Timestamp).toDate();
    } else if (createdAt != null) {
      expiresAt = createdAt.add(const Duration(hours: 24));
    } else if (updatedAt != null) {
      expiresAt = updatedAt.add(const Duration(hours: 24));
    }

    return BroadcastModel(
      id: doc.id,
      distributorId:
          (data['distributorId'] ?? distributorId).toString().trim(),
      message: (data['message'] ?? '').toString().trim(),
      title: (data['title'] ?? '').toString().trim(),
      tag: (data['tag'] ?? 'Notice').toString().trim(),
      active: data['active'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expiresAt: expiresAt,
    );
  }

  /// Calculates the definitive expiration timestamp (defaults to 24 hours after creation/update).
  DateTime? get effectiveExpiresAt {
    if (expiresAt != null) return expiresAt;
    if (createdAt != null) return createdAt!.add(const Duration(hours: 24));
    if (updatedAt != null) return updatedAt!.add(const Duration(hours: 24));
    return null;
  }

  /// Returns true if more than 24 hours have passed since the broadcast was posted.
  bool get isExpired {
    final exp = effectiveExpiresAt;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  /// Remaining duration before auto-deletion/expiration.
  Duration? get timeRemaining {
    final exp = effectiveExpiresAt;
    if (exp == null) return null;
    final diff = exp.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// User-friendly formatted remaining time string (e.g., '23h 45m', '42m', '< 1m', 'Expired').
  String get timeRemainingFormatted {
    final tr = timeRemaining;
    if (tr == null || isExpired || tr == Duration.zero) return 'Expired';
    final hours = tr.inHours;
    final minutes = tr.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '< 1m';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorId': distributorId,
      'message': message.trim(),
      'title': title.trim(),
      'tag': tag.trim(),
      'active': active,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
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

  /// Real-time stream of the current active broadcast for a distributor.
  /// Automatically filters out expired broadcasts (> 24 hours old).
  static Stream<BroadcastModel?> streamCurrentBroadcast(String distributorId) {
    if (distributorId.isEmpty) {
      return Stream.value(null);
    }
    return _broadcastDoc(distributorId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          final model = BroadcastModel.fromFirestore(doc, distributorId);

          if (!model.active || model.message.isEmpty || model.isExpired) {
            // If expired but still marked active in DB, let the distributor auto-clear it in Firestore
            if (model.active && model.isExpired && AuthService.currentUser?.uid == distributorId) {
              clearBroadcast(distributorId).catchError((e) {
                debugPrint('Auto-clear expired broadcast error: $e');
              });
            }
            return null;
          }
          return model;
        })
        .handleError((error) {
          debugPrint('streamCurrentBroadcast error: $error');
          return null;
        });
  }

  /// One-time fetch of current broadcast with 24-hour expiration check.
  static Future<BroadcastModel?> fetchCurrentBroadcast(
    String distributorId,
  ) async {
    if (distributorId.isEmpty) return null;
    try {
      final doc = await _broadcastDoc(distributorId).get();
      if (!doc.exists || doc.data() == null) return null;
      final model = BroadcastModel.fromFirestore(doc, distributorId);
      if (!model.active || model.message.isEmpty || model.isExpired) {
        if (model.active && model.isExpired && AuthService.currentUser?.uid == distributorId) {
          clearBroadcast(distributorId).catchError((e) {
            debugPrint('Auto-clear expired broadcast error: $e');
          });
        }
        return null;
      }
      return model;
    } catch (e) {
      debugPrint('fetchCurrentBroadcast error: $e');
      return null;
    }
  }

  /// Sends or updates active broadcast message for all shops under this distributor.
  /// Sets expiration to exactly 24 hours from the send timestamp.
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
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final data = {
        'distributorId': distributorId,
        'message': message.trim(),
        'title': title.trim(),
        'tag': tag.trim(),
        'active': active,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists || snapshot.data()?['active'] != true) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));

      // Also log to broadcasts history collection with 24-hour expiration
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

  /// Clears/deactivates and resets the current broadcast message.
  static Future<void> clearBroadcast(String distributorId) async {
    if (distributorId.isEmpty) return;
    try {
      await _broadcastDoc(distributorId).set({
        'active': false,
        'message': '',
        'title': '',
        'expiresAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('clearBroadcast error: $e');
      rethrow;
    }
  }
}
