import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';

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
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      color: Color((data['colorValue'] as num?)?.toInt() ?? visual.$1),
      icon: IconData(
        (data['iconCodePoint'] as num?)?.toInt() ?? visual.$2,
        fontFamily: 'MaterialIcons',
      ),
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
    final address = data['shippingAddress'];
    return BuyerOrder(
      id: document.id,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: data['status'] as String? ?? 'Placed',
      total:
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
    );
  }

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
