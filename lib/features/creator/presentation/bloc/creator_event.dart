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
