import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'buyer',
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
