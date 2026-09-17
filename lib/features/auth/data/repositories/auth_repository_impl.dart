import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      if (user == null) {
        return left(Failure('Google sign in cancelled.'));
      }
      return right(user);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithRole(
        uid: uid,
        email: email,
        name: name,
        role: role,
      );
      return right(user);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUserData();
      if (user == null) {
        return left(Failure('User not logged in.'));
      }
      return right(user);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
