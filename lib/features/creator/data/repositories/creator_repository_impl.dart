import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/data/datasources/creator_remote_data_source.dart';
import 'package:madebyhands/features/creator/data/models/creator_bank_account_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_product_model.dart';
import 'package:madebyhands/features/creator/data/models/creator_profile_model.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';
import 'package:madebyhands/features/creator/domain/repositories/creator_repository.dart';

class CreatorRepositoryImpl implements CreatorRepository {
  final CreatorRemoteDataSource remoteDataSource;

  CreatorRepositoryImpl(this.remoteDataSource);

  String _cleanExceptionMessage(Object e) {
    var msg = e.toString();
    while (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg.trim();
  }

  @override
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(String uid) async {
    try {
      final profile = await remoteDataSource.getCreatorProfile(uid);
      return right(profile);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
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
    File? panCardFile,
    File? aadhaarCardFile,
    String? existingPanCardUrl,
    String? existingAadhaarCardUrl,
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

      String panCardUrl = existingPanCardUrl ?? '';
      if (panCardFile != null) {
        final ext = panCardFile.path.contains('.')
            ? panCardFile.path.split('.').last.toLowerCase()
            : 'jpg';
        panCardUrl = await remoteDataSource.uploadVerificationFile(
          file: panCardFile,
          uid: uid,
          fileName: 'pan_card.$ext',
        );
      }

      String aadhaarCardUrl = existingAadhaarCardUrl ?? '';
      if (aadhaarCardFile != null) {
        final ext = aadhaarCardFile.path.contains('.')
            ? aadhaarCardFile.path.split('.').last.toLowerCase()
            : 'jpg';
        aadhaarCardUrl = await remoteDataSource.uploadVerificationFile(
          file: aadhaarCardFile,
          uid: uid,
          fileName: 'aadhaar_card.$ext',
        );
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
        panCard: panCardUrl,
        aadhaarCard: aadhaarCardUrl,
      );

      await remoteDataSource.saveCreatorProfile(profileModel);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
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
        return left(
          Failure(
            'Creator profile not found. Please complete onboarding first.',
          ),
        );
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
      await remoteDataSource.updateVerificationStatus(uid, 'In-Process');
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProfile>>> getAllCreatorProfiles() async {
    try {
      final profiles = await remoteDataSource.getAllCreatorProfiles();
      return right(profiles);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateVerificationStatus(
    String uid,
    String status,
  ) async {
    try {
      await remoteDataSource.updateVerificationStatus(uid, status);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct({
    required String name,
    required String description,
    required List<File> imageFiles,
    required String category,
    List<String> categories = const [],
    required double price,
    required int stock,
    required String materials,
    required String dimensions,
    required String weight,
    required String shippingInfo,
    required String creatorUid,
    required String creatorName,
    bool isCustomizable = false,
    bool? isFramed,
    List<String> predefinedCustomizations = const [],
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
          final custImageUrls = await remoteDataSource
              .uploadCustomizationImages(
                images: input.imageFiles,
                uid: creatorUid,
                productName: name,
                customizationName: input.name,
              );
          customizationEntities.add(
            ProductCustomization(
              name: input.name,
              description: input.description,
              additionalPrice: input.additionalPrice,
              images: custImageUrls,
              isMultipleSelection: input.isMultipleSelection,
              options: input.options,
            ),
          );
        }
      }

      final categoriesList = categories.isNotEmpty
          ? categories
          : (category.isNotEmpty ? [category] : <String>[]);
      final categoryStr = categoriesList.isNotEmpty
          ? categoriesList.join(', ')
          : category;

      final newProduct = CreatorProductModel(
        id: '',
        name: name,
        description: description,
        images: imageUrls,
        category: categoryStr,
        categories: categoriesList,
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
        isFramed: isFramed,
        predefinedCustomizations: isCustomizable
            ? predefinedCustomizations
            : const [],
        customizations: customizationEntities,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.addProduct(newProduct);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct({
    required String productId,
    required String name,
    required String description,
    required List<File> newImageFiles,
    required List<String> existingImageUrls,
    required String category,
    List<String> categories = const [],
    required double price,
    required int stock,
    required String materials,
    required String dimensions,
    required String weight,
    required String shippingInfo,
    required String creatorUid,
    required String creatorName,
    required bool isCustomizable,
    bool? isFramed,
    List<String> predefinedCustomizations = const [],
    required List<CustomizationInput> customizations,
    required bool hasChanges,
  }) async {
    try {
      if (!hasChanges) {
        return right(null);
      }

      // 1. Upload New Images if any
      List<String> finalImageUrls = List.from(existingImageUrls);
      if (newImageFiles.isNotEmpty) {
        final newUrls = await remoteDataSource.uploadProductImages(
          images: newImageFiles,
          uid: creatorUid,
          productName: name,
        );
        finalImageUrls.addAll(newUrls);
      }

      // 2. Handle Customizations
      List<ProductCustomization> customizationEntities = [];
      if (isCustomizable) {
        for (final input in customizations) {
          final custImageUrls = await remoteDataSource
              .uploadCustomizationImages(
                images: input.imageFiles,
                uid: creatorUid,
                productName: name,
                customizationName: input.name,
              );
          customizationEntities.add(
            ProductCustomization(
              name: input.name,
              description: input.description,
              additionalPrice: input.additionalPrice,
              images: custImageUrls,
              isMultipleSelection: input.isMultipleSelection,
              options: input.options,
            ),
          );
        }
      }

      // 3. Get existing product to store in history
      final allCreatorProductsRes = await remoteDataSource.getCreatorProducts(
        creatorUid,
      );
      final existingProduct = allCreatorProductsRes.firstWhere(
        (p) => p.id == productId,
      );

      final categoriesList = categories.isNotEmpty
          ? categories
          : (category.isNotEmpty ? [category] : <String>[]);
      final categoryStr = categoriesList.isNotEmpty
          ? categoriesList.join(', ')
          : category;

      final updatedProduct = CreatorProductModel(
        id: productId,
        name: name,
        description: description,
        images: finalImageUrls,
        category: categoryStr,
        categories: categoriesList,
        price: price,
        stock: stock,
        materials: materials,
        dimensions: dimensions,
        weight: weight,
        shippingInfo: shippingInfo,
        creatorUid: creatorUid,
        creatorName: creatorName,
        status: 'Pending Approval', // Reset status
        isActive: false, // Hide from storefront
        isCustomizable: isCustomizable,
        isFramed: isFramed,
        predefinedCustomizations: isCustomizable
            ? predefinedCustomizations
            : const [],
        customizations: customizationEntities,
        createdAt: existingProduct.createdAt,
        editHistory: {
          'previousName': existingProduct.name,
          'previousDescription': existingProduct.description,
          'previousPrice': existingProduct.price,
          'previousCategory': existingProduct.category,
          'previousStock': existingProduct.stock,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await remoteDataSource.updateProduct(updatedProduct);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getPendingProducts() async {
    try {
      final products = await remoteDataSource.getPendingProducts();
      return right(products);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getAdminAllProducts() async {
    try {
      final products = await remoteDataSource.getAdminAllProducts();
      return right(products);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorProduct>>> getCreatorProducts(
    String uid,
  ) async {
    try {
      final products = await remoteDataSource.getCreatorProducts(uid);
      return right(products);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
    String? rejectionReason,
  }) async {
    try {
      await remoteDataSource.updateProductStatus(
        productId,
        status,
        approvedBy: approvedBy,
        approvedByEmail: approvedByEmail,
        rejectionReason: rejectionReason,
      );
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorOrder>>> getCreatorOrders(
    String uid,
  ) async {
    try {
      final orders = await remoteDataSource.getCreatorOrders(uid);
      return right(orders);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
    String? carrierName,
  }) async {
    try {
      await remoteDataSource.updateOrderStatus(
        orderId,
        status,
        rejectionReason: rejectionReason,
        consignmentNumber: consignmentNumber,
        carrierName: carrierName,
      );
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<CreatorNotification>>> getCreatorNotifications(
    String creatorUid,
  ) async {
    try {
      final notifications = await remoteDataSource.getCreatorNotifications(
        creatorUid,
      );
      return right(notifications.cast<CreatorNotification>());
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      await remoteDataSource.markNotificationAsRead(notificationId);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(
    String creatorUid,
  ) async {
    try {
      await remoteDataSource.markAllNotificationsAsRead(creatorUid);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotifications(
    List<String> notificationIds,
  ) async {
    try {
      await remoteDataSource.deleteNotifications(notificationIds);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, CreatorBankAccount?>> getCreatorBankAccount(
    String uid,
  ) async {
    try {
      final bankDetail = await remoteDataSource.getCreatorBankAccount(uid);
      return right(bankDetail);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> saveCreatorBankAccount(
    CreatorBankAccount bankDetail,
  ) async {
    try {
      final model = CreatorBankAccountModel(
        uid: bankDetail.uid,
        accountHolderName: bankDetail.accountHolderName,
        accountNumber: bankDetail.accountNumber,
        accountType: bankDetail.accountType,
        bankName: bankDetail.bankName,
        branchName: bankDetail.branchName,
        ifscCode: bankDetail.ifscCode,
        upiId: bankDetail.upiId,
        panNumber: bankDetail.panNumber,
      );
      await remoteDataSource.saveCreatorBankAccount(model);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }
}
