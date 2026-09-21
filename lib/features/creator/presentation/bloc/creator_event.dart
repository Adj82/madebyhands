part of 'creator_bloc.dart';

@immutable
sealed class CreatorEvent {}

final class CreatorCheckProfileExists extends CreatorEvent {
  final String uid;
  CreatorCheckProfileExists(this.uid);
}

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

final class CreatorFetchAllProfiles extends CreatorEvent {}

final class CreatorUpdateVerificationStatus extends CreatorEvent {
  final String uid;
  final String status;
  CreatorUpdateVerificationStatus({required this.uid, required this.status});
}

final class CreatorAddProduct extends CreatorEvent {
  final String name;
  final String description;
  final List<File> imageFiles;
  final String category;
  final double price;
  final int stock;
  final String materials;
  final String dimensions;
  final String weight;
  final String shippingInfo;
  final String creatorUid;
  final String creatorName;
  final bool isCustomizable;
  final List<CustomizationInput> customizations;

  CreatorAddProduct({
    required this.name,
    required this.description,
    required this.imageFiles,
    required this.category,
    required this.price,
    required this.stock,
    required this.materials,
    required this.dimensions,
    required this.weight,
    required this.shippingInfo,
    required this.creatorUid,
    required this.creatorName,
    this.isCustomizable = false,
    this.customizations = const [],
  });
}

final class CreatorUpdateProduct extends CreatorEvent {
  final String productId;
  final String name;
  final String description;
  final List<File> newImageFiles;
  final List<String> existingImageUrls;
  final String category;
  final double price;
  final int stock;
  final String materials;
  final String dimensions;
  final String weight;
  final String shippingInfo;
  final String creatorUid;
  final String creatorName;
  final bool isCustomizable;
  final List<CustomizationInput> customizations;
  final bool hasChanges;

  CreatorUpdateProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.newImageFiles,
    required this.existingImageUrls,
    required this.category,
    required this.price,
    required this.stock,
    required this.materials,
    required this.dimensions,
    required this.weight,
    required this.shippingInfo,
    required this.creatorUid,
    required this.creatorName,
    required this.isCustomizable,
    required this.customizations,
    required this.hasChanges,
  });
}

final class CreatorFetchPendingProducts extends CreatorEvent {}

final class CreatorFetchAdminAllProducts extends CreatorEvent {}

final class CreatorFetchCreatorProducts extends CreatorEvent {
  final String uid;
  CreatorFetchCreatorProducts(this.uid);
}

final class CreatorUpdateProductStatus extends CreatorEvent {
  final String productId;
  final String status;
  CreatorUpdateProductStatus({required this.productId, required this.status});
}
