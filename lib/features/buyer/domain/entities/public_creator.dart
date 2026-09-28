class PublicCreator {
  final String uid;
  final String name;
  final String businessName;
  final String profileImage;
  final String bio;
  final String category;
  final String location;
  final List<String> socialLinks;
  final List<String> portfolio;
  final String story;
  final bool isVerified;

  const PublicCreator({
    required this.uid,
    required this.name,
    this.businessName = '',
    this.profileImage = '',
    this.bio = '',
    this.category = '',
    this.location = '',
    this.socialLinks = const [],
    this.portfolio = const [],
    this.story = '',
    this.isVerified = false,
  });

  String get displayName => businessName.trim().isNotEmpty
      ? businessName.trim()
      : name.trim().isNotEmpty
      ? name.trim()
      : 'MadeByHands creator';
}
