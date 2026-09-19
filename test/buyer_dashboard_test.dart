import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/buyer/data/mock_buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/buyer/presentation/pages/buyer_dashboard_page.dart';

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
        child: BuyerDashboardPage(
          user: buyer,
          onLogout: () {},
        ),
      ),
    );
  }

  testWidgets('buyer can browse and search products', (tester) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('Hello, Suhani'), findsOneWidget);
    expect(find.text('Handpicked for you'), findsOneWidget);

    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pottery');
    await tester.pump();

    expect(find.text('Blue Pottery Vase'), findsOneWidget);
  });
}
