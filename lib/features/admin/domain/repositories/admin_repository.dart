import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

abstract interface class AdminRepository {
  Future<Either<Failure, Map<String, double>>> getPlatformSettings();
  Future<Either<Failure, void>> updatePlatformSettings(
    double flatFee,
    double percentFee,
    double commissionThreshold,
  );
  Future<Either<Failure, List<CreatorProfile>>> getCreatorProfiles();
  Future<Either<Failure, void>> approveCreator(String uid);
  Future<Either<Failure, void>> rejectCreator(String uid, String reason);

  /// Platform categories. With [seedDefaults] an empty collection is filled
  /// with the defaults (admins only); otherwise the defaults are returned
  /// without writing.
  Future<Either<Failure, List<String>>> getCategories({bool seedDefaults = false});
  Future<Either<Failure, void>> addCategory(String name);
  Future<Either<Failure, void>> deleteCategory(String name);
  Future<Either<Failure, void>> suspendUser(String uid, bool isSuspended);
  Future<Either<Failure, void>> reviewProduct({
    required String productId,
    required bool approve,
    required String reviewerName,
    required String reviewerEmail,
    String? rejectionReason,
  });
}
