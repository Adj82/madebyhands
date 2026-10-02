class BuyerOrderItem {
  final String productId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int baseUnitPrice;
  final int customizationPrice;
  final Map<String, List<String>> customizations;
  final String image;

  const BuyerOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.baseUnitPrice = 0,
    this.customizationPrice = 0,
    this.customizations = const {},
    this.image = '',
  });

  int get total => quantity * unitPrice;
}

class BuyerOrder {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String status;

  /// What the buyer paid for this order: items subtotal + platform fee.
  final int total;
  final int subtotal;
  final int platformFee;
  final List<BuyerOrderItem> items;
  final String deliveryAddress;

  /// The buyer's name as snapshotted on the order, for the invoice's
  /// "Bill To" line. Falls back to 'Customer' when missing on old orders.
  final String buyerName;
  final String? rejectionReason;
  final String? consignmentNumber;
  final String? carrierName;
  final String? trackingUrl;
  final String? lastLocation;
  final DateTime? trackingUpdatedAt;

  /// 'processing', 'refunded' or 'failed' once a paid order is rejected.
  final String? refundStatus;

  const BuyerOrder({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    required this.status,
    required this.total,
    this.subtotal = 0,
    this.platformFee = 0,
    required this.items,
    required this.deliveryAddress,
    this.buyerName = 'Customer',
    this.rejectionReason,
    this.consignmentNumber,
    this.carrierName,
    this.trackingUrl,
    this.lastLocation,
    this.trackingUpdatedAt,
    this.refundStatus,
  });
}

/// Buyer-facing text for a rejected order's refund state.
String refundStatusLabel(String refundStatus) => switch (refundStatus) {
  'refunded' => 'Refunded to your original payment method',
  'failed' => 'Refund pending — our team is on it',
  _ => 'Refund in progress — you will be refunded in full within 5 days',
};
