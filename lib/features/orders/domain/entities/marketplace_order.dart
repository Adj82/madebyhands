class MarketplaceOrderItem {
  final String productId;
  final String name;
  final String creatorId;
  final String creatorName;
  final int quantity;
  final int unitPrice;

  const MarketplaceOrderItem({
    required this.productId,
    required this.name,
    required this.creatorId,
    required this.creatorName,
    required this.quantity,
    required this.unitPrice,
  });

  int get total => quantity * unitPrice;
}

class MarketplaceOrder {
  final String id;
  final String checkoutId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final int subtotal;
  final int flatFee;
  final double commissionRate;
  final int commissionAmount;
  final int platformFee;
  final int creatorNetAmount;
  final String paymentStatus;
  final String payoutStatus;
  final List<MarketplaceOrderItem> items;
  final String deliveryAddress;
  final String? rejectionReason;
  final String? consignmentNumber;
  final bool isSample;

  const MarketplaceOrder({
    required this.id,
    required this.checkoutId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.subtotal,
    required this.flatFee,
    required this.commissionRate,
    required this.commissionAmount,
    required this.platformFee,
    required this.creatorNetAmount,
    required this.paymentStatus,
    required this.payoutStatus,
    required this.items,
    required this.deliveryAddress,
    this.rejectionReason,
    this.consignmentNumber,
    this.isSample = false,
  });

  int get total => subtotal;
  int get totalAmount => subtotal;
}

class CheckoutOrderItem {
  final String productId;
  final String name;
  final String creatorId;
  final String creatorName;
  final int quantity;
  final int unitPrice;

  const CheckoutOrderItem({
    required this.productId,
    required this.name,
    required this.creatorId,
    required this.creatorName,
    required this.quantity,
    required this.unitPrice,
  });
}

class CheckoutAddress {
  final String recipientName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String postalCode;

  const CheckoutAddress({
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  String get formatted => '$addressLine, $city, $state $postalCode';
}

class PlatformFeeBreakdown {
  final int flatFee;
  final double commissionRate;
  final int commissionAmount;
  final int totalFee;
  final int creatorNetAmount;

  const PlatformFeeBreakdown({
    required this.flatFee,
    required this.commissionRate,
    required this.commissionAmount,
    required this.totalFee,
    required this.creatorNetAmount,
  });
}

class PlatformFeeCalculator {
  static PlatformFeeBreakdown calculate({
    required int subtotal,
    required double flatFee,
    required double percentFee,
  }) {
    final normalizedFlatFee = flatFee.round().clamp(0, subtotal);
    final appliedRate = subtotal > 999
        ? percentFee.clamp(0, 100).toDouble()
        : 0.0;
    final commission = (subtotal * appliedRate / 100).round();
    final totalFee = (normalizedFlatFee + commission).clamp(0, subtotal);
    return PlatformFeeBreakdown(
      flatFee: normalizedFlatFee,
      commissionRate: appliedRate,
      commissionAmount: commission,
      totalFee: totalFee,
      creatorNetAmount: subtotal - totalFee,
    );
  }
}
