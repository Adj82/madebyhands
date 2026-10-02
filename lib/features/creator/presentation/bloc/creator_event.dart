part of 'creator_bloc.dart';

@immutable
sealed class CreatorEvent {}

/// Loads the creator profile for [uid] (or refreshes it silently).
final class CreatorCheckProfileExists extends CreatorEvent {
  final String uid;
  final bool silent;
  CreatorCheckProfileExists(this.uid, {this.silent = false});
}

/// Clears the session on sign-out.
final class CreatorSessionEnded extends CreatorEvent {}

final class CreatorSubmitOnboarding extends CreatorEvent {
  final String uid;
  final String name;
  final File? profileImageFile;
  final String bio;
  final String category;
  final String location;
  final List<String> socialLinks;
  final List<File> portfolioImageFiles;
  final String story;
  final String? existingProfileImageUrl;
  final List<String>? existingPortfolioUrls;
  final File? panCardFile;
  final File? aadhaarCardFile;
  final String? existingPanCardUrl;
  final String? existingAadhaarCardUrl;

  CreatorSubmitOnboarding({
    required this.uid,
    required this.name,
    this.profileImageFile,
    required this.bio,
    required this.category,
    required this.location,
    required this.socialLinks,
    required this.portfolioImageFiles,
    required this.story,
    this.existingProfileImageUrl,
    this.existingPortfolioUrls,
    this.panCardFile,
    this.aadhaarCardFile,
    this.existingPanCardUrl,
    this.existingAadhaarCardUrl,
  });
}

final class CreatorSubmitVerification extends CreatorEvent {
  final String uid;
  final String creatorName;
  final String businessName;
  final String address;
  final File? latestPhotoFile;
  final File? idCardFile;
  final String existingLatestPhotoUrl;
  final String existingIdCardUrl;

  CreatorSubmitVerification({
    required this.uid,
    required this.creatorName,
    required this.businessName,
    required this.address,
    required this.latestPhotoFile,
    required this.idCardFile,
    required this.existingLatestPhotoUrl,
    required this.existingIdCardUrl,
  });
}

/// Creates a product, or updates [productId] when it is set.
final class CreatorSaveProduct extends CreatorEvent {
  final String? productId;
  final ProductInput input;
  CreatorSaveProduct({this.productId, required this.input});
}

final class CreatorDeleteProduct extends CreatorEvent {
  final String productId;
  CreatorDeleteProduct(this.productId);
}

final class CreatorSetProductPublished extends CreatorEvent {
  final String productId;
  final bool published;
  CreatorSetProductPublished({required this.productId, required this.published});
}

final class CreatorUpdateStock extends CreatorEvent {
  final String productId;
  final int stock;
  CreatorUpdateStock({required this.productId, required this.stock});
}

final class CreatorUpdateOrderStatus extends CreatorEvent {
  final String orderId;
  final String status;
  final String? consignmentNumber;
  final String? carrierName;

  CreatorUpdateOrderStatus({
    required this.orderId,
    required this.status,
    this.consignmentNumber,
    this.carrierName,
  });
}

final class CreatorRejectOrder extends CreatorEvent {
  final String orderId;
  final String reason;
  CreatorRejectOrder({required this.orderId, required this.reason});
}

final class CreatorSaveBankAccount extends CreatorEvent {
  final CreatorBankAccount bankDetail;
  CreatorSaveBankAccount(this.bankDetail);
}
