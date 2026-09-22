import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';

class MarketplaceOrderModel extends MarketplaceOrder {
  const MarketplaceOrderModel({
    required super.id,
    required super.checkoutId,
    required super.buyerId,
    required super.buyerName,
    required super.buyerPhone,
    required super.creatorId,
    required super.creatorName,
    required super.createdAt,
    required super.updatedAt,
    required super.status,
    required super.subtotal,
    required super.flatFee,
    required super.commissionRate,
    required super.commissionAmount,
    required super.platformFee,
    required super.creatorNetAmount,
    required super.paymentStatus,
    required super.payoutStatus,
    required super.items,
    required super.deliveryAddress,
    super.rejectionReason,
    super.consignmentNumber,
    super.isSample,
  });

  factory MarketplaceOrderModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final rawItems = data['items'] as List<dynamic>? ?? const [];
    final items = rawItems.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return MarketplaceOrderItem(
        productId: item['productId'] as String? ?? '',
        name: item['name'] as String? ?? 'Handmade item',
        creatorId:
            item['creatorId'] as String? ?? data['creatorId'] as String? ?? '',
        creatorName:
            item['creatorName'] as String? ??
            data['creatorName'] as String? ??
            'Creator',
        quantity: (item['quantity'] as num?)?.round() ?? 1,
        unitPrice: (item['unitPrice'] as num?)?.round() ?? 0,
      );
    }).toList();
    final address = data['shippingAddress'] ?? data['deliveryAddress'];
    final subtotal =
        (data['subtotal'] as num?)?.round() ??
        (data['totalAmount'] as num?)?.round() ??
        (data['total'] as num?)?.round() ??
        items.fold<int>(0, (total, item) => total + item.total);
    final createdAt = _date(data['createdAt']);

    return MarketplaceOrderModel(
      id: document.id,
      checkoutId: data['checkoutId'] as String? ?? document.id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? 'Valued Customer',
      buyerPhone: data['buyerPhone'] as String? ?? '',
      creatorId: data['creatorId'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? 'Creator',
      createdAt: createdAt,
      updatedAt: _date(data['updatedAt'], fallback: createdAt),
      status: data['status'] as String? ?? 'Placed',
      subtotal: subtotal,
      flatFee: (data['flatFee'] as num?)?.round() ?? 0,
      commissionRate: (data['commissionRate'] as num?)?.toDouble() ?? 0,
      commissionAmount: (data['commissionAmount'] as num?)?.round() ?? 0,
      platformFee: (data['platformFee'] as num?)?.round() ?? 0,
      creatorNetAmount: (data['creatorNetAmount'] as num?)?.round() ?? subtotal,
      paymentStatus: data['paymentStatus'] as String? ?? 'skipped',
      payoutStatus: data['payoutStatus'] as String? ?? 'pending',
      items: items,
      deliveryAddress: _addressText(address),
      rejectionReason: data['rejectionReason'] as String?,
      consignmentNumber: data['consignmentNumber'] as String?,
      isSample: data['isSample'] as bool? ?? false,
    );
  }

  static DateTime _date(Object? value, {DateTime? fallback}) =>
      value is Timestamp ? value.toDate() : fallback ?? DateTime(1970);

  static String _addressText(Object? address) {
    if (address is String) return address;
    if (address is Map) {
      return [
        address['addressLine'],
        address['city'],
        address['state'],
        address['postalCode'],
      ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    }
    return 'Address unavailable';
  }
}
