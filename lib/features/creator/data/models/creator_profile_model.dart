import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class CreatorProfileModel extends CreatorProfile {
  CreatorProfileModel({
    required super.uid,
    required super.name,
    required super.profileImage,
    required super.bio,
    required super.category,
    required super.location,
    required super.socialLinks,
    required super.portfolio,
    required super.story,
    super.verificationStatus,
    super.businessName,
    super.address,
    super.latestPhoto,
    super.idCard,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'profileImage': profileImage,
      'bio': bio,
      'category': category,
      'location': location,
      'socialLinks': socialLinks,
      'portfolio': portfolio,
      'story': story,
      'verificationStatus': verificationStatus,
      'businessName': businessName,
      'address': address,
      'latestPhoto': latestPhoto,
      'idCard': idCard,
    };
  }

  factory CreatorProfileModel.fromJson(Map<String, dynamic> json) {
    return CreatorProfileModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'] ?? '',
      bio: json['bio'] ?? '',
      category: json['category'] ?? '',
      location: json['location'] ?? '',
      socialLinks: List<String>.from(json['socialLinks'] ?? []),
      portfolio: List<String>.from(json['portfolio'] ?? []),
      story: json['story'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'Unverified',
      businessName: json['businessName'] ?? '',
      address: json['address'] ?? '',
      latestPhoto: json['latestPhoto'] ?? '',
      idCard: json['idCard'] ?? '',
    );
  }

  factory CreatorProfileModel.fromEntity(CreatorProfile entity) {
    return CreatorProfileModel(
      uid: entity.uid,
      name: entity.name,
      profileImage: entity.profileImage,
      bio: entity.bio,
      category: entity.category,
      location: entity.location,
      socialLinks: entity.socialLinks,
      portfolio: entity.portfolio,
      story: entity.story,
      verificationStatus: entity.verificationStatus,
      businessName: entity.businessName,
      address: entity.address,
      latestPhoto: entity.latestPhoto,
      idCard: entity.idCard,
    );
  }
}
