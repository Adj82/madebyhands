import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/data/mock_buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/arch_backdrop.dart';
import 'package:madebyhands/features/buyer/presentation/widgets/buyer_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in const [
    Size(320, 560),
    Size(360, 780),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets(
      'fills ${size.width.toInt()}x${size.height.toInt()} without errors',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: ArchBackdrop(),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ArchBackdrop)), size);
      },
    );
  }

  testWidgets('on a wide screen the home content stays inside the arch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final buyer = UserEntity(
      uid: 'buyer-1',
      email: 'suhani@example.com',
      name: 'Suhani',
      role: 'buyer',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: BlocProvider(
          create: (_) => BuyerBloc(repository: MockBuyerRepository())
            ..add(BuyerWatchProducts())
            ..add(BuyerWatchFavorites(buyer.uid)),
          child: BuyerDashboardPage(user: buyer, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const archLeft = (1440 - ArchBackdrop.defaultMaxArchWidth) / 2;
    const archRight = archLeft + ArchBackdrop.defaultMaxArchWidth;
    for (final finder in [
      find.text('Hello, Suhani'),
      find.text('Interesting Facts & Stories'),
      find.byIcon(Icons.search),
    ]) {
      final rect = tester.getRect(finder.first);
      expect(rect.left, greaterThanOrEqualTo(archLeft));
      expect(rect.right, lessThanOrEqualTo(archRight));
    }
  });

  testWidgets('the arch and the logo start below the status bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    final buyer = UserEntity(
      uid: 'buyer-1',
      email: 'suhani@example.com',
      name: 'Suhani',
      role: 'buyer',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: BlocProvider(
          create: (_) => BuyerBloc(repository: MockBuyerRepository())
            ..add(BuyerWatchProducts())
            ..add(BuyerWatchFavorites(buyer.uid)),
          child: BuyerDashboardPage(user: buyer, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ArchBackdrop),
        matching: find.byType(CustomPaint),
      ),
    );
    final archTop = (paint.painter! as ArchBackdropPainter).top;
    // The tip tucks into the empty last few pixels of the status bar.
    expect(archTop, inInclusiveRange(30, 40));

    final greeting = tester.getRect(find.text('Hello, Suhani'));
    expect(greeting.top, greaterThan(archTop + 60));
  });

  testWidgets('the other tabs sit below a scalloped pink header', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);

    final buyer = UserEntity(
      uid: 'buyer-1',
      email: 'suhani@example.com',
      name: 'Suhani',
      role: 'buyer',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeMode,
        home: BlocProvider(
          create: (_) => BuyerBloc(repository: MockBuyerRepository())
            ..add(BuyerWatchProducts())
            ..add(BuyerWatchFavorites(buyer.uid)),
          child: BuyerDashboardPage(user: buyer, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Shop, Wishlist, Cart and Account each get the frame; Home has the arch.
    expect(find.byType(BuyerTabFrame, skipOffstage: false), findsNWidgets(4));

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();

    final header = tester.getRect(find.byType(ScallopedHeader));
    expect(header.top, 0);
    expect(header.bottom, 40 + ScallopedHeader.depth);
    final heading = tester.getRect(find.text('Explore handmade'));
    expect(
      heading.top,
      greaterThanOrEqualTo(40 + ScallopedHeader.contentInset),
    );
    expect(tester.takeException(), isNull);
  });
}
