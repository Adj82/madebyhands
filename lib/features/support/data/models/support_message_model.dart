import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';

class SupportMessageModel extends SupportMessage {
  const SupportMessageModel({
    required super.id,
    required super.senderId,
    required super.senderRole,
    required super.message,
    required super.createdAt,
  });

  factory SupportMessageModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return SupportMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'buyer',
      message: data['message'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
