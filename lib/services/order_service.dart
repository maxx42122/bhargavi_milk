import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String name; // backwards-compatible alias
  final String category;
  final String packSize;
  final String unit;
  final double price;
  final int quantity;
  final double subtotal;
  final double totalPrice; // backwards-compatible alias
  final String emoji;

  const OrderItem({
    required this.productId,
    required this.productName,
    String? name,
    this.category = '',
    this.packSize = '',
    this.unit = '',
    required this.price,
    required this.quantity,
    double? subtotal,
    double? totalPrice,
    this.emoji = '🥛',
  })  : name = name ?? productName,
        subtotal = subtotal ?? (totalPrice ?? (price * quantity)),
        totalPrice = totalPrice ?? (subtotal ?? (price * quantity));

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    final priceRaw = data['price'];
    final double price = (priceRaw is num)
        ? priceRaw.toDouble()
        : (double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0);

    final qtyRaw = data['quantity'] ?? data['qty'];
    final int qty = (qtyRaw is num)
        ? qtyRaw.toInt()
        : (int.tryParse(qtyRaw?.toString() ?? '1') ?? 1);

    final subtotalRaw = data['subtotal'] ?? data['totalPrice'];
    final double subtotal = (subtotalRaw is num)
        ? subtotalRaw.toDouble()
        : (price * qty);

    final prodName = (data['productName'] ?? data['name'] ?? 'Product').toString().trim();

    return OrderItem(
      productId: (data['productId'] ?? data['id'] ?? '').toString().trim(),
      productName: prodName,
      name: prodName,
      category: (data['category'] ?? '').toString().trim(),
      packSize: (data['packSize'] ?? '').toString().trim(),
      unit: (data['unit'] ?? '').toString().trim(),
      price: price,
      quantity: qty,
      subtotal: subtotal,
      totalPrice: subtotal,
      emoji: (data['emoji'] ?? '🥛').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'name': name,
      'category': category,
      'packSize': packSize,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
      'totalPrice': totalPrice,
      'emoji': emoji,
    };
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String shopId;
  final String shopName;
  final String shopOwner;
  final String shopMobile;
  final String distributorId;
  final List<OrderItem> items;
  final List<String> products;
  final int totalQuantity;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double totalAmount;
  final double total; // backwards-compatible alias
  final String status; // 'pending', 'confirmed', 'prepared', 'delivered', 'rejected', 'completed'
  final String orderStatus; // backwards-compatible alias
  final String deliveryAddress;
  final String deliveryDate;
  final String deliveryTime;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.shopId,
    required this.shopName,
    this.shopOwner = '',
    this.shopMobile = '',
    required this.distributorId,
    required this.items,
    required this.products,
    required this.totalQuantity,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.totalAmount,
    double? total,
    required this.status,
    String? orderStatus,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.paymentMethod,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  })  : total = total ?? totalAmount,
        orderStatus = orderStatus ?? status;

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => OrderItem.fromMap(m))
        .toList();

    final productsRaw = data['products'] as List<dynamic>? ?? [];
    final products = productsRaw.map((p) => p.toString()).toList();

    final subtotalRaw = data['subtotal'];
    final double subtotal = (subtotalRaw is num)
        ? subtotalRaw.toDouble()
        : (double.tryParse(subtotalRaw?.toString() ?? '0') ?? 0.0);

    final delChargeRaw = data['deliveryCharge'];
    final double deliveryCharge = (delChargeRaw is num)
        ? delChargeRaw.toDouble()
        : (double.tryParse(delChargeRaw?.toString() ?? '0') ?? 0.0);

    final discRaw = data['discount'];
    final double discount = (discRaw is num)
        ? discRaw.toDouble()
        : (double.tryParse(discRaw?.toString() ?? '0') ?? 0.0);

    final totalRaw = data['totalAmount'] ?? data['total'];
    final double totalAmount = (totalRaw is num)
        ? totalRaw.toDouble()
        : (double.tryParse(totalRaw?.toString() ?? '0') ?? 0.0);

    final qtyRaw = data['totalQuantity'] ?? data['quantity'];
    final int totalQuantity = (qtyRaw is num)
        ? qtyRaw.toInt()
        : (int.tryParse(qtyRaw?.toString() ?? '0') ??
            items.fold(0, (acc, i) => acc + i.quantity));

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedAt;
    if (data['updatedAt'] is Timestamp) {
      updatedAt = (data['updatedAt'] as Timestamp).toDate();
    }

    final id = doc.id;
    final orderNumber = (data['orderNumber'] ??
            '#ORD-${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}')
        .toString();

    final statusStr = (data['status'] ?? data['orderStatus'] ?? 'pending')
        .toString()
        .trim();

    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      shopId: (data['shopId'] ?? '').toString(),
      shopName: (data['shopName'] ?? 'Shop').toString(),
      shopOwner: (data['shopOwner'] ?? '').toString(),
      shopMobile: (data['shopMobile'] ?? '').toString(),
      distributorId: (data['distributorId'] ?? '').toString(),
      items: items,
      products: products.isNotEmpty
          ? products
          : items.map((i) => '${i.productName} (${i.packSize})').toList(),
      totalQuantity: totalQuantity,
      subtotal: subtotal,
      deliveryCharge: deliveryCharge,
      discount: discount,
      totalAmount: totalAmount,
      total: totalAmount,
      status: statusStr,
      orderStatus: statusStr,
      deliveryAddress:
          (data['deliveryAddress'] ?? data['address'] ?? '').toString(),
      deliveryDate: (data['deliveryDate'] ?? '').toString(),
      deliveryTime: (data['deliveryTime'] ?? '').toString(),
      paymentMethod: (data['paymentMethod'] ?? 'cash').toString(),
      paymentStatus: (data['paymentStatus'] ?? 'Pending').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'shopId': shopId,
      'shopName': shopName,
      'shopOwner': shopOwner,
      'shopMobile': shopMobile,
      'distributorId': distributorId,
      'items': items.map((i) => i.toMap()).toList(),
      'products': products,
      'totalQuantity': totalQuantity,
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'discount': discount,
      'totalAmount': totalAmount,
      'total': totalAmount,
      'status': status,
      'orderStatus': orderStatus,
      'deliveryAddress': deliveryAddress,
      'deliveryDate': deliveryDate,
      'deliveryTime': deliveryTime,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Helper getter for orders collection under a distributor:
  /// `/distributor/{distributorId}/orders`
  static CollectionReference<Map<String, dynamic>> _ordersRef(
    String distributorId,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('orders');
  }

  /// Places a new order into Firestore at:
  /// `/distributor/{distributorId}/orders/{orderId}`
  ///
  /// Uses current Firebase Auth UID as `shopId`.
  /// Does NOT update the shop document.
  static Future<String> placeOrder({
    required String distributorId,
    String? shopUid,
    required String shopName,
    String shopOwner = '',
    String shopMobile = '',
    required List<OrderItem> items,
    double? subtotal,
    double deliveryCharge = 0.0,
    double discount = 0.0,
    double? totalAmount,
    double? total,
    required String deliveryAddress,
    required String deliveryDate,
    required String deliveryTime,
    required String paymentMethod,
    String paymentStatus = 'Pending',
    String status = 'pending',
    String? orderStatus,
  }) async {
    // 1. Authenticate user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }
    final shopId = user.uid;

    // 2. Validate inputs
    if (distributorId.trim().isEmpty) {
      throw Exception('Distributor ID is required to place an order.');
    }

    if (items.isEmpty) {
      throw Exception('Cannot place an order with an empty cart.');
    }

    for (final item in items) {
      if (item.productId.trim().isEmpty) {
        throw Exception('Each item must have a valid productId.');
      }
      if (item.quantity <= 0) {
        throw Exception('Item quantity must be greater than zero.');
      }
    }

    // 3. Subtotal & Total Amount calculation
    final calculatedSubtotal = items.fold<double>(
      0.0,
      (acc, item) => acc + (item.quantity * item.price),
    );

    final finalSubtotal = subtotal ?? calculatedSubtotal;
    final finalTotal = totalAmount ??
        total ??
        (finalSubtotal + deliveryCharge - discount).clamp(0.0, double.infinity);

    final initialStatus = (orderStatus ?? status).toLowerCase();

    try {
      // 4. Generate new document at /distributor/{distributorId}/orders/{orderId}
      final ordersCollection = _ordersRef(distributorId.trim());
      final newOrderDoc = ordersCollection.doc();
      final orderId = newOrderDoc.id;

      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final orderNumber =
          '#ORD-${suffix.length > 5 ? suffix.substring(suffix.length - 5) : suffix}';

      final List<String> productsList = items
          .map((i) => '${i.productName} × ${i.quantity}')
          .toList();

      final int totalQuantity = items.fold(0, (acc, i) => acc + i.quantity);

      final orderData = {
        'id': orderId,
        'orderNumber': orderNumber,
        'shopId': shopId,
        'shopName': shopName.trim(),
        'shopOwner': shopOwner.trim(),
        'shopMobile': shopMobile.trim(),
        'distributorId': distributorId.trim(),
        'items': items.map((i) => i.toMap()).toList(),
        'products': productsList,
        'totalQuantity': totalQuantity,
        'subtotal': finalSubtotal,
        'deliveryCharge': deliveryCharge,
        'discount': discount,
        'totalAmount': finalTotal,
        'total': finalTotal,
        'status': initialStatus,
        'orderStatus': initialStatus,
        'deliveryAddress': deliveryAddress.trim(),
        'deliveryDate': deliveryDate.trim(),
        'deliveryTime': deliveryTime.trim(),
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 5. Write only the order document (do NOT modify the shop doc)
      await newOrderDoc.set(orderData);

      debugPrint('Order placed successfully: $orderNumber at /distributor/$distributorId/orders/$orderId');
      return orderNumber;
    } catch (e) {
      debugPrint('placeOrder error: $e');
      rethrow;
    }
  }

  /// Real-time stream of all orders for a specific shop:
  /// Queries `/distributor/{distributorId}/orders` where `shopId == currentUser.uid`
  static Stream<List<OrderModel>> streamShopOrders({
    required String distributorId,
    required String shopUid,
  }) {
    if (distributorId.isEmpty || shopUid.isEmpty) {
      return Stream.value([]);
    }

    return _ordersRef(distributorId)
        .where('shopId', isEqualTo: shopUid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          // Sort descending in memory so it works instantly without composite index errors
          list.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

  /// Real-time stream of all orders under a distributor:
  /// Queries `/distributor/{distributorId}/orders`
  static Stream<List<OrderModel>> streamDistributorOrders({
    required String distributorId,
    String? statusFilter,
  }) {
    if (distributorId.isEmpty) {
      return Stream.value([]);
    }

    return _ordersRef(distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          if (statusFilter != null &&
              statusFilter.isNotEmpty &&
              statusFilter.toLowerCase() != 'all') {
            final filter = statusFilter.trim().toLowerCase();
            list = list
                .where((o) =>
                    o.status.toLowerCase() == filter ||
                    o.orderStatus.toLowerCase() == filter)
                .toList();
          }

          return list;
        });
  }

  /// One-time fetch of a specific order from `/distributor/{distributorId}/orders/{orderId}`
  static Future<OrderModel?> getOrder({
    required String distributorId,
    required String orderId,
    String? shopUid,
  }) async {
    if (distributorId.isEmpty || orderId.isEmpty) return null;

    try {
      final doc = await _ordersRef(distributorId).doc(orderId).get();
      if (!doc.exists) return null;
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('getOrder error: $e');
      return null;
    }
  }

  /// Update order status (distributor only):
  /// Updates `/distributor/{distributorId}/orders/{orderId}`
  static Future<void> updateOrderStatus({
    required String distributorId,
    required String orderId,
    required String newStatus,
    String? shopUid,
  }) async {
    if (distributorId.isEmpty || orderId.isEmpty) return;

    final statusLower = newStatus.toLowerCase();
    await _ordersRef(distributorId).doc(orderId).update({
      'status': statusLower,
      'orderStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Batch update multiple orders' status (distributor only)
  static Future<void> batchUpdateOrderStatus({
    required String distributorId,
    required List<String> orderIds,
    required String newStatus,
  }) async {
    if (distributorId.isEmpty || orderIds.isEmpty) return;

    final statusLower = newStatus.toLowerCase();

    // Firestore batch limit is 500 operations per batch
    for (var i = 0; i < orderIds.length; i += 500) {
      final chunk = orderIds.sublist(
        i,
        i + 500 > orderIds.length ? orderIds.length : i + 500,
      );
      final batch = _db.batch();
      for (final orderId in chunk) {
        final docRef = _ordersRef(distributorId).doc(orderId);
        batch.update(docRef, {
          'status': statusLower,
          'orderStatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// Delete an order (distributor only)
  static Future<void> deleteOrder({
    required String distributorId,
    required String orderId,
  }) async {
    if (distributorId.isEmpty || orderId.isEmpty) return;

    await _ordersRef(distributorId).doc(orderId).delete();
  }
}
