class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role; // 'buyer', 'creator', 'admin', 'super_admin', 'manager'
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

  static const List<String> presetSuperAdminEmails = [
    'adhirajjain364@gmail.com',
    'mayankjaisw8673@gmail.com',
    'suhanimahajan2810@gmail.com',
    'majumdarpayal50@gmail.com',
    'reshob.rc12345@gmail.com',
  ];

  bool get isSuperAdmin {
    final lowerRole = role.toLowerCase().trim();
    if (lowerRole == 'super_admin') return true;
    final lowerEmail = email.toLowerCase().trim();
    if ((lowerRole == 'admin' || lowerRole.isEmpty) &&
        presetSuperAdminEmails.contains(lowerEmail)) {
      return true;
    }
    return false;
  }

  bool get isManager {
    final lowerRole = role.toLowerCase().trim();
    if (lowerRole == 'manager') return true;
    if (lowerRole == 'admin' && !isSuperAdmin) return true;
    return false;
  }

  bool get isAdminOrManager {
    final lowerRole = role.toLowerCase().trim();
    return isSuperAdmin || isManager || lowerRole == 'admin';
  }

  String get roleDisplay {
    if (isSuperAdmin) return 'Super Admin';
    if (isManager) return 'Manager (Operational)';
    if (role.toLowerCase() == 'creator') return 'Creator / Seller';
    return 'Buyer';
  }
}
