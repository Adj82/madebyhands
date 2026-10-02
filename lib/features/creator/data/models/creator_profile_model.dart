import 'package:madebyhands/features/creator/domain/entities/creator_profile.dart';

class CreatorProfileModel extends CreatorProfile {
  CreatorProfileModel({
    required super.uid,
    required super.name,
    required super.profileImage,
    required super.bio,
    required super.location,
    required super.socialLinks,
    required super.portfolio,
    required super.story,
    super.verificationStatus,
    super.verificationNote,
    super.businessName,
    super.address,
    super.latestPhoto,
    super.idCard,
  });

  /// The public, creator-editable fields. Verification status and documents
  /// are written separately so a profile edit can never reset them.
  Map<String, dynamic> toEditableJson() {
    return {
      'uid': uid,
      'name': name,
      'profileImage': profileImage,
      'bio': bio,
      'location': location,
      'socialLinks': socialLinks,
      'portfolio': portfolio,
      'story': story,
    };
  }

  static String _string(Object? value) => value is String ? value : '';

  static List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().where((item) => item.trim().isNotEmpty).toList()
      : const [];

  factory CreatorProfileModel.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    final uid = _string(json['uid']).trim();
    return CreatorProfileModel(
      uid: uid.isNotEmpty ? uid : (docId ?? ''),
      name: _string(json['name']),
      profileImage: _string(json['profileImage']),
      bio: _string(json['bio']),
      location: _string(json['location']),
      socialLinks: _strings(json['socialLinks']),
      portfolio: _strings(json['portfolio']),
      story: _string(json['story']),
      verificationStatus: _string(json['verificationStatus']).isEmpty
          ? 'Unverified'
          : _string(json['verificationStatus']),
      verificationNote: _string(json['verificationNote']),
      businessName: _string(json['businessName']),
      address: _string(json['address']),
      latestPhoto: _string(json['latestPhoto']),
      idCard: _string(json['idCard']),
    );
  }
}
