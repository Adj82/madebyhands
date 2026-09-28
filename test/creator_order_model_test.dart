import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/features/creator/data/models/creator_order_model.dart';

void main() {
  test('creator order reads carrier and buyer customization choices', () {
    final order = CreatorOrderModel.fromJson({
      'buyerId': 'buyer-1',
      'buyerName': 'Suhani',
      'status': 'Shipped',
      'subtotal': 1250,
      'shippingAddress': 'Jaipur',
      'carrierName': 'India Post',
      'consignmentNumber': 'SP123456789IN',
      'items': [
        {
          'productId': 'product-1',
          'name': 'Custom vase',
          'quantity': 1,
          'unitPrice': 1250,
          'baseUnitPrice': 1000,
          'customizationPrice': 250,
          'customizations': {
            'Colour': ['Blue'],
            'Name': ['Suhani'],
          },
        },
      ],
    }, 'order-1');

    expect(order.carrierName, 'India Post');
    expect(order.consignmentNumber, 'SP123456789IN');
    expect(order.items.single.baseUnitPrice, 1000);
    expect(order.items.single.customizationPrice, 250);
    expect(order.items.single.customizations['Colour'], ['Blue']);
    expect(order.items.single.customizations['Name'], ['Suhani']);
  });
}
