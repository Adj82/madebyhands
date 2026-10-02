import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/services/payment_api.dart';
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
  final OrderActionsApi orderActionsApi;

  CreatorRepositoryImpl(this.remoteDataSource, {required this.orderActionsApi});

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (error) {
      return left(Failure(friendlyErrorMessage(error)));
    }
  }

  @override
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(String uid) =>
      _guard<CreatorProfile?>(() => remoteDataSource.getCreatorProfile(uid));

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
  }) => _guard<void>(() async {
    var profileImageUrl = existingProfileImageUrl ?? '';
    if (profileImageFile != null) {
      profileImageUrl = await remoteDataSource.uploadProfileImage(
        image: profileImageFile,
        uid: uid,
      );
    }
    final portfolioUrls = [
      ...?existingPortfolioUrls,
      if (portfolioImageFiles.isNotEmpty)
        ...await remoteDataSource.uploadPortfolioImages(
          images: portfolioImageFiles,
          uid: uid,
        ),
    ];

    await remoteDataSource.saveCreatorProfile(
      CreatorProfileModel(
        uid: uid,
        name: name,
        profileImage: profileImageUrl,
        bio: bio,
        category: category,
        location: location,
        socialLinks: socialLinks,
        portfolio: portfolioUrls,
        story: story,
      ),
    );
  });

  @override
  Future<Either<Failure, VerificationDocuments?>> getVerificationDocuments(
    String uid,
  ) => _guard<VerificationDocuments?>(() async {
    final documents = await remoteDataSource.getVerificationDocuments(uid);
    if (documents == null) return null;
    return VerificationDocuments(
      businessName: documents.businessName,
      address: documents.address,
      latestPhotoUrl: documents.latestPhoto,
      idCardUrl: documents.idCard,
    );
  });

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
  }) => _guard<void>(() async {
    final latestPhoto = latestPhotoFile == null
        ? existingLatestPhotoUrl
        : await remoteDataSource.uploadVerificationFile(
            file: latestPhotoFile,
            uid: uid,
            fileName: 'latest_photo.jpg',
          );
    final idCard = idCardFile == null
        ? existingIdCardUrl
        : await remoteDataSource.uploadVerificationFile(
            file: idCardFile,
            uid: uid,
            fileName: 'id_card.jpg',
          );
    if (latestPhoto.isEmpty || idCard.isEmpty) {
      throw Exception('Please add both your photo and an ID document.');
    }
    await remoteDataSource.submitVerification(
      uid: uid,
      creatorName: creatorName,
      documents: VerificationDocumentsModel(
        businessName: businessName,
        address: address,
        latestPhoto: latestPhoto,
        idCard: idCard,
      ),
    );
  });

  Future<CreatorProductModel> _buildProduct(
    ProductInput input, {
    required String id,
    required String folder,
    CreatorProductModel? existing,
  }) async {
    final images = [
      ...input.existingImageUrls,
      if (input.newImageFiles.isNotEmpty)
        ...await remoteDataSource.uploadProductImages(
          images: input.newImageFiles,
          uid: input.creatorUid,
          folder: folder,
        ),
    ];
    if (images.isEmpty) {
      throw Exception('Add at least one product photo.');
    }

    final customizations = <ProductCustomization>[];
    if (input.isCustomizable) {
      for (final option in input.customizations) {
        customizations.add(
          ProductCustomization(
            name: option.name,
            description: option.description,
            additionalPrice: option.additionalPrice,
            isMultipleSelection: option.isMultipleSelection,
            options: option.options,
            images: [
              ...option.existingImageUrls,
              if (option.imageFiles.isNotEmpty)
                ...await remoteDataSource.uploadProductImages(
                  images: option.imageFiles,
                  uid: input.creatorUid,
                  folder: '$folder/${option.name}',
                ),
            ],
          ),
        );
      }
    }

    return CreatorProductModel(
      id: id,
      name: input.name,
      description: input.description,
      images: images,
      category: input.categories.join(', '),
      categories: input.categories,
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
      customizations: customizations,
      createdAt: existing?.createdAt ?? DateTime.now(),
      editHistory: existing == null
          ? null
          : {
              'previousName': existing.name,
              'previousDescription': existing.description,
              'previousPrice': existing.price,
              'previousCategory': existing.category,
              'previousStock': existing.stock,
              'timestamp': DateTime.now().toIso8601String(),
            },
    );
  }

  @override
  Future<Either<Failure, void>> addProduct(ProductInput input) => _guard<void>(() async {
    final profile = await remoteDataSource.getCreatorProfile(input.creatorUid);
    if (profile == null || !profile.isVerified) {
      throw Exception('Only verified creators can list products.');
    }
    final product = await _buildProduct(
      input,
      id: '',
      folder: '${DateTime.now().millisecondsSinceEpoch}_${input.name}',
    );
    await remoteDataSource.addProduct(product);
  });

  @override
  Future<Either<Failure, void>> updateProduct(String productId, ProductInput input) =>
      _guard<void>(() async {
        final existing = await remoteDataSource.getProduct(productId);
        if (existing == null) throw Exception('This product no longer exists.');
        final product = await _buildProduct(
          input,
          id: productId,
          folder: productId,
          existing: existing,
        );
        await remoteDataSource.updateProduct(product);
      });

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) =>
      _guard<void>(() => remoteDataSource.deleteProduct(productId));

  @override
  Future<Either<Failure, void>> setProductPublished(String productId, bool published) =>
      _guard<void>(() => remoteDataSource.setProductPublished(productId, published));

  @override
  Future<Either<Failure, void>> updateStock(String productId, int stock) =>
      _guard<void>(() => remoteDataSource.updateStock(productId, stock));

  @override
  Stream<List<CreatorProduct>> watchCreatorProducts(String uid) =>
      remoteDataSource.watchCreatorProducts(uid);

  @override
  Stream<List<CreatorOrder>> watchCreatorOrders(String uid) =>
      remoteDataSource.watchCreatorOrders(uid);

  @override
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    String status, {
    String? consignmentNumber,
    String? carrierName,
  }) => _guard<void>(
    () => remoteDataSource.updateOrderStatus(
      orderId,
      status,
      consignmentNumber: consignmentNumber,
      carrierName: carrierName,
    ),
  );

  @override
  Future<Either<Failure, RejectOrderResult>> rejectOrder(String orderId, String reason) =>
      _guard<RejectOrderResult>(
        () => orderActionsApi.rejectOrder(orderId: orderId, reason: reason),
      );

  @override
  Stream<List<CreatorNotification>> watchNotifications(String uid) =>
      remoteDataSource.watchNotifications(uid);

  @override
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId) =>
      _guard<void>(() => remoteDataSource.markNotificationAsRead(notificationId));

  @override
  Future<Either<Failure, void>> markAllNotificationsAsRead(String uid) =>
      _guard<void>(() => remoteDataSource.markAllNotificationsAsRead(uid));

  @override
  Future<Either<Failure, void>> deleteNotifications(List<String> notificationIds) =>
      _guard<void>(() => remoteDataSource.deleteNotifications(notificationIds));

  @override
  Future<Either<Failure, CreatorBankAccount?>> getCreatorBankAccount(String uid) =>
      _guard<CreatorBankAccount?>(() => remoteDataSource.getCreatorBankAccount(uid));

  @override
  Future<Either<Failure, void>> saveCreatorBankAccount(CreatorBankAccount bankDetail) =>
      _guard<void>(
        () => remoteDataSource.saveCreatorBankAccount(
          CreatorBankAccountModel(
            uid: bankDetail.uid,
            accountHolderName: bankDetail.accountHolderName,
            accountNumber: bankDetail.accountNumber,
            accountType: bankDetail.accountType,
            bankName: bankDetail.bankName,
            branchName: bankDetail.branchName,
            ifscCode: bankDetail.ifscCode,
            upiId: bankDetail.upiId,
            panNumber: bankDetail.panNumber,
          ),
        ),
      );
}
