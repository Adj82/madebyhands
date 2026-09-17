import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, UserEntity>> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String role,
  });
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> signOut();
}
