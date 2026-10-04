import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/theme/app_theme.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/creator/presentation/pages/creator_verification_page.dart';
import 'package:madebyhands/init_dependencies.dart';

class _FakeCreatorRepository implements CreatorRepository {
  CreatorProfile? profile;
  final submissions = <({String photo, String idCard})>[];

  @override
  Future<Either<Failure, VerificationDocuments?>> getVerificationDocuments(
    String uid,
  ) async => right(null);

  @override
  Future<Either<Failure, void>> submitVerification({
    required String uid,
    required String creatorName,
    required String businessName,
    required String address,
    required File? latestPhotoFile,
    required File? idCardFile,
    required String existingLatestPhotoUrl,
    required String existingIdCardUrl,
  }) async {
    submissions.add((photo: existingLatestPhotoUrl, idCard: existingIdCardUrl));
    return right(null);
  }

  @override
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(
    String uid,
  ) async => right(profile);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CreatorProfile _profile({String photo = '', String idCard = ''}) =>
    CreatorProfile(
      uid: 'c1',
      name: 'Asha Rao',
      profileImage: '',
      bio: '',
      location: '',
      socialLinks: const [],
      portfolio: const [],
      story: '',
      businessName: 'Rao Pottery',
      address: '12 Kumhar Lane, Jaipur',
      latestPhoto: photo,
      idCard: idCard,
    );

void main() {
  late _FakeCreatorRepository repository;

  Future<void> open(WidgetTester tester, CreatorProfile profile) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = _FakeCreatorRepository();
    repository.profile = profile;
    serviceLocator.registerSingleton<CreatorRepository>(repository);
    addTearDown(serviceLocator.reset);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => CreatorBloc(creatorRepository: repository),
        child: MaterialApp(
          theme: AppTheme.lightThemeMode,
          home: CreatorVerificationPage(profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('Submit for verification');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  const missing =
      'Please add both a recent photo of you and a photo of your PAN card / government ID.';

  testWidgets('the ID photo is marked required and cannot be skipped', (
    tester,
  ) async {
    await open(tester, _profile(photo: 'https://example.invalid/me.jpg'));

    expect(find.text('PAN card / government ID *'), findsOneWidget);
    expect(find.textContaining('Optional'), findsNothing);

    await submit(tester);

    expect(find.text(missing), findsOneWidget);
    expect(repository.submissions, isEmpty);
  });

  testWidgets('the photo of you is still required', (tester) async {
    await open(tester, _profile(idCard: 'https://example.invalid/id.jpg'));

    await submit(tester);

    expect(find.text(missing), findsOneWidget);
    expect(repository.submissions, isEmpty);
  });

  testWidgets('submits once both photos are present', (tester) async {
    await open(
      tester,
      _profile(
        photo: 'https://example.invalid/me.jpg',
        idCard: 'https://example.invalid/id.jpg',
      ),
    );

    await submit(tester);

    expect(find.text(missing), findsNothing);
    expect(repository.submissions, hasLength(1));
    expect(
      repository.submissions.single.idCard,
      'https://example.invalid/id.jpg',
    );
  });
}
