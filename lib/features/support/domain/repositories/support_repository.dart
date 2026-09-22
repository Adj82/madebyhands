import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';

abstract interface class SupportRepository {
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
}
