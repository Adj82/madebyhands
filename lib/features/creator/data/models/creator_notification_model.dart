import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:madebyhands/features/creator/domain/entities/creator_notification.dart';

class CreatorNotificationModel extends CreatorNotification {
  const CreatorNotificationModel({
    required super.id,
    required super.creatorUid,
    required super.title,
    required super.message,
    required super.type,
    required super.createdAt,
    required super.isRead,
    super.targetId,
  });

  factory CreatorNotificationModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return CreatorNotificationModel(
      id: id,
      creatorUid: json['creatorUid'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      createdAt:
          (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      targetId: json['targetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creatorUid': creatorUid,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt,
      'isRead': isRead,
      'targetId': targetId,
    };
  }
}
