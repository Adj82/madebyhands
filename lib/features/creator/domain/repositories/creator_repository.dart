import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

abstract interface class CreatorRepository {
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(String uid);
  
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
  });

  Future<Either<Failure, void>> submitVerification({
    required String uid,
    required String creatorName,
    required String businessName,
    required String address,
    required File? latestPhotoFile,
    required File? idCardFile,
    required String existingLatestPhotoUrl,
    required String existingIdCardUrl,
  });

  Future<Either<Failure, List<CreatorProfile>>> getAllCreatorProfiles();

  Future<Either<Failure, void>> updateVerificationStatus(String uid, String status);

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
  });

  Future<Either<Failure, void>> updateProduct({
    required String productId,
    required String name,
    required String description,
    required List<File> newImageFiles,
    required List<String> existingImageUrls,
    required String category,
    required double price,
    required int stock,
    required String materials,
    required String dimensions,
    required String weight,
    required String shippingInfo,
    required String creatorUid,
    required String creatorName,
    required bool isCustomizable,
    required List<CustomizationInput> customizations,
    required bool hasChanges,
  });

  Future<Either<Failure, List<CreatorProduct>>> getPendingProducts();
  Future<Either<Failure, List<CreatorProduct>>> getAdminAllProducts();
  Future<Either<Failure, List<CreatorProduct>>> getCreatorProducts(String uid);

  Future<Either<Failure, void>> updateProductStatus(String productId, String status);

  Future<Either<Failure, List<CreatorOrder>>> getCreatorOrders(String uid);

  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status, {String? rejectionReason, String? consignmentNumber});
}

class CustomizationInput {
  final String name;
  final String description;
  final double additionalPrice;
  final List<File> imageFiles;
  final bool isMultipleSelection;
  final List<String> options;

  CustomizationInput({
    required this.name,
    required this.description,
    required this.additionalPrice,
    required this.isMultipleSelection,
    this.imageFiles = const [],
    this.options = const [],
  });
}
