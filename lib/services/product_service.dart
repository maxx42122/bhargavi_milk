import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String packSize;
  final String unit;
  final double price;
  final int stock;
  final bool active;
  final String description;
  final String emoji;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.packSize,
    required this.unit,
    required this.price,
    required this.stock,
    this.active = true,
    this.description = '',
    this.emoji = '🥛',
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final priceRaw = data['price'];
    final double parsedPrice = (priceRaw is num)
        ? priceRaw.toDouble()
        : (double.tryParse(priceRaw?.toString() ?? '0') ?? 0.0);

    final stockRaw = data['stock'];
    final int parsedStock = (stockRaw is num)
        ? stockRaw.toInt()
        : (int.tryParse(stockRaw?.toString() ?? '0') ?? 0);

    final activeRaw = data['active'];
    final bool parsedActive = (activeRaw is bool)
        ? activeRaw
        : (activeRaw?.toString().toLowerCase() != 'false');

    return Product(
      id: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      category: (data['category'] ?? 'Milk').toString().trim(),
      packSize: (data['packSize'] ?? '500ml').toString().trim(),
      unit: (data['unit'] ?? 'Pouch').toString().trim(),
      price: parsedPrice,
      stock: parsedStock,
      active: parsedActive,
      description: (data['description'] ?? '').toString().trim(),
      emoji: (data['emoji'] ?? '🥛').toString().trim(),
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
      'name': name.trim(),
      'category': category.trim(),
      'packSize': packSize.trim(),
      'unit': unit.trim(),
      'price': price,
      'stock': stock,
      'active': active,
      'description': description.trim(),
      'emoji': emoji.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? packSize,
    String? unit,
    double? price,
    int? stock,
    bool? active,
    String? description,
    String? emoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      packSize: packSize ?? this.packSize,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      active: active ?? this.active,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProductService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns collection reference:
  /// /distributor/{distributorId}/products
  static CollectionReference<Map<String, dynamic>> _productsRef(
    String distributorId,
  ) {
    return _db
        .collection('distributor')
        .doc(distributorId)
        .collection('products');
  }

  /// Real-time stream of all products under a distributor.
  static Stream<List<Product>> streamProducts(String distributorId) {
    if (distributorId.isEmpty) {
      return Stream.value([]);
    }

    return _productsRef(distributorId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();

          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  /// Fetch products once
  static Future<List<Product>> fetchProducts(String distributorId) async {
    if (distributorId.isEmpty) return [];

    try {
      final snapshot = await _productsRef(distributorId).get();
      final list = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('fetchProducts error: $e');
      rethrow;
    }
  }

  /// Add a new product to /distributor/{distributorId}/products
  static Future<String> addProduct({
    required String distributorId,
    required String name,
    required String category,
    required String packSize,
    required String unit,
    required double price,
    required int stock,
    bool active = true,
    String description = '',
    String emoji = '🥛',
  }) async {
    if (distributorId.isEmpty) {
      throw Exception('Distributor ID is required.');
    }

    final docRef = _productsRef(distributorId).doc();

    final data = {
      'id': docRef.id,
      'name': name.trim(),
      'category': category.trim(),
      'packSize': packSize.trim(),
      'unit': unit.trim(),
      'price': price,
      'stock': stock,
      'active': active,
      'description': description.trim(),
      'emoji': emoji.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing product
  static Future<void> updateProduct({
    required String distributorId,
    required Product product,
  }) async {
    if (distributorId.isEmpty || product.id.isEmpty) {
      throw Exception('Distributor ID and Product ID are required.');
    }

    await _productsRef(distributorId).doc(product.id).update(product.toFirestore());
  }

  /// Toggle product active / inactive status
  static Future<void> toggleProductStatus({
    required String distributorId,
    required String productId,
    required bool currentStatus,
  }) async {
    if (distributorId.isEmpty || productId.isEmpty) return;

    await _productsRef(distributorId).doc(productId).update({
      'active': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update stock quantity
  static Future<void> updateStock({
    required String distributorId,
    required String productId,
    required int newStock,
  }) async {
    if (distributorId.isEmpty || productId.isEmpty) return;

    await _productsRef(distributorId).doc(productId).update({
      'stock': newStock < 0 ? 0 : newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a product
  static Future<void> deleteProduct({
    required String distributorId,
    required String productId,
  }) async {
    if (distributorId.isEmpty || productId.isEmpty) return;

    await _productsRef(distributorId).doc(productId).delete();
  }

  /// Seed initial sample products into Firestore if none exist
  static Future<int> seedInitialProducts(String distributorId) async {
    if (distributorId.isEmpty) return 0;

    final ref = _productsRef(distributorId);
    final current = await ref.limit(1).get();

    if (current.docs.isNotEmpty) {
      // Products already exist
      return 0;
    }

    final batch = _db.batch();

    for (final mock in mockProducts) {
      final docRef = ref.doc();
      batch.set(docRef, {
        'id': docRef.id,
        'name': mock.name,
        'category': mock.category,
        'packSize': mock.packSize,
        'unit': mock.unit,
        'price': mock.price,
        'stock': mock.stock,
        'active': mock.active,
        'description': mock.description,
        'emoji': mock.emoji,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return mockProducts.length;
  }
}
