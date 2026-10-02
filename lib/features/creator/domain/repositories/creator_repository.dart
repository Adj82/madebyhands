import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:madebyhands/core/error/failures.dart';
import 'package:madebyhands/core/services/payment_api.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_bank_account.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_order.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_product.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

/// Documents a creator submits for verification. They are stored privately
/// (`creator_verifications/{uid}`), never on the public profile.
class VerificationDocuments {
  final String businessName;
  final String address;
  final String latestPhotoUrl;
  final String idCardUrl;

  const VerificationDocuments({
    required this.businessName,
    required this.address,
    required this.latestPhotoUrl,
    required this.idCardUrl,
  });
}

abstract interface class CreatorRepository {
  Future<Either<Failure, CreatorProfile?>> getCreatorProfile(String uid);

  Future<Either<Failure, void>> saveCreatorProfile({
    required String uid,
    required String name,
    required File? profileImageFile,
    required String bio,
    required String location,
    required List<String> socialLinks,
    required List<File> portfolioImageFiles,
    required String story,
    String? existingProfileImageUrl,
    List<String>? existingPortfolioUrls,
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

  Future<Either<Failure, void>> addProduct(ProductInput input);

  /// Saves edits to [productId]. The listing returns to admin review and is
  /// hidden from buyers until approved again.
  Future<Either<Failure, void>> updateProduct(String productId, ProductInput input);

  Future<Either<Failure, void>> deleteProduct(String productId);

  /// Publishes or unpublishes an approved listing.
  Future<Either<Failure, void>> setProductPublished(String productId, bool published);

  /// Stock changes apply immediately without another admin review.
  Future<Either<Failure, void>> updateStock(String productId, int stock);

  Stream<List<CreatorProduct>> watchCreatorProducts(String uid);

  Stream<List<CreatorOrder>> watchCreatorOrders(String uid);

  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    String status, {
    String? consignmentNumber,
    String? carrierName,
  });

  /// Rejects a paid order through the payment API, which restores stock and
  /// refunds the buyer.
  Future<Either<Failure, RejectOrderResult>> rejectOrder(String orderId, String reason);

  Stream<List<CreatorNotification>> watchNotifications(String uid);
  Future<Either<Failure, void>> markNotificationAsRead(String notificationId);
  Future<Either<Failure, void>> markAllNotificationsAsRead(String uid);
  Future<Either<Failure, void>> deleteNotifications(List<String> notificationIds);

  Future<Either<Failure, CreatorBankAccount?>> getCreatorBankAccount(String uid);
  Future<Either<Failure, void>> saveCreatorBankAccount(CreatorBankAccount bankDetail);
}

/// Everything a creator enters on the product form.
class ProductInput {
  final String name;
  final String description;
  final List<File> newImageFiles;
  final List<String> existingImageUrls;
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
  final List<CustomizationInput> customizations;

  const ProductInput({
    required this.name,
    required this.description,
    this.newImageFiles = const [],
    this.existingImageUrls = const [],
    required this.categories,
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
