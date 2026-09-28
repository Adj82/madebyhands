class CreatorNotification {
  final String id;
  final String creatorUid;
  final String title;
  final String message;
  final String type; // 'order', 'announcement', 'verification', 'product', 'account'
  final DateTime createdAt;
  final bool isRead;
  final String? targetId;

  const CreatorNotification({
    required this.id,
    required this.creatorUid,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.targetId,
  });
}
