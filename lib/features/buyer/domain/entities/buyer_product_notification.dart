import 'package:madebyhands/features/buyer/domain/entities/product.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

enum BuyerProductNotificationReason { wishlisted, purchased, both }

enum BuyerNotificationType { newProduct, order }

class BuyerProductNotification {
  final String id;
  final Product? product;
  final String category;
  final DateTime publishedAt;
  final BuyerProductNotificationReason? reason;
  final BuyerNotificationType type;
  final String? orderId;
  final String? orderStatus;
  final String? orderRejectionReason;

  const BuyerProductNotification({
    required this.id,
    required this.product,
    required this.category,
    required this.publishedAt,
    required this.reason,
    this.type = BuyerNotificationType.newProduct,
    this.orderId,
    this.orderStatus,
    this.orderRejectionReason,
  });

  const BuyerProductNotification.order({
    required this.id,
    required this.orderId,
    required this.orderStatus,
    required this.publishedAt,
    this.orderRejectionReason,
  }) : product = null,
       category = '',
       reason = null,
       type = BuyerNotificationType.order;

  String get title => type == BuyerNotificationType.order
      ? (OrderStatus.normalize(orderStatus ?? '') == OrderStatus.rejected
            ? 'Order rejected'
            : OrderStatus.normalize(orderStatus ?? '') == OrderStatus.confirmed
            ? 'Order accepted'
            : 'Order ${_statusLabel(orderStatus ?? '')}')
      : 'New in $category';

  String get message {
    if (type != BuyerNotificationType.order) {
      return switch (reason) {
        BuyerProductNotificationReason.wishlisted =>
          '${product!.artisan} added ${product!.name} in a category you have wishlisted.',
        BuyerProductNotificationReason.purchased =>
          '${product!.artisan} added ${product!.name} in a category you have purchased from.',
        BuyerProductNotificationReason.both =>
          '${product!.artisan} added ${product!.name} in a category you follow.',
        null => '',
      };
    }

    final normalized = OrderStatus.normalize(orderStatus ?? '');
    if (normalized == OrderStatus.rejected) {
      final reason = (orderRejectionReason ?? '').trim();
      final reasonText = reason.isEmpty ? '' : ' Reason: $reason.';
      return 'Order #$orderId was rejected by the creator.$reasonText '
          'You will be refunded in full within 5 days.';
    }
    if (normalized == OrderStatus.confirmed) {
      return 'Order #$orderId has been accepted by the creator and is now being prepared.';
    }
    return 'Order #$orderId: ${OrderStatus.label(orderStatus ?? '').toLowerCase()}.';
  }

  /// Title-cased status, e.g. 'in_transit' -> 'In Transit'.
  static String _statusLabel(String status) => OrderStatus.normalize(status)
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
