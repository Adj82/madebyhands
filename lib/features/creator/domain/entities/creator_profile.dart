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
  final String verificationStatus; // 'Unverified', 'In-Process', 'Verified'
  final String businessName;
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
    this.businessName = '',
    this.address = '',
    this.latestPhoto = '',
    this.idCard = '',
  });
}
