import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_data.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_repository.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<UserEntity>>> getUsers(String role) async {
    try {
      final users = await remoteDataSource.getUsers(role);
      return right(users);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(String uid, String role) async {
    try {
      await remoteDataSource.updateUserRole(uid, role);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleUserStatus(String uid, bool isActive) async {
    try {
      await remoteDataSource.toggleUserStatus(uid, isActive);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getPlatformSettings() async {
    try {
      final settings = await remoteDataSource.getPlatformSettings();
      return right({
        'flatFee': (settings['flatFee'] as num).toDouble(),
        'percentFee': (settings['percentFee'] as num).toDouble(),
      });
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlatformSettings(double flatFee, double percentFee) async {
    try {
      await remoteDataSource.updatePlatformSettings(flatFee, percentFee);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AdminSupportTicket>>> getSupportTickets() async {
    try {
      final ticketsData = await remoteDataSource.getSupportTickets();
      final tickets = ticketsData.map((data) => AdminSupportTicket(
        id: data['id'],
        subject: data['subject'] ?? 'No Subject',
        lastMessage: data['lastMessage'] ?? '',
        isOpen: data['status'] == 'open',
      )).toList();
      return right(tickets);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProfile>>> getPendingVerifications() async {
    try {
      final profiles = await remoteDataSource.getPendingVerifications();
      return right(profiles);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveCreator(String uid) async {
    try {
      await remoteDataSource.approveCreator(uid);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectCreator(String uid) async {
    try {
      await remoteDataSource.rejectCreator(uid);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
