class BuyerOrderItem {
  final String productId;
  final String name;
  final int quantity;
  final int unitPrice;

  const BuyerOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  int get total => quantity * unitPrice;
}

class BuyerOrder {
  final String id;
  final DateTime createdAt;
  final String status;
  final int total;
  final List<BuyerOrderItem> items;
  final String deliveryAddress;

  const BuyerOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.total,
    required this.items,
    required this.deliveryAddress,
  });
}
