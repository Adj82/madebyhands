import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/core/constants/product_categories.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/buyer/data/mock_buyer_repository.dart';
import 'package:madebyhands/features/buyer/data/mock_products.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/category_details_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget buildPage(String category) => MaterialApp(
    theme: AppTheme.lightThemeMode,
    home: BlocProvider(
      create: (_) =>
          BuyerBloc(repository: MockBuyerRepository())
            ..add(BuyerWatchProducts()),
      child: CategoryDetailsPage(
        categoryTitle: category,
        userId: 'buyer-1',
        onProductTap: (_) {},
        onOpenCart: () {},
      ),
    ),
  );

  // A phone-sized surface: the page is a scroll view, so its hero is laid out
  // with unbounded height and must not rely on flex space.
  Future<void> usePhoneSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final category in kProductCategories) {
    testWidgets('category page lays out for "$category"', (tester) async {
      await usePhoneSurface(tester);
      await tester.pumpWidget(buildPage(category));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(category), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  }

  testWidgets('category page shows its products in a grid', (tester) async {
    await usePhoneSurface(tester);
    final category = kProductCategories.firstWhere(
      (category) => mockProducts.any(
        (product) => productMatchesCategory(product.allCategories, category),
      ),
    );
    await tester.pumpWidget(buildPage(category));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('category search and filters stay within the screen', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    await tester.pumpWidget(buildPage(kProductCategories.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search this category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzzz-no-such-product');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No matching works'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No matching works'), findsNothing);
  });
}
