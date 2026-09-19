import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/data/datasources/creator_remote_data_source.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';

class CreatorRepositoryImpl implements CreatorRepository {
  final CreatorRemoteDataSource remoteDataSource;

  CreatorRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(String uid) async {
    try {
      final profile = await remoteDataSource.getCreatorProfile(uid);
      return right(profile);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveCreatorProfile({
    required String uid,
    required String name,
    required File? profileImageFile,
    required String bio,
    required String category,
    required String location,
    required List<String> socialLinks,
    required List<File> portfolioImageFiles,
    required String story,
    String? existingProfileImageUrl,
    List<String>? existingPortfolioUrls,
  }) async {
    try {
      String profileImageUrl = existingProfileImageUrl ?? '';
      if (profileImageFile != null) {
        profileImageUrl = await remoteDataSource.uploadProfileImage(
          image: profileImageFile,
          uid: uid,
        );
      }

      List<String> portfolioUrls = existingPortfolioUrls ?? [];
      if (portfolioImageFiles.isNotEmpty) {
        final newUrls = await remoteDataSource.uploadPortfolioImages(
          images: portfolioImageFiles,
          uid: uid,
        );
        portfolioUrls.addAll(newUrls);
      }

      final profileModel = CreatorProfileModel(
        uid: uid,
        name: name,
        profileImage: profileImageUrl,
        bio: bio,
        category: category,
        location: location,
        socialLinks: socialLinks,
        portfolio: portfolioUrls,
        story: story,
      );

      await remoteDataSource.saveCreatorProfile(profileModel);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
