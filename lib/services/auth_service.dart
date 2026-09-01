import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Roles stored in Firestore.
enum UserRole { distributor, shop }

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Used to prevent AuthGate from resolving the user
  /// while registration is still writing Firestore.
  static bool isRegistering = false;

  // ============================================================
  // CURRENT USER
  // ============================================================

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================
  // DISTRIBUTOR REGISTRATION
  // ============================================================

  /// Creates:
  ///
  /// Firebase Authentication account
  /// +
  /// /distributor/{uid}
  ///
  static Future<UserCredential> registerDistributor({
    required String email,
    required String password,
    required String companyName,
    required String distributorName,
    required String address,
    required String mobile,
  }) async {
    isRegistering = true;

    try {
      // 1. Create Firebase Authentication account.
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = cred.user;

      if (user == null) {
        throw Exception('Unable to create distributor account.');
      }

      // 2. Save display name in Firebase Auth.
      await user.updateDisplayName(distributorName.trim());

      // 3. Create distributor Firestore document.
      await _db.collection('distributor').doc(user.uid).set({
        'uid': user.uid,
        'companyName': companyName.trim(),
        'distributorName': distributorName.trim(),
        'address': address.trim(),
        'mobile': mobile.trim(),
        'email': email.trim(),
        'role': 'distributor',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred;
    } catch (e) {
      rethrow;
    } finally {
      isRegistering = false;
    }
  }

  // ============================================================
  // SHOP REGISTRATION
  // ============================================================

  /// Creates:
  ///
  /// /distributor/{distributorId}/shops/{shopUid}
  ///
  /// and
  ///
  /// /shop_accounts/{shopUid}
  ///
  /// Shop starts with status = "pending".
  static Future<UserCredential> registerShop({
    required String email,
    required String password,
    required String shopName,
    required String ownerName,
    required String mobile,
    required String address,
    required String distributorId,
  }) async {
    isRegistering = true;

    try {
      // --------------------------------------------------------
      // 1. Create Firebase Auth account.
      // --------------------------------------------------------

      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = cred.user;

      if (user == null) {
        throw Exception('Unable to create shop account.');
      }

      // --------------------------------------------------------
      // 2. Save owner name in Firebase Auth.
      // --------------------------------------------------------

      await user.updateDisplayName(ownerName.trim());

      // --------------------------------------------------------
      // 3. Shop data.
      // --------------------------------------------------------

      final Map<String, dynamic> shopData = {
        'uid': user.uid,
        'shopName': shopName.trim(),
        'ownerName': ownerName.trim(),
        'mobile': mobile.trim(),
        'address': address.trim(),
        'email': email.trim(),

        // Selected distributor.
        'distributorId': distributorId,

        // User role.
        'role': 'shop',

        // IMPORTANT:
        // Shop cannot access the app until distributor approves.
        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),

        // Shop account information.
        'totalOrders': 0,
        'totalPurchase': 0.0,
        'paidAmount': 0.0,
        'outstanding': 0.0,
      };

      // --------------------------------------------------------
      // 4. Save shop under selected distributor.
      //
      // /distributor/{distributorId}/shops/{shopUid}
      // --------------------------------------------------------

      await _db
          .collection('distributor')
          .doc(distributorId)
          .collection('shops')
          .doc(user.uid)
          .set(shopData);

      // --------------------------------------------------------
      // 5. Save top-level shop lookup.
      //
      // /shop_accounts/{shopUid}
      //
      // This makes login/role checking easy.
      // --------------------------------------------------------

      await _db.collection('shop_accounts').doc(user.uid).set({
        'uid': user.uid,
        'distributorId': distributorId,
        'status': 'pending',
        'email': email.trim(),
        'role': 'shop',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred;
    } catch (e) {
      rethrow;
    } finally {
      isRegistering = false;
    }
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  static Future<({UserRole role, String distributorId, String status})>
  loginWithEmail({required String email, required String password}) async {
    final UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = cred.user;

    if (user == null) {
      throw Exception('Unable to sign in.');
    }

    return _resolveRole(user.uid);
  }

  // ============================================================
  // GOOGLE SIGN-IN
  // ============================================================

  /// Google sign-in is intended for distributors.
  static Future<({UserCredential cred, bool isNew})> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in cancelled.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential cred = await _auth.signInWithCredential(credential);

    final bool isNew = cred.additionalUserInfo?.isNewUser ?? false;

    return (cred: cred, isNew: isNew);
  }

  // ============================================================
  // RESOLVE USER ROLE
  // ============================================================

  static Future<({UserRole role, String distributorId, String status})>
  _resolveRole(String uid) async {
    // ----------------------------------------------------------
    // 1. Check distributor.
    //
    // /distributor/{uid}
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> distributorDoc = await _db
        .collection('distributor')
        .doc(uid)
        .get();

    if (distributorDoc.exists) {
      return (role: UserRole.distributor, distributorId: uid, status: 'active');
    }

    // ----------------------------------------------------------
    // 2. Check shop account.
    //
    // /shop_accounts/{uid}
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> shopDoc = await _db
        .collection('shop_accounts')
        .doc(uid)
        .get();

    if (shopDoc.exists) {
      final Map<String, dynamic>? data = shopDoc.data();

      if (data == null) {
        throw Exception('Shop account data is empty.');
      }

      final String? distributorId = data['distributorId'] as String?;

      String status = (data['status'] as String? ?? 'pending').trim().toLowerCase();

      if (distributorId == null || distributorId.isEmpty) {
        throw Exception('Distributor information not found.');
      }

      // Check authoritative status from /distributor/{distributorId}/shops/{uid}
      try {
        final distShopDoc = await _db
            .collection('distributor')
            .doc(distributorId)
            .collection('shops')
            .doc(uid)
            .get();

        if (distShopDoc.exists) {
          final liveStatus = (distShopDoc.data()?['status'] as String?)?.trim().toLowerCase();
          if (liveStatus != null && liveStatus.isNotEmpty) {
            status = liveStatus;
          }
        }
      } catch (e) {
        debugPrint('Could not check distributor shop doc status: $e');
      }

      return (
        role: UserRole.shop,
        distributorId: distributorId,
        status: status,
      );
    }

    // ----------------------------------------------------------
    // 3. No Firestore account found.
    // ----------------------------------------------------------

    throw Exception('User account not found. Please register first.');
  }

  // ============================================================
  // PUBLIC ROLE RESOLVER
  // ============================================================

  static Future<({UserRole role, String distributorId, String status})>
  resolveCurrentUserRole() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Not signed in.');
    }

    return _resolveRole(user.uid);
  }

  // ============================================================
  // DISTRIBUTOR APPROVE / REJECT SHOP
  // ============================================================

  /// Distributor can set:
  ///
  /// pending
  /// active
  /// rejected
  ///
  static Future<void> updateShopStatus({
    required String distributorId,
    required String shopUid,
    required String status,
  }) async {
    // Only these statuses are allowed.
    const List<String> allowedStatuses = ['pending', 'active', 'rejected'];

    final normStatus = status.trim().toLowerCase();
    if (!allowedStatuses.contains(normStatus)) {
      throw Exception('Invalid shop status: $status');
    }

    // ----------------------------------------------------------
    // Update shop document.
    //
    // /distributor/{distributorId}/shops/{shopUid}
    // ----------------------------------------------------------

    await _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .doc(shopUid)
        .update({'status': normStatus, 'updatedAt': FieldValue.serverTimestamp()});

    // ----------------------------------------------------------
    // Update shop login lookup.
    //
    // /shop_accounts/{shopUid}
    // ----------------------------------------------------------

    try {
      await _db.collection('shop_accounts').doc(shopUid).update({
        'status': normStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('shop_accounts update notice: $e');
    }
  }

  // ============================================================
  // FETCH ALL DISTRIBUTORS
  // ============================================================

  /// Used by ShopRegisterScreen.
  ///
  /// Reads:
  ///
  /// /distributor
  ///
  static Future<List<Map<String, dynamic>>> fetchDistributors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('distributor')
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();

        final companyName = (data['companyName'] ??
                data['businessName'] ??
                data['shopName'] ??
                data['company'] ??
                '')
            .toString()
            .trim();

        final distributorName = (data['distributorName'] ??
                data['name'] ??
                data['ownerName'] ??
                data['displayName'] ??
                data['fullName'] ??
                '')
            .toString()
            .trim();

        final mobile = (data['mobile'] ??
                data['phone'] ??
                data['contact'] ??
                data['phoneNumber'] ??
                '')
            .toString()
            .trim();

        final email = (data['email'] ?? '').toString().trim();
        final address = (data['address'] ?? data['city'] ?? data['location'] ?? '')
            .toString()
            .trim();

        return {
          'id': doc.id,
          'companyName': companyName,
          'distributorName': distributorName,
          'mobile': mobile,
          'email': email,
          'address': address,
        };
      }).toList();

      list.sort((a, b) {
        final aName = a['companyName']!.isNotEmpty
            ? a['companyName']!
            : (a['distributorName']!.isNotEmpty
                ? a['distributorName']!
                : a['id']!);
        final bName = b['companyName']!.isNotEmpty
            ? b['companyName']!
            : (b['distributorName']!.isNotEmpty
                ? b['distributorName']!
                : b['id']!);
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

      return list;
    } catch (e) {
      debugPrint('fetchDistributors error: $e');
      rethrow;
    }
  }

  // ============================================================
  // GET SINGLE DISTRIBUTOR
  // ============================================================

  /// Gets one distributor.
  ///
  /// Example:
  ///
  /// /distributor/oP6wPSJUabgAWN0eNs7pAsAIsoY2
  ///
  static Future<Map<String, dynamic>?> getDistributor(
    String distributorId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('distributor')
        .doc(distributorId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...doc.data()!};
  }

  // ============================================================
  // DISTRIBUTOR PROFILE STREAM
  // ============================================================

  static Stream<DocumentSnapshot<Map<String, dynamic>>> distributorStream(
    String distributorId,
  ) {
    return _db.collection('distributor').doc(distributorId).snapshots();
  }

  // ============================================================
  // SHOP STREAM
  // ============================================================

  /// Streams shops belonging to a distributor.
  ///
  /// Example:
  ///
  /// distributor/{distributorId}/shops
  ///
  static Stream<QuerySnapshot<Map<String, dynamic>>> shopsStream({
    required String distributorId,
    required String status,
  }) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  // ============================================================
  // GET SHOP
  // ============================================================

  static Future<Map<String, dynamic>?> getShop({
    required String distributorId,
    required String shopUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('distributor')
        .doc(distributorId)
        .collection('shops')
        .doc(shopUid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return {'id': doc.id, ...doc.data()!};
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors.
    }

    await _auth.signOut();
  }
  ///////////////////////////////sendPasswordResetEmail///////////
  ///////////////////////
  ////////////

  static Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
