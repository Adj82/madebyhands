class SupportTicket {
  final String id;
  final String userId;
  final String userRole;
  final String userName;
  final String subject;
  final String status;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.userName,
    required this.subject,
    required this.status,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
}

class SupportMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String message;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });
}
