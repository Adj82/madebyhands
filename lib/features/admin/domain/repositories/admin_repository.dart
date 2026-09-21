import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

abstract interface class AdminRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers(String role);
  Future<Either<Failure, void>> updateUserRole(String uid, String role);
  Future<Either<Failure, void>> toggleUserStatus(String uid, bool isActive);
  Future<Either<Failure, Map<String, double>>> getPlatformSettings();
  Future<Either<Failure, void>> updatePlatformSettings(double flatFee, double percentFee);
  Future<Either<Failure, List<AdminSupportTicket>>> getSupportTickets();
  Future<Either<Failure, List<CreatorProfile>>> getPendingVerifications();
  Future<Either<Failure, void>> approveCreator(String uid);
  Future<Either<Failure, void>> rejectCreator(String uid);
  Future<Either<Failure, List<String>>> getCategories();
  Future<Either<Failure, void>> addCategory(String name);
  Future<Either<Failure, void>> deleteCategory(String name);
  Future<Either<Failure, void>> suspendUser(String uid, bool isSuspended);
}
