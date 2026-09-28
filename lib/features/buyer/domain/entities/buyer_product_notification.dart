import 'package:madebyhands/features/buyer/domain/entities/product.dart';

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

  const BuyerProductNotification({
    required this.id,
    required this.product,
    required this.category,
    required this.publishedAt,
    required this.reason,
    this.type = BuyerNotificationType.newProduct,
    this.orderId,
    this.orderStatus,
  });

  const BuyerProductNotification.order({
    required this.id,
    required this.orderId,
    required this.orderStatus,
    required this.publishedAt,
  }) : product = null,
       category = '',
       reason = null,
       type = BuyerNotificationType.order;

  String get title => type == BuyerNotificationType.order
      ? 'Order ${_statusLabel(orderStatus ?? '')}'
      : 'New in $category';

  String get message => type == BuyerNotificationType.order
      ? 'Order #$orderId is now ${_statusLabel(orderStatus ?? '').toLowerCase()}.'
      : switch (reason) {
          BuyerProductNotificationReason.wishlisted =>
            '${product!.artisan} added ${product!.name} in a category you have wishlisted.',
          BuyerProductNotificationReason.purchased =>
            '${product!.artisan} added ${product!.name} in a category you have purchased from.',
          BuyerProductNotificationReason.both =>
            '${product!.artisan} added ${product!.name} in a category you follow.',
          null => '',
        };

  static String _statusLabel(String status) => status
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
