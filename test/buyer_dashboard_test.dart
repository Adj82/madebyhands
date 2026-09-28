import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/data/mock_buyer_repository.dart';
import 'package:madebyhands/features/buyer/data/mock_products.dart';
import 'package:madebyhands/features/buyer/domain/entities/buyer_order.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/order_detail_page.dart';
import 'package:madebyhands/features/buyer/presentation/pages/product_details_page.dart';

void main() {
  final buyer = UserEntity(
    uid: 'buyer-1',
    email: 'suhani@example.com',
    name: 'Suhani',
    role: 'buyer',
  );

  Widget buildDashboard() {
    return MaterialApp(
      theme: AppTheme.lightThemeMode,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => BuyerBloc(repository: MockBuyerRepository())
              ..add(BuyerWatchProducts())
              ..add(BuyerWatchFavorites(buyer.uid)),
          ),
          // We provide a dummy AuthBloc since the UI needs it for Logout
          // but we won't trigger any real auth actions here
        ],
        child: BuyerDashboardPage(user: buyer, onLogout: () {}),
      ),
    );
  }

  testWidgets('buyer can browse and search products', (tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Hello, Suhani'), findsOneWidget);
    expect(find.textContaining('21 Craft Lane'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Handpicked for you'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Handpicked for you'), findsOneWidget);
    expect(find.text('Shop by craft'), findsNothing);

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter by category'), findsOneWidget);
    expect(find.text('Paintings & Fine Art'), findsOneWidget);
    expect(find.text('Pottery, Ceramics & Clay'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Paintings & Fine Art'),
    );
    await tester.pump();
    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Pottery, Ceramics & Clay'),
    );
    await tester.pump();
    await tester.tap(find.text('Apply (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Filter (2)'), findsOneWidget);
    expect(find.text('Blue Pottery Vase'), findsOneWidget);
    expect(find.text('Handwoven Storage Basket'), findsNothing);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pottery');
    await tester.pump();

    expect(find.text('Blue Pottery Vase'), findsOneWidget);
  });

  testWidgets('product details updates quantity and bag badge', (tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pottery');
    await tester.pump();
    await tester.drag(
      find.byKey(const PageStorageKey('buyer-search')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Pottery Vase'));
    await tester.pumpAndSettle();

    expect(find.text('Add to cart'), findsOneWidget);
    expect(find.textContaining('Buy now'), findsOneWidget);
    expect(find.byTooltip('Open cart'), findsOneWidget);

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNWidgets(2));
    expect(find.byTooltip('Increase quantity'), findsOneWidget);
    expect(find.byTooltip('Decrease quantity'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsWidgets);

    await tester.tap(find.byTooltip('Open cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart'), findsOneWidget);
    expect(find.text('Blue Pottery Vase'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('buy now starts the direct checkout action', (tester) async {
    var buyNowPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: ProductDetailsPage(
          product: mockProducts.first,
          isSaved: false,
          cartQuantity: 0,
          cartCount: 0,
          onSave: () {},
          onCartQuantityChanged: (_) {},
          onOpenCart: () {},
          onBuyNow: () => buyNowPressed = true,
          buyerRepository: MockBuyerRepository(),
          buyerId: buyer.uid,
          buyerName: buyer.name,
        ),
      ),
    );

    await tester.tap(find.textContaining('Buy now'));
    await tester.pump();

    expect(buyNowPressed, isTrue);
  });

  testWidgets('verified buyer can submit and edit a product review', (
    tester,
  ) async {
    final repository = MockBuyerRepository();
    final product = mockProducts.firstWhere(
      (item) => item.id == 'blue-pottery',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: ProductDetailsPage(
          product: product,
          isSaved: false,
          cartQuantity: 0,
          cartCount: 0,
          onSave: () {},
          onCartQuantityChanged: (_) {},
          onOpenCart: () {},
          onBuyNow: () {},
          buyerRepository: repository,
          buyerId: buyer.uid,
          buyerName: buyer.name,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reviews & ratings'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reviews & ratings'), findsOneWidget);
    expect(find.text('Write a review'), findsOneWidget);
    expect(find.text('Verified purchase'), findsOneWidget);

    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 stars'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your review'),
      'Loved the finish and careful packaging.',
    );
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(
      find.text('Loved the finish and careful packaging.'),
      findsOneWidget,
    );
    expect(find.text('Edit your review'), findsOneWidget);
  });

  testWidgets('buyer cannot review a product without a delivered purchase', (
    tester,
  ) async {
    final product = mockProducts.firstWhere((item) => item.id == 'soy-candle');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: ProductDetailsPage(
          product: product,
          isSaved: false,
          cartQuantity: 0,
          cartCount: 0,
          onSave: () {},
          onCartQuantityChanged: (_) {},
          onOpenCart: () {},
          onBuyNow: () {},
          buyerRepository: MockBuyerRepository(),
          buyerId: buyer.uid,
          buyerName: buyer.name,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Reviews & ratings'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You can review this product after a delivered purchase.'),
      findsOneWidget,
    );
    expect(find.text('Write a review'), findsNothing);
  });

  testWidgets('buyer order details receive live seller shipment updates', (
    tester,
  ) async {
    final updates = StreamController<BuyerOrder>();
    addTearDown(updates.close);
    final placedOrder = BuyerOrder(
      id: 'ORDER-1',
      createdAt: DateTime(2026, 9, 28, 10),
      updatedAt: DateTime(2026, 9, 28, 10),
      status: 'Placed',
      total: 899,
      items: const [
        BuyerOrderItem(
          productId: 'blue-pottery',
          name: 'Blue Pottery Vase',
          quantity: 1,
          unitPrice: 899,
        ),
      ],
      deliveryAddress: '21 Craft Lane, Jaipur',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: OrderDetailPage(order: placedOrder, orderUpdates: updates.stream),
      ),
    );

    expect(find.text('Order placed'), findsWidgets);
    expect(find.text('Shipment progress'), findsOneWidget);

    updates.add(
      BuyerOrder(
        id: placedOrder.id,
        createdAt: placedOrder.createdAt,
        updatedAt: DateTime(2026, 9, 28, 14, 30),
        status: 'Shipped',
        total: placedOrder.total,
        items: placedOrder.items,
        deliveryAddress: placedOrder.deliveryAddress,
        consignmentNumber: 'SP123456789IN',
        carrierName: 'India Post',
      ),
    );
    await tester.pump();

    expect(find.text('Shipped'), findsWidgets);
    expect(find.text('Tracking details'), findsOneWidget);
    expect(find.text('SP123456789IN'), findsOneWidget);
    expect(find.text('India Post'), findsOneWidget);
  });
}
