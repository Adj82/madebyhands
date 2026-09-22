import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';

class CreatorOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final DateTime createdAt;
  final String status; // 'Placed', 'Accepted', 'Rejected', 'Shipped', 'Delivered', 'Completed'
  final int totalAmount;
  final List<BuyerOrderItem> items;
  final String deliveryAddress;
  final String? rejectionReason;
  final String? consignmentNumber;

  const CreatorOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.deliveryAddress,
    this.rejectionReason,
    this.consignmentNumber,
  });
}
