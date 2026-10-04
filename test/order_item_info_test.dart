import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_detail_page.dart';
import 'package:madebyhands/features/orders/domain/order_status.dart';

void main() {
  final order = BuyerOrder(
    id: 'ORDER1234567890',
    createdAt: DateTime(2026, 10, 1, 10, 5),
    status: 'Confirmed',
    total: 2648,
    subtotal: 2598,
    platformFee: 50,
    items: const [
      BuyerOrderItem(
        productId: 'p1',
        name: 'Hand-painted Madhubani wall plate',
        quantity: 2,
        unitPrice: 1299,
        baseUnitPrice: 1199,
        customizationPrice: 100,
        customizations: {
          'Colour': ['Indigo blue'],
          'Engraving': ['Happy anniversary'],
        },
        // Not loadable in tests: the item must still render with a placeholder.
        image: 'https://example.invalid/plate.jpg',
      ),
      BuyerOrderItem(
        productId: 'p2',
        name: 'Clay diya set',
        quantity: 1,
        unitPrice: 349,
      ),
    ],
    deliveryAddress: 'Suhani Jain, 42 MG Road, Indore, Madhya Pradesh 452001',
  );

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: OrderDetailPage(order: order),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping an item opens its details and the order info', (
    tester,
  ) async {
    await open(tester);

    final item = find.text('Hand-painted Madhubani wall plate');
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();

    // The sheet repeats the name as its heading, on top of the list entry.
    expect(item, findsNWidgets(2));
    expect(find.text('Order info'), findsOneWidget);
    expect(find.text('Your customisation'), findsOneWidget);
    expect(find.text('Indigo blue'), findsOneWidget);
    expect(find.text('Happy anniversary'), findsOneWidget);
    expect(find.text('Base price'), findsOneWidget);
    expect(find.text('₹1199'), findsOneWidget);
    expect(find.text('Customisation'), findsOneWidget);
    expect(find.text(OrderStatus.buyerLabel('Confirmed')), findsWidgets);
    expect(find.textContaining('42 MG Road'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an item without customisation shows a simpler sheet', (
    tester,
  ) async {
    await open(tester);

    final item = find.text('Clay diya set');
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('Order info'), findsOneWidget);
    expect(find.text('Your customisation'), findsNothing);
    expect(find.text('Base price'), findsNothing);
    expect(find.text('Price each'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
