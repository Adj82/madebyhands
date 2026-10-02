import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';

/// An order as seen by the creator who fulfils it. Amounts are integer
/// rupees snapshotted by the payment API at checkout.
class CreatorOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final DateTime createdAt;

  /// Raw Firestore status; compare through `OrderStatus`.
  final String status;

  /// Items subtotal (what the creator's products sold for).
  final int totalAmount;
  final int platformFee;
  final int creatorNetAmount;

  /// Fee breakdown snapshotted on the order at checkout time (see
  /// `server/fees.js`), used by the seller-copy invoice. `flatFee` +
  /// `commissionAmount` == `platformFee`.
  final int flatFee;
  final double commissionRate;
  final int commissionAmount;
  final String paymentStatus;
  final String payoutStatus;
  final String? refundStatus;

  /// Seeded demo orders; never counted as real earnings.
  final bool isSample;
  final List<BuyerOrderItem> items;
  final String deliveryAddress;
  final String? rejectionReason;
  final String? consignmentNumber;
  final String? carrierName;

  const CreatorOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhone = '',
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    this.platformFee = 0,
    this.flatFee = 0,
    this.commissionRate = 0,
    this.commissionAmount = 0,
    int? creatorNetAmount,
    this.paymentStatus = 'paid',
    this.payoutStatus = 'pending',
    this.refundStatus,
    this.isSample = false,
    required this.items,
    required this.deliveryAddress,
    this.rejectionReason,
    this.consignmentNumber,
    this.carrierName,
  }) : creatorNetAmount = creatorNetAmount ?? totalAmount;

  /// A real, paid order whose creator payout is still owed or already made.
  bool get countsTowardEarnings =>
      paymentStatus == 'paid' && !isSample && payoutStatus != 'cancelled';

  bool get isPaidOut => payoutStatus == 'paid' || payoutStatus == 'released';

  String get shortId =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();
}
