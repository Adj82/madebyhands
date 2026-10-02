import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_product_notification.dart';
import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/buyer/domain/entities/product_review.dart';
import 'package:madebyhands/features/buyer/domain/entities/public_creator.dart';
import 'package:madebyhands/features/buyer/domain/entities/saved_address.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

abstract interface class BuyerRepository {
  Stream<List<Product>> watchProducts();

  /// Reads `settings/platform_economics` so checkout can show the same flat
  /// fee the payment API will charge.
  Future<PlatformFeeSettings> getPlatformFeeSettings();

  Stream<List<PublicCreator>> watchPublicCreators();

  /// Category names managed by admins, falling back to the defaults.
  Stream<List<String>> watchCategories();

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

  Stream<List<BuyerProductNotification>> watchNewProductNotifications(
    String userId,
  );

  Stream<List<BuyerProductNotification>> watchBuyerNotifications(String userId);

  Stream<List<ProductReview>> watchProductReviews(String productId);

  Future<ProductReviewEligibility> getProductReviewEligibility({
    required String buyerId,
    required String productId,
  });

  Future<void> submitProductReview({
    required String buyerId,
    required String buyerName,
    required String productId,
    required int rating,
    required String comment,
  });
}
