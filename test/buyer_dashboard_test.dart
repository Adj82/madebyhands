import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';

void main() {
  final buyer = UserEntity(
    uid: 'buyer-1',
    email: 'suhani@example.com',
    name: 'Suhani',
    role: 'buyer',
  );

  Widget buildDashboard() => MaterialApp(
    theme: AppTheme.lightThemeMode,
    home: BuyerDashboardPage(user: buyer, onLogout: () {}),
  );

  testWidgets('buyer can browse and search products', (tester) async {
    await tester.pumpWidget(buildDashboard());

    expect(find.text('Hello, Suhani'), findsOneWidget);
    expect(find.text('Handpicked for you'), findsOneWidget);

    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pottery');
    await tester.pump();

    expect(find.text('Blue Pottery Vase'), findsOneWidget);
    expect(find.text('Handwoven Storage Basket'), findsNothing);
  });

  testWidgets('buyer can save a product', (tester) async {
    await tester.pumpWidget(buildDashboard());

    await tester.scrollUntilVisible(
      find.text('Handwoven Storage Basket'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Save item').first);
    await tester.pump();
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();

    expect(find.text('Handwoven Storage Basket'), findsOneWidget);
  });
}
