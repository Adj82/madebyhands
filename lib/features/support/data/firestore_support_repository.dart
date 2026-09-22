import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/support/domain/entities/support_ticket.dart';
import 'package:madebyhands/features/support/domain/repositories/support_repository.dart';

class FirestoreSupportRepository implements SupportRepository {
  final FirebaseFirestore firestore;

  const FirestoreSupportRepository({required this.firestore});

  @override
  Stream<List<SupportTicket>> watchUserTickets(String userId) => firestore
      .collection('support_tickets')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(_tickets);

  @override
  Stream<List<SupportTicket>> watchAllTickets() =>
      firestore.collection('support_tickets').snapshots().map(_tickets);

  List<SupportTicket> _tickets(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final tickets = snapshot.docs.map((document) {
      final data = document.data();
      final createdAt = _date(data['createdAt']);
      return SupportTicket(
        id: document.id,
        userId: data['userId'] as String? ?? '',
        userRole: data['userRole'] as String? ?? 'buyer',
        userName: data['userName'] as String? ?? 'User',
        subject: data['subject'] as String? ?? 'Support request',
        status: data['status'] as String? ?? 'open',
        lastMessage: data['lastMessage'] as String? ?? '',
        createdAt: createdAt,
        updatedAt: _date(data['updatedAt'], fallback: createdAt),
      );
    }).toList();
    tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tickets;
  }

  @override
  Stream<List<SupportMessage>> watchMessages(String ticketId) => firestore
      .collection('support_tickets')
      .doc(ticketId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((document) {
          final data = document.data();
          return SupportMessage(
            id: document.id,
            senderId: data['senderId'] as String? ?? '',
            senderRole: data['senderRole'] as String? ?? 'buyer',
            message: data['message'] as String? ?? '',
            createdAt: _date(data['createdAt']),
          );
        }).toList(),
      );

  @override
  Future<String> createTicket({
    required String userId,
    required String userRole,
    required String userName,
    required String subject,
    required String message,
  }) async {
    final ticket = firestore.collection('support_tickets').doc();
    final firstMessage = ticket.collection('messages').doc();
    final batch = firestore.batch();
    batch.set(ticket, {
      'userId': userId,
      'userRole': userRole,
      'userName': userName,
      'subject': subject,
      'status': 'open',
      'lastMessage': message,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(firstMessage, {
      'senderId': userId,
      'senderRole': userRole,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ticket.id;
  }

  @override
  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    required String message,
  }) async {
    final ticket = firestore.collection('support_tickets').doc(ticketId);
    final messageDocument = ticket.collection('messages').doc();
    final batch = firestore.batch();
    batch.set(messageDocument, {
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(ticket, {
      'lastMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> resolveTicket(String ticketId) =>
      firestore.collection('support_tickets').doc(ticketId).update({
        'status': 'resolved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static DateTime _date(Object? value, {DateTime? fallback}) =>
      value is Timestamp ? value.toDate() : fallback ?? DateTime(1970);
}
