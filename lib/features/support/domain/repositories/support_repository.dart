import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';

abstract class SupportRepository {
  Stream<List<SupportTicket>> watchUserTickets(String userId);
  Stream<List<SupportTicket>> watchAllTickets();
  Stream<List<SupportMessage>> watchMessages(String ticketId);

  Future<String> createTicket({
    required String userId,
    required String userRole,
    required String userName,
    required String subject,
    required String message,
  });

  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    required String message,
  });

  Future<void> resolveTicket(String ticketId);

  Future<String> createAccountDeletionRequest({
    required String userId,
    required String userName,
    required String reason,
  });

  Future<void> approveAccountDeletion({
    required String ticketId,
    required String creatorUid,
  });

  Future<void> rejectAccountDeletion({
    required String ticketId,
    required String creatorUid,
    required String rejectionReason,
  });

  Stream<SupportTicket?> watchLatestDeletionRequest(String userId);
}
