import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/product_review.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

class FirestoreBuyerRepository implements BuyerRepository {
  final FirebaseFirestore firestore;

  const FirestoreBuyerRepository({required this.firestore});

  @override
  Stream<List<Product>> watchProducts() => firestore
      .collection('products')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.data()['isActive'] != false)
            .map((doc) => _productFromDocument(doc))
            .toList(),
      );

  @override
  Stream<Set<String>> watchFavoriteProductIds(String userId) => firestore
      .collection('users')
      .doc(userId)
      .collection('favorites')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Future<void> setFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  }) async {
    final reference = firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId);
    if (isFavorite) {
      await reference.set({
        'productId': productId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await reference.delete();
    }
  }

  @override
  Stream<List<BuyerOrder>> watchOrders(String userId) => firestore
      .collection('orders')
      .where('buyerId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs.map(_orderFromDocument).toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });

  @override
  Stream<List<SavedAddress>> watchAddresses(String userId) => firestore
      .collection('users')
      .doc(userId)
      .collection('addresses')
      .snapshots()
      .map((snapshot) {
        final addresses = snapshot.docs.map(_addressFromDocument).toList();
        addresses.sort((a, b) {
          if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
          return a.label.compareTo(b.label);
        });
        return addresses;
      });

  @override
  Future<void> saveAddress(String userId, SavedAddress address) async {
    final collection = firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');
    final reference = address.id.isEmpty
        ? collection.doc()
        : collection.doc(address.id);

    if (address.isDefault) {
      final batch = firestore.batch();
      final existing = await collection.get();
      for (final document in existing.docs) {
        batch.update(document.reference, {'isDefault': false});
      }
      batch.set(reference, _addressToMap(address));
      await batch.commit();
      return;
    }

    await reference.set(_addressToMap(address));
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) => firestore
      .collection('users')
      .doc(userId)
      .collection('addresses')
      .doc(addressId)
      .delete();

  @override
  Stream<List<ProductReview>> watchProductReviews(String productId) => firestore
      .collection('products')
      .doc(productId)
      .collection('reviews')
      .snapshots()
      .map((snapshot) {
        final reviews = snapshot.docs.map(_reviewFromDocument).toList();
        reviews.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return reviews;
      });

  @override
  Future<ProductReviewEligibility> getProductReviewEligibility({
    required String buyerId,
    required String productId,
  }) async {
    final orders = await firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .get();
    for (final document in orders.docs) {
      final data = document.data();
      if (OrderStatus.normalize(data['status'] as String? ?? '') !=
          OrderStatus.delivered) {
        continue;
      }
      final items = data['items'] as List<dynamic>? ?? const [];
      final containsProduct = items.whereType<Map>().any(
        (item) => item['productId'] == productId,
      );
      if (containsProduct) {
        return ProductReviewEligibility.eligible(document.id);
      }
    }
    return const ProductReviewEligibility.ineligible();
  }

  @override
  Future<void> submitProductReview({
    required String buyerId,
    required String buyerName,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 5');
    }
    final normalizedComment = comment.trim();
    if (normalizedComment.length < 3 || normalizedComment.length > 1000) {
      throw ArgumentError.value(
        normalizedComment,
        'comment',
        'Must be between 3 and 1000 characters',
      );
    }
    final eligibility = await getProductReviewEligibility(
      buyerId: buyerId,
      productId: productId,
    );
    if (!eligibility.canReview) {
      throw StateError(eligibility.message);
    }

    final reference = firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(buyerId);
    final existing = await reference.get();
    await reference.set({
      'schemaVersion': 1,
      'productId': productId,
      'buyerId': buyerId,
      'buyerName': buyerName.trim().isEmpty ? 'Buyer' : buyerName.trim(),
      'rating': rating,
      'comment': normalizedComment,
      'verifiedPurchase': true,
      'orderId': eligibility.orderId,
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Product _productFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final category = data['category'] as String? ?? 'Handmade';
    final visual = _visualForCategory(category);
    return Product(
      id: document.id,
      name: data['name'] as String? ?? 'Handmade piece',
      artisan:
          data['artisan'] as String? ??
          data['sellerName'] as String? ??
          'MadeByHands artisan',
      category: category,
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.round() ?? 0,
      rating:
          (data['ratingAverage'] as num?)?.toDouble() ??
          (data['rating'] as num?)?.toDouble() ??
          0,
      color: Color((data['colorValue'] as num?)?.toInt() ?? visual.$1),
      icon: IconData(
        (data['iconCodePoint'] as num?)?.toInt() ?? visual.$2,
        fontFamily: 'MaterialIcons',
      ),
      creatorUid: data['creatorUid'] as String? ?? '',
      images: List<String>.from(data['images'] as List? ?? const []),
      stock: (data['stock'] as num?)?.round() ?? 0,
    );
  }

  BuyerOrder _orderFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final items = rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return BuyerOrderItem(
        productId: item['productId'] as String? ?? '',
        name: item['name'] as String? ?? 'Handmade item',
        quantity: (item['quantity'] as num?)?.round() ?? 1,
        unitPrice: (item['unitPrice'] as num?)?.round() ?? 0,
      );
    }).toList();
    final address = data['shippingAddress'] ?? data['deliveryAddress'];
    final createdAt =
        _timestamp(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return BuyerOrder(
      id: document.id,
      createdAt: createdAt,
      updatedAt: _timestamp(data['updatedAt']) ?? createdAt,
      deliveredAt: _timestamp(data['deliveredAt']),
      status: OrderStatus.normalize(data['status'] as String? ?? 'Placed'),
      total:
          (data['buyerPayableAmount'] as num?)?.round() ??
          (data['subtotal'] as num?)?.round() ??
          (data['totalAmount'] as num?)?.round() ??
          (data['total'] as num?)?.round() ??
          items.fold(0, (total, item) => total + item.total),
      items: items,
      deliveryAddress: address is Map
          ? [
              address['addressLine'],
              address['city'],
              address['state'],
              address['postalCode'],
            ].whereType<String>().where((value) => value.isNotEmpty).join(', ')
          : address as String? ?? 'Address unavailable',
      rejectionReason: data['rejectionReason'] as String?,
      consignmentNumber: data['consignmentNumber'] as String?,
      carrierName: data['carrierName'] as String?,
      trackingUrl: data['trackingUrl'] as String?,
      lastLocation: data['lastLocation'] as String?,
      trackingUpdatedAt: _timestamp(data['trackingUpdatedAt']),
    );
  }

  DateTime? _timestamp(Object? value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;

  SavedAddress _addressFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return SavedAddress(
      id: document.id,
      label: data['label'] as String? ?? 'Address',
      recipientName: data['recipientName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      addressLine: data['addressLine'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      postalCode: data['postalCode'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  ProductReview _reviewFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt =
        _timestamp(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ProductReview(
      id: document.id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? 'Buyer',
      rating: ((data['rating'] as num?)?.round() ?? 0).clamp(1, 5),
      comment: data['comment'] as String? ?? '',
      verifiedPurchase: data['verifiedPurchase'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: _timestamp(data['updatedAt']) ?? createdAt,
    );
  }

  Map<String, dynamic> _addressToMap(SavedAddress address) => {
    'label': address.label,
    'recipientName': address.recipientName,
    'phone': address.phone,
    'addressLine': address.addressLine,
    'city': address.city,
    'state': address.state,
    'postalCode': address.postalCode,
    'isDefault': address.isDefault,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  (int, int) _visualForCategory(String category) =>
      switch (category.toLowerCase()) {
        'pottery' => (0xFFAFC9D6, Icons.local_florist_outlined.codePoint),
        'jewellery' => (0xFFD8D6D1, Icons.diamond_outlined.codePoint),
        'textiles' => (0xFFE8AA91, Icons.shopping_bag_outlined.codePoint),
        'wellness' => (0xFFD9A179, Icons.light_mode_outlined.codePoint),
        'gifts' => (0xFFB8C99D, Icons.card_giftcard_outlined.codePoint),
        _ => (0xFFD8BE8B, Icons.handyman_outlined.codePoint),
      };
}
