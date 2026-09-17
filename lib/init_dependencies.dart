import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:madebyhands/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:madebyhands/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';
import 'package:madebyhands/features/auth/presentation/bloc/auth_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  try {
    // Initialize Firebase
    // Note: For Web, you should ideally pass DefaultFirebaseOptions.currentPlatform
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Core
  serviceLocator.registerLazySingleton(() => FirebaseAuth.instance);
  serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);
  serviceLocator.registerLazySingleton(() => GoogleSignIn());

  // Auth Feature
  _initAuth();
}

void _initAuth() {
  // Data Source
  serviceLocator.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: serviceLocator(),
      firestore: serviceLocator(),
      googleSignIn: serviceLocator(),
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
