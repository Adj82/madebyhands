import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/data/datasources/creator_remote_data_source.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
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

  @override
  Future<Either<Failure, void>> submitVerification({
    required String uid,
    required String creatorName,
    required String businessName,
    required String address,
    required File? latestPhotoFile,
    required File? idCardFile,
    required String existingLatestPhotoUrl,
    required String existingIdCardUrl,
  }) async {
    try {
      final existingProfile = await remoteDataSource.getCreatorProfile(uid);
      if (existingProfile == null) {
        return left(Failure('Creator profile not found. Please complete onboarding first.'));
      }

      String latestPhotoUrl = existingLatestPhotoUrl;
      if (latestPhotoFile != null) {
        latestPhotoUrl = await remoteDataSource.uploadVerificationFile(
          file: latestPhotoFile,
          uid: uid,
          fileName: 'latest_photo.jpg',
        );
      }

      String idCardUrl = existingIdCardUrl;
      if (idCardFile != null) {
        idCardUrl = await remoteDataSource.uploadVerificationFile(
          file: idCardFile,
          uid: uid,
          fileName: 'id_card.jpg',
        );
      }

      final updatedProfile = CreatorProfileModel(
        uid: uid,
        name: creatorName,
        profileImage: existingProfile.profileImage,
        bio: existingProfile.bio,
        category: existingProfile.category,
        location: existingProfile.location,
        socialLinks: existingProfile.socialLinks,
        portfolio: existingProfile.portfolio,
        story: existingProfile.story,
        verificationStatus: 'In-Process',
        businessName: businessName,
        address: address,
        latestPhoto: latestPhotoUrl,
        idCard: idCardUrl,
      );

      await remoteDataSource.saveCreatorProfile(updatedProfile);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProfile>>> getAllCreatorProfiles() async {
    try {
      final profiles = await remoteDataSource.getAllCreatorProfiles();
      return right(profiles);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateVerificationStatus(String uid, String status) async {
    try {
      await remoteDataSource.updateVerificationStatus(uid, status);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct({
    required String name,
    required String description,
    required List<File> imageFiles,
    required String category,
    required double price,
    required int stock,
    required String materials,
    required String dimensions,
    required String weight,
    required String shippingInfo,
    required String creatorUid,
    required String creatorName,
    bool isCustomizable = false,
    List<CustomizationInput> customizations = const [],
  }) async {
    try {
      final profile = await remoteDataSource.getCreatorProfile(creatorUid);
      if (profile == null || profile.verificationStatus != 'Verified') {
        return left(Failure('You must be a Verified Creator to add products.'));
      }

      final imageUrls = await remoteDataSource.uploadProductImages(
        images: imageFiles,
        uid: creatorUid,
        productName: name,
      );

      List<ProductCustomization> customizationEntities = [];
      if (isCustomizable) {
        for (final input in customizations) {
          final custImageUrls = await remoteDataSource.uploadCustomizationImages(
            images: input.imageFiles,
            uid: creatorUid,
            productName: name,
            customizationName: input.name,
          );
          customizationEntities.add(ProductCustomization(
            name: input.name,
            description: input.description,
            additionalPrice: input.additionalPrice,
            images: custImageUrls,
          ));
        }
      }

      final newProduct = CreatorProductModel(
        id: '',
        name: name,
        description: description,
        images: imageUrls,
        category: category,
        price: price,
        stock: stock,
        materials: materials,
        dimensions: dimensions,
        weight: weight,
        shippingInfo: shippingInfo,
        creatorUid: creatorUid,
        creatorName: creatorName,
        status: 'Pending Approval',
        isActive: false,
        isCustomizable: isCustomizable,
        customizations: customizationEntities,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.addProduct(newProduct);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getPendingProducts() async {
    try {
      final products = await remoteDataSource.getPendingProducts();
      return right(products);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getAdminAllProducts() async {
    try {
      final products = await remoteDataSource.getAdminAllProducts();
      return right(products);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getCreatorProducts(String uid) async {
    try {
      final products = await remoteDataSource.getCreatorProducts(uid);
      return right(products);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductStatus(String productId, String status) async {
    try {
      await remoteDataSource.updateProductStatus(productId, status);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
