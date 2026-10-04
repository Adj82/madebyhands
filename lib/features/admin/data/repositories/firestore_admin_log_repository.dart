import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:madebyhands/features/admin/domain/entities/admin_log_entry.dart';
import 'package:madebyhands/features/admin/domain/repositories/admin_log_repository.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';

/// Stores the log in the append-only `admin_logs` collection.
class FirestoreAdminLogRepository implements AdminLogRepository {
  final FirebaseFirestore firestore;

  /// Who is signed in right now; read at the moment of each action.
  final UserEntity? Function() currentUser;

  FirestoreAdminLogRepository({
    required this.firestore,
    required this.currentUser,
  });

  @override
  Future<void> log({
    required AdminLogCategory category,
    required String action,
    required String summary,
    String targetId = '',
  }) async {
    try {
      final actor = currentUser();
      if (actor == null) return;
      await firestore.collection('admin_logs').add({
        ...AdminLogEntry(
          id: '',
          actorUid: actor.uid,
          actorName: actor.name,
          actorEmail: actor.email,
          actorRole: actor.roleDisplay,
          action: action,
          category: category,
          summary: summary,
          targetId: targetId,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Could not write admin log "$action": $error');
    }
  }

  @override
  Stream<List<AdminLogEntry>> watchLogs({int limit = 300}) => firestore
      .collection('admin_logs')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => AdminLogEntry.fromMap(
                doc.id,
                doc.data(),
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
            )
            .toList(),
      );
}
