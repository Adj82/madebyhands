import 'package:madebyhands/core/services/payment_api.dart';
import 'package:madebyhands/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:madebyhands/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:madebyhands/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_repository.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:madebyhands/features/admin/presentation/bloc/admin_cubit.dart';
import 'package:madebyhands/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:madebyhands/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:madebyhands/features/buyer/data/firestore_buyer_repository.dart';
import 'package:madebyhands/features/buyer/domain/repositories/buyer_repository.dart';
import 'package:madebyhands/features/buyer/presentation/bloc/buyer_bloc.dart';
import 'package:madebyhands/features/creator/data/datasources/creator_remote_data_source.dart';
import 'package:madebyhands/features/creator/data/repositories/creator_repository_impl.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';
import 'package:madebyhands/features/creator/presentation/bloc/creator_bloc.dart';
import 'package:madebyhands/features/support/data/firestore_support_repository.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';

final serviceLocator = GetIt.instance;

const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

Future<void> initDependencies() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    // Hot restarts on Android can report the default app as already created.
    if (error.code != 'duplicate-app') rethrow;
  }

  // Core
  serviceLocator.registerLazySingleton(() => FirebaseAuth.instance);
  serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);
  serviceLocator.registerLazySingleton(() => FirebaseStorage.instance);
  serviceLocator.registerLazySingleton(
    () => GoogleSignIn(
      // Only the web build needs an explicit OAuth client id.
      clientId: _googleClientId.isEmpty ? null : _googleClientId,
    ),
  );

  // Auth Feature
  _initAuth();
  // Creator Feature
  _initCreator();
  // Buyer Feature
  _initBuyer();
  // Admin Feature
  _initAdmin();
  _initSharedData();
}

void _initSharedData() {
  serviceLocator.registerLazySingleton(() => OrderActionsApi());
  serviceLocator.registerLazySingleton(() => UserModerationApi());
  serviceLocator.registerLazySingleton<SupportRepository>(
    () => FirestoreSupportRepository(firestore: serviceLocator()),
  );
}

void _initAuth() {
  // Data Source
  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: serviceLocator(),
      firestore: serviceLocator(),
      googleSignIn: serviceLocator(),
      storage: serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(serviceLocator()),
  );

  // Bloc
  serviceLocator.registerLazySingleton(
    () => AuthBloc(authRepository: serviceLocator()),
  );
}

void _initCreator() {
  // Data Source
  serviceLocator.registerFactory<CreatorRemoteDataSource>(
    () => CreatorRemoteDataSourceImpl(
      firestore: serviceLocator(),
      firebaseStorage: serviceLocator(),
    ),
  );

  // Repository
  serviceLocator.registerFactory<CreatorRepository>(
    () => CreatorRepositoryImpl(
      serviceLocator(),
      orderActionsApi: serviceLocator(),
    ),
  );

  // Bloc
  serviceLocator.registerLazySingleton(
    () => CreatorBloc(creatorRepository: serviceLocator()),
  );
}

void _initBuyer() {
  // Repository
  serviceLocator.registerLazySingleton<BuyerRepository>(
    () => FirestoreBuyerRepository(firestore: serviceLocator()),
  );

  serviceLocator.registerLazySingleton(
    () => BuyerBloc(repository: serviceLocator()),
  );
}

void _initAdmin() {
  // Data Source
  serviceLocator.registerFactory<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(serviceLocator()),
  );

  // Repository
  serviceLocator.registerFactory<AdminRepository>(
    () => AdminRepositoryImpl(serviceLocator(), userModerationApi: serviceLocator()),
  );

  // Cubit/Bloc
  serviceLocator.registerFactory(() => AdminCubit());

  serviceLocator.registerLazySingleton(
    () => AdminBloc(adminRepository: serviceLocator()),
  );
}
