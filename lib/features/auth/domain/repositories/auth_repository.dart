import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, UserEntity>> signUpWithRole({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String role,
  });
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, UserEntity>> updateProfile({
    required String uid,
    required String name,
    required String phone,
  });
  Future<Either<Failure, void>> sendPasswordReset(String email);
  Future<Either<Failure, void>> requestAccountDeletion(UserEntity user);
  Future<Either<Failure, void>> signOut();
}
