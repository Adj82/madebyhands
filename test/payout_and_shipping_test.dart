import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_log_entry.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_log_repository.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_repository.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/add_product_page.dart';
import 'package:madebyhands/features/creator/presentation/pages/manage_bank_account_page.dart';
import 'package:madebyhands/init_dependencies.dart';

class _FakeCreatorRepository implements CreatorRepository {
  CreatorBankAccount? account;

  @override
  Future<Either<Failure, CreatorBankAccount?>> getCreatorBankAccount(
    String uid,
  ) async => right(account);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdminRepository implements AdminRepository {
  @override
  Future<Either<Failure, List<String>>> getCategories({
    bool seedDefaults = false,
  }) async => right(const ['Pottery']);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoLogs implements AdminLogRepository {
  @override
  Future<void> log({
    required AdminLogCategory category,
    required String action,
    required String summary,
    String targetId = '',
  }) async {}

  @override
  Stream<List<AdminLogEntry>> watchLogs({int limit = 300}) =>
      const Stream.empty();
}

final _profile = CreatorProfile(
  uid: 'c1',
  name: 'Asha Rao',
  profileImage: '',
  bio: '',
  location: '',
  socialLinks: [],
  portfolio: [],
  story: '',
);

Future<_FakeCreatorRepository> _open(
  WidgetTester tester,
  Widget page, {
  CreatorBankAccount? account,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _FakeCreatorRepository()..account = account;
  serviceLocator.registerSingleton<CreatorRepository>(repository);
  addTearDown(serviceLocator.reset);
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CreatorBloc(creatorRepository: repository)),
        BlocProvider(
          create: (_) => AdminBloc(
            adminRepository: _FakeAdminRepository(),
            logRepository: _NoLogs(),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightThemeMode, home: page),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

bool _obscured(WidgetTester tester, String hint) {
  final field = find.ancestor(
    of: find.text(hint),
    matching: find.byType(TextField),
  );
  return tester.widget<TextField>(field.first).obscureText;
}

void main() {
  const accountHint = 'Enter bank account number';
  const confirmHint = 'Re-enter bank account number';

  testWidgets('both account number fields can be revealed independently', (
    tester,
  ) async {
    await _open(tester, ManageBankAccountPage(profile: _profile));

    expect(_obscured(tester, accountHint), isTrue);
    expect(_obscured(tester, confirmHint), isTrue);

    final toggles = find.byIcon(Icons.visibility_outlined);
    expect(toggles, findsNWidgets(2));

    await tester.tap(toggles.first);
    await tester.pump();
    expect(_obscured(tester, accountHint), isFalse);
    expect(_obscured(tester, confirmHint), isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(_obscured(tester, confirmHint), isFalse);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
    await tester.pump();
    expect(_obscured(tester, accountHint), isTrue);
  });

  testWidgets('new product form warns when payout details are missing', (
    tester,
  ) async {
    await _open(tester, AddProductPage(profile: _profile));

    expect(
      find.textContaining('Add your payout details to get paid'),
      findsOneWidget,
    );
    expect(find.text('Add payout details'), findsOneWidget);
  });

  testWidgets('no warning once payout details exist', (tester) async {
    await _open(
      tester,
      AddProductPage(profile: _profile),
      account: const CreatorBankAccount(
        uid: 'c1',
        accountHolderName: 'Asha Rao',
        accountNumber: '123456789012',
        accountType: 'Savings',
        bankName: 'Test Bank',
        branchName: 'Main',
        ifscCode: 'TEST0001234',
      ),
    );

    expect(
      find.textContaining('Add your payout details to get paid'),
      findsNothing,
    );
  });

  testWidgets('the shipping field is labelled as an estimated timeline', (
    tester,
  ) async {
    await _open(tester, AddProductPage(profile: _profile));
    final label = find.text(
      'Estimated shipping timeline *',
      skipOffstage: false,
    );
    expect(label, findsOneWidget);
    expect(
      find.text('Shipping Information *', skipOffstage: false),
      findsNothing,
    );
  });
}
