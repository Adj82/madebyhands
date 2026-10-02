class CreatorProfile {
  final String uid;
  final String name;
  final String profileImage;
  final String bio;
  final String category;
  final String location;
  final List<String> socialLinks;
  final List<String> portfolio;
  final String story;
  /// 'Unverified', 'In-Process', 'Verified' or 'Rejected'.
  final String verificationStatus;

  /// Admin's reason when verification was rejected.
  final String verificationNote;
  final String businessName;

  // Legacy: older profiles stored verification documents publicly. New
  // submissions keep them in the private `creator_verifications` collection.
  final String address;
  final String latestPhoto;
  final String idCard;

  CreatorProfile({
    required this.uid,
    required this.name,
    required this.profileImage,
    required this.bio,
    required this.category,
    required this.location,
    required this.socialLinks,
    required this.portfolio,
    required this.story,
    this.verificationStatus = 'Unverified',
    this.verificationNote = '',
    this.businessName = '',
    this.address = '',
    this.latestPhoto = '',
    this.idCard = '',
  });

  bool get isVerified => verificationStatus == 'Verified';
  bool get isUnderReview => verificationStatus == 'In-Process';
  bool get isVerificationRejected => verificationStatus == 'Rejected';
}
