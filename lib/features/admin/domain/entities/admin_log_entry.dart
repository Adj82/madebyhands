/// What kind of thing an admin changed. Drives the icon and the filter chips
/// on the Activity Logs screen.
enum AdminLogCategory {
  creator('Creators'),
  product('Products'),
  order('Orders'),
  payout('Payouts'),
  category('Categories'),
  user('Users'),
  access('Admin access'),
  settings('Settings');

  final String label;
  const AdminLogCategory(this.label);

  static AdminLogCategory? tryParse(String? value) {
    for (final category in values) {
      if (category.name == value) return category;
    }
    return null;
  }
}

/// One line in the admin activity log: who did what, and when.
///
/// Entries are append-only (see the `admin_logs` rules) and carry a
/// plain-language [summary] so the log stays readable even after the thing it
/// refers to has been renamed or deleted.
class AdminLogEntry {
  final String id;
  final String actorUid;
  final String actorName;
  final String actorEmail;
  final String actorRole;

  /// Stable machine key, e.g. `creator.verified`.
  final String action;
  final AdminLogCategory category;
  final String summary;
  final String targetId;

  /// Null only for the instant between writing an entry and the server
  /// stamping it.
  final DateTime? createdAt;

  const AdminLogEntry({
    required this.id,
    required this.actorUid,
    required this.actorName,
    required this.actorEmail,
    required this.actorRole,
    required this.action,
    required this.category,
    required this.summary,
    this.targetId = '',
    this.createdAt,
  });

  /// The name to show for who did it.
  String get actorLabel => actorName.trim().isNotEmpty
      ? actorName.trim()
      : (actorEmail.trim().isNotEmpty ? actorEmail.trim() : 'Unknown admin');

  factory AdminLogEntry.fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime? createdAt,
  }) {
    return AdminLogEntry(
      id: id,
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorEmail: data['actorEmail'] as String? ?? '',
      actorRole: data['actorRole'] as String? ?? '',
      action: data['action'] as String? ?? '',
      category:
          AdminLogCategory.tryParse(data['category'] as String?) ??
          AdminLogCategory.settings,
      summary: data['summary'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  /// Fields written to Firestore (everything except the server timestamp,
  /// which the repository adds).
  Map<String, dynamic> toMap() => {
    'actorUid': actorUid,
    'actorName': actorName,
    'actorEmail': actorEmail,
    'actorRole': actorRole,
    'action': action,
    'category': category.name,
    'summary': summary,
    'targetId': targetId,
  };

  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return [
      summary,
      actorName,
      actorEmail,
      action,
      targetId,
    ].any((field) => field.toLowerCase().contains(needle));
  }
}
