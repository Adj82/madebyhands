import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

abstract interface class AdminRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers(String role);
  Future<Either<Failure, void>> updateUserRole(String uid, String role);
  Future<Either<Failure, void>> toggleUserStatus(String uid, bool isActive);
  Future<Either<Failure, Map<String, double>>> getPlatformSettings();
  Future<Either<Failure, void>> updatePlatformSettings(double flatFee, double percentFee);
  Future<Either<Failure, List<AdminSupportTicket>>> getSupportTickets();
}
