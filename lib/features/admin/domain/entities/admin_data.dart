import 'package:equatable/equatable.dart';

class AdminCreatorApplication extends Equatable {
  final String id;
  final String name;
  final String category;
  final String bio;
  final DateTime appliedAt;

  const AdminCreatorApplication({
    required this.id,
    required this.name,
    required this.category,
    required this.bio,
    required this.appliedAt,
  });

  @override
  List<Object> get props => [id, name, category, bio, appliedAt];
}

class AdminProductApproval extends Equatable {
  final String id;
  final String name;
  final String creatorName;
  final int price;
  final String category;

  const AdminProductApproval({
    required this.id,
    required this.name,
    required this.creatorName,
    required this.price,
    required this.category,
  });

  @override
  List<Object> get props => [id, name, creatorName, price, category];
}

class AdminSupportTicket extends Equatable {
  final String id;
  final String subject;
  final String lastMessage;
  final bool isOpen;

  const AdminSupportTicket({
    required this.id,
    required this.subject,
    required this.lastMessage,
    required this.isOpen,
  });

  @override
  List<Object> get props => [id, subject, lastMessage, isOpen];
}
