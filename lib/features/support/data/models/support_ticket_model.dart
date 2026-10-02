import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';

class SupportTicketModel extends SupportTicket {
  const SupportTicketModel({
    required super.id,
    required super.userId,
    required super.userRole,
    required super.userName,
    required super.subject,
    required super.status,
    required super.lastMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportTicketModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userRole: data['userRole'] as String? ?? 'buyer',
      userName: data['userName'] as String? ?? 'User',
      subject: data['subject'] as String? ?? 'Support ticket',
      status: data['status'] as String? ?? 'open',
      lastMessage: data['lastMessage'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }
}
