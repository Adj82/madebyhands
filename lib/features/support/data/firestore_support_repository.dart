import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/support/data/models/support_message_model.dart';
import 'package:madebyhands/features/support/data/models/support_ticket_model.dart';
import 'package:madebyhands/features/support/domain/entities/support_message.dart';
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
      .map(_ticketsFromSnapshot);

  @override
  Stream<List<SupportTicket>> watchAllTickets() => firestore
      .collection('support_tickets')
      .snapshots()
      .map((snapshot) {
        final List<SupportTicket> tickets = snapshot.docs
            .map<SupportTicket>(SupportTicketModel.fromDocument)
            .where((ticket) => !ticket.isAccountDeletion)
            .toList();
        tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return tickets;
      });

  @override
  Stream<List<SupportMessage>> watchMessages(String ticketId) => firestore
      .collection('support_tickets')
      .doc(ticketId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map<SupportMessage>(SupportMessageModel.fromDocument).toList());

  @override
  Stream<SupportTicket?> watchLatestDeletionRequest(String userId) => firestore
      .collection('support_tickets')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final List<SupportTicket> deletionTickets = snapshot.docs
            .map<SupportTicket>(SupportTicketModel.fromDocument)
            .where((t) => t.isAccountDeletion)
            .toList();
        if (deletionTickets.isEmpty) return null;
        deletionTickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return deletionTickets.first;
      });

  List<SupportTicket> _ticketsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<SupportTicket> tickets = snapshot.docs.map<SupportTicket>(SupportTicketModel.fromDocument).toList();
    tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tickets;
  }

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
      'type': 'general',
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
  Future<String> createAccountDeletionRequest({
    required String userId,
    required String userName,
    required String reason,
  }) async {
    final existingQuery = await firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'account_deletion')
        .get();

    for (final doc in existingQuery.docs) {
      final data = doc.data();
      final reqStatus = data['requestStatus'] as String? ?? 'Pending';
      final status = data['status'] as String? ?? 'open';
      if (reqStatus == 'Pending' && status == 'open') {
        throw Exception(
          'You already have an active pending account deletion request.',
        );
      }
    }

    final ticket = firestore.collection('support_tickets').doc();
    final firstMessage = ticket.collection('messages').doc();
    final adminNotificationRef = firestore.collection('notifications').doc();
    final userRef = firestore.collection('users').doc(userId);

    final batch = firestore.batch();

    final messageText = 'Account Deletion Request Reason: $reason';

    // 1. Mark deletion requested on user document
    batch.update(userRef, {
      'isDeletionRequested': true,
      'deletionReason': reason,
      'deletionRequestedAt': FieldValue.serverTimestamp(),
    });

    // 2. Write support ticket
    batch.set(ticket, {
      'userId': userId,
      'userRole': 'creator',
      'userName': userName,
      'subject': 'Account Deletion Request',
      'type': 'account_deletion',
      'status': 'open',
      'requestStatus': 'Pending',
      'reason': reason,
      'lastMessage': messageText,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(firstMessage, {
      'senderId': userId,
      'senderRole': 'creator',
      'message': messageText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Write admin notification
    batch.set(adminNotificationRef, {
      'type': 'admin',
      'category': 'deletion_request',
      'title': 'Account Deletion Request ⚠️',
      'message': '$userName requested account deletion. Reason: "$reason"',
      'targetId': userId,
      'ticketId': ticket.id,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
    return ticket.id;
  }

  Future<String> requestCreatorAccountDeletion({
    required String userId,
    required String userName,
    required String reason,
  }) => createAccountDeletionRequest(
    userId: userId,
    userName: userName,
    reason: reason,
  );

  @override
  Future<void> approveAccountDeletion({
    required String ticketId,
    required String creatorUid,
  }) async {
    final batch = firestore.batch();

    final ticketRef = firestore.collection('support_tickets').doc(ticketId);
    batch.update(ticketRef, {
      'status': 'resolved',
      'requestStatus': 'Approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final msgRef = ticketRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'admin',
      'senderRole': 'admin',
      'message':
          'Account deletion request APPROVED. Creator profile and products deactivated.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final profileRef =
        firestore.collection('creator_profiles').doc(creatorUid);
    batch.set(profileRef, {
      'verificationStatus': 'Deactivated',
      'isActive': false,
    }, SetOptions(merge: true));

    final userRef = firestore.collection('users').doc(creatorUid);
    batch.set(userRef, {
      'isDeactivated': true,
      'isDeletionRequested': false,
      'role': 'deactivated',
      'isVerified': false,
    }, SetOptions(merge: true));

    final productsSnap = await firestore
        .collection('products')
        .where('creatorUid', isEqualTo: creatorUid)
        .get();

    for (final doc in productsSnap.docs) {
      batch.update(doc.reference, {
        'isActive': false,
        'status': 'Deactivated',
      });
    }

    final notifRef = firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'creatorUid': creatorUid,
      'title': 'Account Deletion Approved',
      'message':
          'Your request for account deletion has been approved by Admin. Your account and listings have been deactivated.',
      'type': 'account',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  @override
  Future<void> rejectAccountDeletion({
    required String ticketId,
    required String creatorUid,
    required String rejectionReason,
  }) async {
    final batch = firestore.batch();

    final ticketRef = firestore.collection('support_tickets').doc(ticketId);
    batch.update(ticketRef, {
      'status': 'resolved',
      'requestStatus': 'Rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userRef = firestore.collection('users').doc(creatorUid);
    batch.set(userRef, {
      'isDeletionRequested': false,
    }, SetOptions(merge: true));

    final msgRef = ticketRef.collection('messages').doc();
    batch.set(msgRef, {
      'senderId': 'admin',
      'senderRole': 'admin',
      'message': 'Account deletion request REJECTED. Reason: $rejectionReason',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final notifRef = firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'creatorUid': creatorUid,
      'title': 'Account Deletion Request Rejected',
      'message':
          'Your account deletion request was rejected by Admin. Reason: $rejectionReason',
      'type': 'account',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  @override
  Future<void> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderRole,
    required String message,
  }) async {
    final ticketRef = firestore.collection('support_tickets').doc(ticketId);
    final messageRef = ticketRef.collection('messages').doc();
    final batch = firestore.batch();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderRole': senderRole,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(ticketRef, {
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
}
