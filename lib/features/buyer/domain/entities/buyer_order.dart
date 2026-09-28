class BuyerOrderItem {
  final String productId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int baseUnitPrice;
  final int customizationPrice;
  final Map<String, List<String>> customizations;

  const BuyerOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.baseUnitPrice = 0,
    this.customizationPrice = 0,
    this.customizations = const {},
  });

  int get total => quantity * unitPrice;
}

class BuyerOrder {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String status;
  final int total;
  final List<BuyerOrderItem> items;
  final String deliveryAddress;
  final String? rejectionReason;
  final String? consignmentNumber;
  final String? carrierName;
  final String? trackingUrl;
  final String? lastLocation;
  final DateTime? trackingUpdatedAt;

  const BuyerOrder({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    required this.status,
    required this.total,
    required this.items,
    required this.deliveryAddress,
    this.rejectionReason,
    this.consignmentNumber,
    this.carrierName,
    this.trackingUrl,
    this.lastLocation,
    this.trackingUpdatedAt,
  });
}
