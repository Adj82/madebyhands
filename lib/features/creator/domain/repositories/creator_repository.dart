import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

abstract class CreatorRepository {
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
    File? panCardFile,
    File? aadhaarCardFile,
    String? existingPanCardUrl,
    String? existingAadhaarCardUrl,
  });

  Future<Either<Failure, VerificationDocuments?>> getVerificationDocuments(
    String uid,
  );

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

  Future<Either<Failure, void>> updateVerificationStatus(
    String uid,
    String status,
  );

  Future<Either<Failure, void>> addProduct(ProductInput input);
  Future<Either<Failure, void>> updateProduct(String productId, ProductInput input);
  Future<Either<Failure, void>> deleteProduct(String productId);
  Future<Either<Failure, void>> setProductPublished(String productId, bool published);
  Future<Either<Failure, void>> updateStock(String productId, int stock);

  Future<Either<Failure, List<CreatorProduct>>> getPendingProducts();
  Future<Either<Failure, List<CreatorProduct>>> getAdminAllProducts();
  Future<Either<Failure, List<CreatorProduct>>> getCreatorProducts(String uid);

  Stream<List<CreatorProduct>> watchCreatorProducts(String uid);
  Stream<List<CreatorOrder>> watchCreatorOrders(String uid);

  Future<Either<Failure, void>> updateProductStatus(
    String productId,
    String status, {
    String? approvedBy,
    String? approvedByEmail,
    String? rejectionReason,
  });

  Future<Either<Failure, List<CreatorOrder>>> getCreatorOrders(String uid);

  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    String status, {
    String? rejectionReason,
    String? consignmentNumber,
    String? carrierName,
  });

  Future<Either<Failure, void>> rejectOrder(String orderId, String reason);

  Stream<List<CreatorNotification>> watchNotifications(String uid);
  Future<Either<Failure, List<CreatorNotification>>> getCreatorNotifications(
    String creatorUid,
  );

  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);
  Future<Either<Failure, void>> markAllNotificationsAsRead(String creatorUid);
  Future<Either<Failure, void>> deleteNotifications(
    List<String> notificationIds,
  );

  Future<Either<Failure, CreatorBankAccount?>> getCreatorBankAccount(
    String uid,
  );

  Future<Either<Failure, void>> saveCreatorBankAccount(
    CreatorBankAccount bankDetail,
  );
}

class ProductInput {
  final String name;
  final String description;
  final List<File> newImageFiles;
  final List<String> existingImageUrls;
  final String category;
  final List<String> categories;
  final double price;
  final int stock;
  final String materials;
  final String dimensions;
  final String weight;
  final String shippingInfo;
  final String creatorUid;
  final String creatorName;
  final bool isCustomizable;
  final bool? isFramed;
  final List<String> predefinedCustomizations;
  final List<CustomizationInput> customizations;

  ProductInput({
    required this.name,
    required this.description,
    this.newImageFiles = const [],
    this.existingImageUrls = const [],
    this.category = '',
    this.categories = const [],
    required this.price,
    required this.stock,
    required this.materials,
    required this.dimensions,
    required this.weight,
    required this.shippingInfo,
    required this.creatorUid,
    required this.creatorName,
    this.isCustomizable = false,
    this.isFramed,
    this.predefinedCustomizations = const [],
    this.customizations = const [],
  });
}

class CustomizationInput {
  final String name;
  final String description;
  final double additionalPrice;
  final List<File> imageFiles;
  final List<String> existingImageUrls;
  final bool isMultipleSelection;
  final List<String> options;

  CustomizationInput({
    required this.name,
    required this.description,
    required this.additionalPrice,
    required this.isMultipleSelection,
    this.imageFiles = const [],
    this.existingImageUrls = const [],
    this.options = const [],
  });
}

class VerificationDocuments {
  final String businessName;
  final String address;
  final String latestPhotoUrl;
  final String idCardUrl;

  VerificationDocuments({
    required this.businessName,
    required this.address,
    required this.latestPhotoUrl,
    required this.idCardUrl,
  });
}
