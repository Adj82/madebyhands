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
  final CreatorRemoteDataSourceImpl remoteDataSource;

  CreatorRepositoryImpl(this.remoteDataSource);

  String _cleanExceptionMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
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
      var profileImageUrl = existingProfileImageUrl ?? '';
      if (profileImageFile != null) {
        profileImageUrl = await remoteDataSource.uploadProfileImage(
          image: profileImageFile,
          uid: uid,
        );
      }

      var portfolioUrls = <String>[];
      if (existingPortfolioUrls != null) {
        portfolioUrls.addAll(existingPortfolioUrls);
      }
      if (portfolioImageFiles.isNotEmpty) {
        final uploaded = await remoteDataSource.uploadPortfolioImages(
          images: portfolioImageFiles,
          uid: uid,
        );
        portfolioUrls.addAll(uploaded);
      }

      var panCardUrl = existingPanCardUrl ?? '';
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

      var aadhaarCardUrl = existingAadhaarCardUrl ?? '';
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
  Future<Either<Failure, VerificationDocuments?>> getVerificationDocuments(
    String uid,
  ) async {
    try {
      final docModel = await remoteDataSource.getVerificationDocuments(uid);
      if (docModel == null) return right(null);
      return right(VerificationDocuments(
        businessName: docModel.businessName,
        address: docModel.address,
        latestPhotoUrl: docModel.latestPhoto,
        idCardUrl: docModel.idCard,
      ));
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
      var latestPhotoUrl = existingLatestPhotoUrl;
      if (latestPhotoFile != null) {
        latestPhotoUrl = await remoteDataSource.uploadVerificationFile(
          file: latestPhotoFile,
          uid: uid,
          fileName: 'latest_photo.jpg',
        );
      }

      var idCardUrl = existingIdCardUrl;
      if (idCardFile != null) {
        idCardUrl = await remoteDataSource.uploadVerificationFile(
          file: idCardFile,
          uid: uid,
          fileName: 'id_card.jpg',
        );
      }

      final existingProfile = await remoteDataSource.getCreatorProfile(uid);
      if (existingProfile != null) {
        final updatedModel = CreatorProfileModel(
          uid: existingProfile.uid,
          name: creatorName.isNotEmpty ? creatorName : existingProfile.name,
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
        await remoteDataSource.saveCreatorProfile(updatedModel);
      }
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
  Future<Either<Failure, void>> addProduct(ProductInput input) async {
    try {
      final imageUrls = await remoteDataSource.uploadProductImages(
        images: input.newImageFiles,
        uid: input.creatorUid,
        folder: input.name,
      );

      final customizationModels = <ProductCustomization>[];
      if (input.isCustomizable) {
        for (var customInput in input.customizations) {
          var custImageUrls = <String>[];
          if (customInput.imageFiles.isNotEmpty) {
            custImageUrls = await remoteDataSource.uploadCustomizationImages(
              images: customInput.imageFiles,
              uid: input.creatorUid,
              productName: input.name,
              customizationName: customInput.name,
            );
          }
          customizationModels.add(
            ProductCustomization(
              name: customInput.name,
              description: customInput.description,
              additionalPrice: customInput.additionalPrice,
              images: custImageUrls,
              isMultipleSelection: customInput.isMultipleSelection,
              options: customInput.options,
            ),
          );
        }
      }

      final categoriesList = input.categories.isNotEmpty
          ? input.categories
          : (input.category.isNotEmpty ? [input.category] : <String>[]);
      final categoryStr = categoriesList.isNotEmpty
          ? categoriesList.join(', ')
          : input.category;

      final newProduct = CreatorProductModel(
        id: '',
        name: input.name,
        description: input.description,
        images: imageUrls,
        category: categoryStr,
        categories: categoriesList,
        price: input.price,
        stock: input.stock,
        materials: input.materials,
        dimensions: input.dimensions,
        weight: input.weight,
        shippingInfo: input.shippingInfo,
        creatorUid: input.creatorUid,
        creatorName: input.creatorName,
        status: 'Pending Approval',
        isActive: false,
        isCustomizable: input.isCustomizable,
        isFramed: input.isFramed,
        predefinedCustomizations: input.predefinedCustomizations,
        customizations: customizationModels,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.addProduct(newProduct);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(
    String productId,
    ProductInput input,
  ) async {
    try {
      var finalImageUrls = List<String>.from(input.existingImageUrls);
      if (input.newImageFiles.isNotEmpty) {
        final uploaded = await remoteDataSource.uploadProductImages(
          images: input.newImageFiles,
          uid: input.creatorUid,
          folder: input.name,
        );
        finalImageUrls.addAll(uploaded);
      }

      final customizationModels = <ProductCustomization>[];
      if (input.isCustomizable) {
        for (var customInput in input.customizations) {
          var custImageUrls = List<String>.from(customInput.existingImageUrls);
          if (customInput.imageFiles.isNotEmpty) {
            final uploadedCust = await remoteDataSource.uploadCustomizationImages(
              images: customInput.imageFiles,
              uid: input.creatorUid,
              productName: input.name,
              customizationName: customInput.name,
            );
            custImageUrls.addAll(uploadedCust);
          }
          customizationModels.add(
            ProductCustomization(
              name: customInput.name,
              description: customInput.description,
              additionalPrice: customInput.additionalPrice,
              images: custImageUrls,
              isMultipleSelection: customInput.isMultipleSelection,
              options: customInput.options,
            ),
          );
        }
      }

      final categoriesList = input.categories.isNotEmpty
          ? input.categories
          : (input.category.isNotEmpty ? [input.category] : <String>[]);
      final categoryStr = categoriesList.isNotEmpty
          ? categoriesList.join(', ')
          : input.category;

      final updatedProduct = CreatorProductModel(
        id: productId,
        name: input.name,
        description: input.description,
        images: finalImageUrls,
        category: categoryStr,
        categories: categoriesList,
        price: input.price,
        stock: input.stock,
        materials: input.materials,
        dimensions: input.dimensions,
        weight: input.weight,
        shippingInfo: input.shippingInfo,
        creatorUid: input.creatorUid,
        creatorName: input.creatorName,
        status: 'Pending Approval',
        isActive: false,
        isCustomizable: input.isCustomizable,
        isFramed: input.isFramed,
        predefinedCustomizations: input.isCustomizable
            ? input.predefinedCustomizations
            : const [],
        customizations: customizationModels,
        createdAt: DateTime.now(),
      );

      await remoteDataSource.updateProduct(updatedProduct);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    try {
      await remoteDataSource.deleteProduct(productId);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> setProductPublished(String productId, bool published) async {
    try {
      await remoteDataSource.setProductPublished(productId, published);
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateStock(String productId, int stock) async {
    try {
      await remoteDataSource.updateStock(productId, stock);
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
  Stream<List<CreatorProduct>> watchCreatorProducts(String uid) =>
      remoteDataSource.watchCreatorProducts(uid);

  @override
  Stream<List<CreatorOrder>> watchCreatorOrders(String uid) =>
      remoteDataSource.watchCreatorOrders(uid);

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
  Future<Either<Failure, void>> rejectOrder(String orderId, String reason) async {
    try {
      await remoteDataSource.updateOrderStatus(
        orderId,
        'Rejected',
        rejectionReason: reason,
      );
      return right(null);
    } catch (e) {
      return left(Failure(_cleanExceptionMessage(e)));
    }
  }

  @override
  Stream<List<CreatorNotification>> watchNotifications(String uid) =>
      remoteDataSource.watchNotifications(uid);

  @override
  Future<Either<Failure, List<CreatorNotification>>> getCreatorNotifications(
    String creatorUid,
  ) async {
    try {
      final notifications = await remoteDataSource.getCreatorNotifications(
        creatorUid,
      );
      return right(notifications);
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
      final bankAccount = await remoteDataSource.getCreatorBankAccount(uid);
      return right(bankAccount);
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
