import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

abstract interface class OrderRepository {
  Stream<List<MarketplaceOrder>> watchBuyerOrders(String buyerId);
  Stream<List<MarketplaceOrder>> watchCreatorOrders(String creatorId);
  Stream<List<MarketplaceOrder>> watchAllOrders();

  Future<List<String>> placeOrders({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required CheckoutAddress address,
    required List<CheckoutOrderItem> items,
  });

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
  });

  Future<void> releasePayout(String orderId);
  Future<int> seedSampleOrders();
}
