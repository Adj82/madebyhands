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
    final requestedStock = <String, int>{};
    final productNames = <String, String>{};
    for (final item in items) {
      grouped.putIfAbsent(item.creatorId, () => []).add(item);
      requestedStock.update(
        item.productId,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
      productNames[item.productId] = item.name;
    }

    final orderReferences = grouped.values
        .map((_) => firestore.collection('orders').doc())
        .toList();

    await firestore.runTransaction((transaction) async {
      final stockUpdates = <_RepoItemStockUpdate>[];
      for (final entry in requestedStock.entries) {
        final productRef = firestore.collection('products').doc(entry.key);
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw StateError(
            'Product "${productNames[entry.key] ?? entry.key}" is no longer available.',
          );
        }
        final data = productSnapshot.data() ?? const <String, dynamic>{};
        final isActive = data['isActive'] != false;
        final currentStock = (data['stock'] as num?)?.round() ?? 0;
        if (!isActive || currentStock < entry.value) {
          throw StateError(
            'Only $currentStock unit(s) of "${productNames[entry.key] ?? entry.key}" are available.',
          );
        }
        stockUpdates.add(
          _RepoItemStockUpdate(
            ref: productRef,
            snap: productSnapshot,
            quantity: entry.value,
            name: productNames[entry.key] ?? entry.key,
          )..newStock = currentStock - entry.value,
        );
      }

      for (final update in stockUpdates) {
        transaction.update(update.ref, {'stock': update.newStock});
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
        final orderDocRef = orderReferences[orderIndex++];

        transaction.set(orderDocRef, {
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
                  'baseUnitPrice': item.baseUnitPrice,
                  'customizationPrice': item.customizationPrice,
                  'customizations': item.customizations,
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
          'stockReserved': true,
        });
      }
    });

    // Notifications are intentionally outside the order transaction. A
    // notification permission/network failure must never roll back an order.
    try {
      final batch = firestore.batch();
      var orderIndex = 0;
      for (final entry in grouped.entries) {
        final creatorItems = entry.value;
        final subtotal = creatorItems.fold<int>(
          0,
          (total, item) => total + item.unitPrice * item.quantity,
        );
        final notificationDocRef = firestore.collection('notifications').doc();
        batch.set(notificationDocRef, {
          'creatorUid': entry.key,
          'title': 'New Incoming Order! 🛒',
          'message':
              'You received a new order for ${creatorItems.length} item(s) totaling ₹$subtotal from $buyerName.',
          'type': 'order',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'targetId': orderReferences[orderIndex++].id,
        });
      }
      await batch.commit();
    } catch (_) {
      // The order is already safely placed; creator dashboards also read the
      // order collection directly, so notification failure is non-blocking.
    }

    return orderReferences.map((reference) => reference.id).toList();
  }

  static String? _getNextValidStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Placed':
        return 'Confirmed';
      case 'Accepted':
        return 'Confirmed';
      case 'Confirmed':
        return 'Processing';
      case 'Processing':
        return 'In-Transit';
      case 'In-Transit':
        return 'Shipped';
      case 'Shipped':
        return 'Out for Delivery';
      case 'Out for Delivery':
        return 'Delivered';
      default:
        return null;
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
  }) async {
    final orderRef = firestore.collection('orders').doc(orderId);
    final orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw Exception('Order not found.');
    }

    final currentData = orderSnap.data() ?? <String, dynamic>{};
    final currentStatus = currentData['status'] as String? ?? 'Placed';

    if (status == 'Rejected') {
      final updateData = <String, dynamic>{
        'status': 'Rejected',
        'rejectionReason': rejectionReason ?? 'Order rejected by creator',
        'payoutStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await orderRef.update(updateData);
      return;
    }

    final expectedNextStatus = _getNextValidStatus(currentStatus);
    if (expectedNextStatus == null) {
      throw Exception(
        'Order is already in a final status ($currentStatus) and cannot be updated further.',
      );
    }

    if (status != expectedNextStatus) {
      throw Exception(
        'Invalid status transition from "$currentStatus" to "$status". The next valid status is "$expectedNextStatus".',
      );
    }

    if (status == 'Confirmed' || status == 'Accepted') {
      await firestore.runTransaction((transaction) async {
        final txOrderSnap = await transaction.get(orderRef);
        if (!txOrderSnap.exists) {
          throw Exception('Order not found.');
        }

        final orderData = txOrderSnap.data() ?? <String, dynamic>{};
        final txStatus = orderData['status'] as String? ?? '';

        if (orderData['stockReserved'] != true &&
            txStatus != 'Confirmed' &&
            txStatus != 'Accepted') {
          final rawItems = orderData['items'] as List<dynamic>? ?? const [];
          final itemsToUpdate = <_RepoItemStockUpdate>[];

          for (final rawItem in rawItems) {
            if (rawItem is! Map) continue;
            final itemMap = Map<String, dynamic>.from(rawItem);
            final productId = itemMap['productId'] as String? ?? '';
            final quantity = (itemMap['quantity'] as num?)?.round() ?? 1;
            final itemName = itemMap['name'] as String? ?? 'Product';

            if (productId.isNotEmpty) {
              final productRef = firestore
                  .collection('products')
                  .doc(productId);
              final productSnap = await transaction.get(productRef);
              itemsToUpdate.add(
                _RepoItemStockUpdate(
                  ref: productRef,
                  snap: productSnap,
                  quantity: quantity,
                  name: itemName,
                ),
              );
            }
          }

          for (final item in itemsToUpdate) {
            if (!item.snap.exists) {
              throw Exception(
                'Product "${item.name}" no longer exists in inventory.',
              );
            }

            final productData = item.snap.data() ?? <String, dynamic>{};
            final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;

            if (currentStock < item.quantity) {
              throw Exception(
                'Cannot confirm order: Insufficient stock for "${item.name}". Available: $currentStock, Ordered: ${item.quantity}.',
              );
            }

            final newStock = currentStock - item.quantity;
            if (newStock < 0) {
              throw Exception(
                'Cannot confirm order: Stock for "${item.name}" cannot become negative.',
              );
            }

            item.newStock = newStock;
          }

          for (final item in itemsToUpdate) {
            transaction.update(item.ref, {'stock': item.newStock});
          }
        }

        final updateData = <String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (rejectionReason != null) {
          updateData['rejectionReason'] = rejectionReason;
        }
        if (consignmentNumber != null && consignmentNumber.trim().isNotEmpty) {
          updateData['consignmentNumber'] = consignmentNumber.trim();
        }
        transaction.update(orderRef, updateData);
      });
    } else {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (consignmentNumber != null && consignmentNumber.trim().isNotEmpty) {
        updateData['consignmentNumber'] = consignmentNumber.trim();
      }
      if (status == 'Delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await orderRef.update(updateData);
    }
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
    final statuses = ['Placed', 'Confirmed', 'Processing', 'Delivered'];
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

class _RepoItemStockUpdate {
  final DocumentReference<Map<String, dynamic>> ref;
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final int quantity;
  final String name;
  int newStock;

  _RepoItemStockUpdate({
    required this.ref,
    required this.snap,
    required this.quantity,
    required this.name,
  }) : newStock = 0;
}
