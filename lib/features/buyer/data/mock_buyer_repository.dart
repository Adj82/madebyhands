import 'dart:async';

import 'package:madebyhands/features/buyer/data/mock_products.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';

class MockBuyerRepository implements BuyerRepository {
  final Set<String> _favorites = {};
  final List<SavedAddress> _addresses = [
    const SavedAddress(
      id: 'home',
      label: 'Home',
      recipientName: 'Suhani',
      phone: '9876543210',
      addressLine: '21 Craft Lane',
      city: 'Jaipur',
      state: 'Rajasthan',
      postalCode: '302001',
      isDefault: true,
    ),
  ];
  final _favoriteChanges = StreamController<Set<String>>.broadcast();
  final _addressChanges = StreamController<List<SavedAddress>>.broadcast();

  @override
  Stream<List<Product>> watchProducts() => Stream.value(mockProducts);

  @override
  Stream<Set<String>> watchFavoriteProductIds(String userId) async* {
    yield Set.unmodifiable(_favorites);
    yield* _favoriteChanges.stream;
  }

  @override
  Future<void> setFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  }) async {
    isFavorite ? _favorites.add(productId) : _favorites.remove(productId);
    _favoriteChanges.add(Set.unmodifiable(_favorites));
  }

  @override
  Stream<List<BuyerOrder>> watchOrders(String userId) => Stream.value([
    BuyerOrder(
      id: 'MBH-24091',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'Shipped',
      total: 2198,
      items: const [
        BuyerOrderItem(
          productId: 'woven-basket',
          name: 'Handwoven Storage Basket',
          quantity: 1,
          unitPrice: 1299,
        ),
        BuyerOrderItem(
          productId: 'blue-pottery',
          name: 'Blue Pottery Vase',
          quantity: 1,
          unitPrice: 899,
        ),
      ],
      deliveryAddress: '21 Craft Lane, Jaipur, Rajasthan 302001',
    ),
  ]);

  @override
  Stream<List<SavedAddress>> watchAddresses(String userId) async* {
    yield List.unmodifiable(_addresses);
    yield* _addressChanges.stream;
  }

  @override
  Future<void> saveAddress(String userId, SavedAddress address) async {
    if (address.isDefault) {
      for (var index = 0; index < _addresses.length; index++) {
        _addresses[index] = _addresses[index].copyWith(isDefault: false);
      }
    }
    final normalized = address.id.isEmpty
        ? address.copyWith(
            id: 'address-${DateTime.now().microsecondsSinceEpoch}',
          )
        : address;
    final index = _addresses.indexWhere((item) => item.id == normalized.id);
    index == -1 ? _addresses.add(normalized) : _addresses[index] = normalized;
    _addressChanges.add(List.unmodifiable(_addresses));
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    _addresses.removeWhere((address) => address.id == addressId);
    _addressChanges.add(List.unmodifiable(_addresses));
  }
}
