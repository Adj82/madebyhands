class SupportTicket {
  final String id;
  final String userId;
  final String userRole;
  final String userName;
  final String subject;
  final String status;
  final String requestStatus; // 'Pending', 'Approved', 'Rejected', 'none'
  final String reason;
  final String type; // 'general', 'account_deletion'
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
    this.requestStatus = 'none',
    this.reason = '',
    this.type = 'general',
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isAccountDeletionRequest =>
      type == 'account_deletion' || subject == 'Account Deletion Request';
  bool get isAccountDeletion => isAccountDeletionRequest;
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
