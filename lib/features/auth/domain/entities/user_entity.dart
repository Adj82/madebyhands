class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // 'buyer', 'creator', 'admin'
  final bool isVerified;
  final bool isSuspended;

  UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    required this.role,
    this.isVerified = false,
    this.isSuspended = false,
  });
}
