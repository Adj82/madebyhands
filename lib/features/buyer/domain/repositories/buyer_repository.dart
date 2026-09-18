import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';

abstract interface class BuyerRepository {
  Stream<List<Product>> watchProducts();

  Stream<Set<String>> watchFavoriteProductIds(String userId);

  Future<void> setFavorite({
    required String userId,
    required String productId,
    required bool isFavorite,
  });

  Stream<List<BuyerOrder>> watchOrders(String userId);

  Stream<List<SavedAddress>> watchAddresses(String userId);

  Future<void> saveAddress(String userId, SavedAddress address);

  Future<void> deleteAddress(String userId, String addressId);
}
