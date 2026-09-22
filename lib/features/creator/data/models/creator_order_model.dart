import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';

class CreatorOrderModel extends CreatorOrder {
  const CreatorOrderModel({
    required super.id,
    required super.buyerId,
    required super.buyerName,
    required super.createdAt,
    required super.status,
    required super.totalAmount,
    required super.items,
    required super.deliveryAddress,
    super.rejectionReason,
    super.consignmentNumber,
  });

  factory CreatorOrderModel.fromJson(Map<String, dynamic> json, String id) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return BuyerOrderItem(
        productId: item['productId'] as String? ?? '',
        name: item['name'] as String? ?? 'Handmade item',
        quantity: (item['quantity'] as num?)?.round() ?? 1,
        unitPrice: (item['unitPrice'] as num?)?.round() ?? 0,
      );
    }).toList();

    return CreatorOrderModel(
      id: id,
      buyerId: json['buyerId'] ?? '',
      buyerName: json['buyerName'] ?? 'Valued Customer',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'Placed',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      items: items,
      deliveryAddress: json['deliveryAddress'] ?? 'Address unavailable',
      rejectionReason: json['rejectionReason'],
      consignmentNumber: json['consignmentNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'status': status,
      'totalAmount': totalAmount,
      'items': items.map((item) => {
        'productId': item.productId,
        'name': item.name,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
      }).toList(),
      'deliveryAddress': deliveryAddress,
      'rejectionReason': rejectionReason,
      'consignmentNumber': consignmentNumber,
      'createdAt': createdAt, // Preserving original creation time on updates
    };
  }
}
