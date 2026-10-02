import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';

class CreatorOrderModel extends CreatorOrder {
  const CreatorOrderModel({
    required super.id,
    required super.buyerId,
    required super.buyerName,
    super.buyerPhone,
    required super.createdAt,
    required super.status,
    required super.totalAmount,
    super.platformFee,
    super.creatorNetAmount,
    super.paymentStatus,
    super.payoutStatus,
    super.refundStatus,
    super.isSample,
    required super.items,
    required super.deliveryAddress,
    super.rejectionReason,
    super.consignmentNumber,
    super.carrierName,
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
        baseUnitPrice: (item['baseUnitPrice'] as num?)?.round() ?? 0,
        customizationPrice: (item['customizationPrice'] as num?)?.round() ?? 0,
        customizations: _customizations(item['customizations']),
        image: item['image'] as String? ?? '',
      );
    }).toList();
    final subtotal =
        (json['subtotal'] as num?)?.round() ??
        (json['totalAmount'] as num?)?.round() ??
        (json['total'] as num?)?.round() ??
        items.fold<int>(0, (total, item) => total + item.unitPrice * item.quantity);
    final address = json['shippingAddress'] ?? json['deliveryAddress'];

    return CreatorOrderModel(
      id: id,
      buyerId: json['buyerId'] as String? ?? '',
      buyerName: _recipient(address) ?? json['buyerName'] as String? ?? 'Customer',
      buyerPhone: _phone(address) ?? json['buyerPhone'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      status: json['status'] as String? ?? 'Placed',
      totalAmount: subtotal,
      platformFee: (json['platformFee'] as num?)?.round() ?? 0,
      creatorNetAmount: (json['creatorNetAmount'] as num?)?.round(),
      paymentStatus: (json['paymentStatus'] as String? ?? 'paid').toLowerCase(),
      payoutStatus: (json['payoutStatus'] as String? ?? 'pending').toLowerCase(),
      refundStatus: json['refundStatus'] as String?,
      isSample: json['isSample'] == true,
      items: items,
      deliveryAddress: _addressText(address),
      rejectionReason: json['rejectionReason'] as String?,
      consignmentNumber: json['consignmentNumber'] as String?,
      carrierName: json['carrierName'] as String?,
    );
  }

  static String? _recipient(Object? address) {
    if (address is! Map) return null;
    final name = address['recipientName'];
    return name is String && name.trim().isNotEmpty ? name.trim() : null;
  }

  static String? _phone(Object? address) {
    if (address is! Map) return null;
    final phone = address['phone'];
    return phone is String && phone.trim().isNotEmpty ? phone.trim() : null;
  }

  static String _addressText(Object? address) {
    if (address is String && address.trim().isNotEmpty) return address;
    if (address is Map) {
      final text = [
        address['addressLine'],
        address['city'],
        address['state'],
        address['postalCode'],
      ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
      if (text.isNotEmpty) return text;
    }
    return 'Address unavailable';
  }

  static Map<String, List<String>> _customizations(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, rawValue) {
      final values = rawValue is List
          ? rawValue.map((item) => item.toString()).toList()
          : <String>[rawValue.toString()];
      return MapEntry(key.toString(), values);
    });
  }
}
