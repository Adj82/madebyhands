import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/orders/data/models/marketplace_order_model.dart';
import 'package:madebyhands/features/orders/domain/entities/marketplace_order.dart';
import 'package:madebyhands/features/orders/domain/repositories/order_repository.dart';

class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore firestore;

  const FirestoreOrderRepository({required this.firestore});

  @override
  Stream<List<MarketplaceOrder>> watchBuyerOrders(String buyerId) => firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .snapshots()
      .map(_ordersFromSnapshot);

  @override
  Stream<List<MarketplaceOrder>> watchCreatorOrders(String creatorId) =>
      firestore
          .collection('orders')
          .where('creatorId', isEqualTo: creatorId)
          .snapshots()
          .map(_ordersFromSnapshot);

  @override
  Stream<List<MarketplaceOrder>> watchAllOrders() =>
      firestore.collection('orders').snapshots().map(_ordersFromSnapshot);

  List<MarketplaceOrder> _ordersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final orders = snapshot.docs
        .map(MarketplaceOrderModel.fromDocument)
        .toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<List<String>> placeOrders({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required CheckoutAddress address,
    required List<CheckoutOrderItem> items,
  }) async {
    if (items.isEmpty) throw StateError('The cart is empty.');
    if (items.any((item) => item.creatorId.isEmpty)) {
      throw StateError('A product is missing its creator information.');
    }

    final settings = await firestore
        .collection('settings')
        .doc('platform_economics')
        .get();
    final settingsData = settings.data() ?? const <String, dynamic>{};
    final flatFee = (settingsData['flatFee'] as num?)?.toDouble() ?? 50;
    final percentFee = (settingsData['percentFee'] as num?)?.toDouble() ?? 5;
    final checkoutId =
        'CHK-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    final grouped = <String, List<CheckoutOrderItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.creatorId, () => []).add(item);
    }

    final orderReferences = grouped.values
        .map((_) => firestore.collection('orders').doc())
        .toList();
    final productReferences = items
        .map((item) => firestore.collection('products').doc(item.productId))
        .toList();

    await firestore.runTransaction((transaction) async {
      final productSnapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final reference in productReferences) {
        productSnapshots[reference.id] = await transaction.get(reference);
      }

      for (final item in items) {
        final product = productSnapshots[item.productId];
        if (product == null || !product.exists) {
          throw StateError('${item.name} is no longer available.');
        }
        final stock = (product.data()?['stock'] as num?)?.round();
        if (stock != null && stock < item.quantity) {
          throw StateError(
            'Only $stock unit(s) of ${item.name} are available.',
          );
        }
      }

      var orderIndex = 0;
      for (final entry in grouped.entries) {
        final creatorItems = entry.value;
        final subtotal = creatorItems.fold<int>(
          0,
          (total, item) => total + item.unitPrice * item.quantity,
        );
        final fee = PlatformFeeCalculator.calculate(
          subtotal: subtotal,
          flatFee: flatFee,
          percentFee: percentFee,
        );
        final creatorName = creatorItems.first.creatorName;
        transaction.set(orderReferences[orderIndex++], {
          'checkoutId': checkoutId,
          'buyerId': buyerId,
          'buyerName': buyerName,
          'buyerPhone': buyerPhone,
          'creatorId': entry.key,
          'creatorName': creatorName,
          'items': creatorItems
              .map(
                (item) => {
                  'productId': item.productId,
                  'name': item.name,
                  'creatorId': item.creatorId,
                  'creatorName': item.creatorName,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                },
              )
              .toList(),
          'shippingAddress': {
            'recipientName': address.recipientName,
            'phone': address.phone,
            'addressLine': address.addressLine,
            'city': address.city,
            'state': address.state,
            'postalCode': address.postalCode,
          },
          'subtotal': subtotal,
          'flatFee': fee.flatFee,
          'commissionRate': fee.commissionRate,
          'commissionAmount': fee.commissionAmount,
          'platformFee': fee.totalFee,
          'creatorNetAmount': fee.creatorNetAmount,
          'status': 'Placed',
          'paymentStatus': 'skipped',
          'payoutStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isSample': false,
        });
      }

      for (final item in items) {
        final reference = firestore.collection('products').doc(item.productId);
        final stock =
            (productSnapshots[item.productId]?.data()?['stock'] as num?)
                ?.round();
        if (stock != null) {
          transaction.update(reference, {'stock': stock - item.quantity});
        }
      }
    });

    return orderReferences.map((reference) => reference.id).toList();
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    if (consignmentNumber != null) {
      data['consignmentNumber'] = consignmentNumber;
    }
    if (status == 'Rejected' || status == 'Cancelled') {
      data['payoutStatus'] = 'cancelled';
    }
    await firestore.collection('orders').doc(orderId).update(data);
  }

  @override
  Future<void> releasePayout(String orderId) =>
      firestore.collection('orders').doc(orderId).update({
        'payoutStatus': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<int> seedSampleOrders() async {
    final creators = await firestore
        .collection('users')
        .where('role', isEqualTo: 'creator')
        .get();
    if (creators.docs.isEmpty) return 0;
    final buyers = await firestore
        .collection('users')
        .where('role', isEqualTo: 'buyer')
        .limit(1)
        .get();
    final buyer = buyers.docs.isEmpty ? null : buyers.docs.first;
    final statuses = ['Placed', 'Accepted', 'Shipped', 'Completed'];
    final batch = firestore.batch();
    var created = 0;

    for (final creator in creators.docs) {
      final products = await firestore
          .collection('products')
          .where('creatorUid', isEqualTo: creator.id)
          .limit(1)
          .get();
      final product = products.docs.isEmpty ? null : products.docs.first;
      final productData = product?.data() ?? const <String, dynamic>{};
      final creatorData = creator.data();
      for (var index = 0; index < statuses.length; index++) {
        final reference = firestore
            .collection('orders')
            .doc('sample-${creator.id}-$index');
        final existing = await reference.get();
        if (existing.exists) continue;
        final subtotal =
            ((productData['price'] as num?)?.round() ?? 1200) + index * 150;
        final fee = PlatformFeeCalculator.calculate(
          subtotal: subtotal,
          flatFee: 50,
          percentFee: 5,
        );
        batch.set(reference, {
          'checkoutId': 'sample-checkout-${creator.id}-$index',
          'buyerId': buyer?.id ?? 'sample-buyer',
          'buyerName': buyer?.data()['name'] ?? 'Sample Buyer',
          'buyerPhone': buyer?.data()['phone'] ?? '9999999999',
          'creatorId': creator.id,
          'creatorName': creatorData['name'] ?? 'Sample Creator',
          'items': [
            {
              'productId': product?.id ?? 'sample-product',
              'name': productData['name'] ?? 'Sample Handmade Product',
              'creatorId': creator.id,
              'creatorName': creatorData['name'] ?? 'Sample Creator',
              'quantity': 1,
              'unitPrice': subtotal,
            },
          ],
          'shippingAddress': {
            'recipientName': buyer?.data()['name'] ?? 'Sample Buyer',
            'phone': buyer?.data()['phone'] ?? '9999999999',
            'addressLine': 'Sample Craft Lane',
            'city': 'Jaipur',
            'state': 'Rajasthan',
            'postalCode': '302001',
          },
          'subtotal': subtotal,
          'flatFee': fee.flatFee,
          'commissionRate': fee.commissionRate,
          'commissionAmount': fee.commissionAmount,
          'platformFee': fee.totalFee,
          'creatorNetAmount': fee.creatorNetAmount,
          'status': statuses[index],
          'paymentStatus': 'skipped',
          'payoutStatus': 'pending',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: index + 1)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
          'isSample': true,
        });
        created++;
      }
    }
    if (created > 0) await batch.commit();
    return created;
  }
}
