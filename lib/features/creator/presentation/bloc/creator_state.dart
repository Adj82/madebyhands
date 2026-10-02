part of 'creator_bloc.dart';

enum CreatorSessionStatus { initial, loading, ready, notFound, failure }

/// A creator write the UI can react to.
enum CreatorAction {
  saveProfile,
  submitVerification,
  saveProduct,
  deleteProduct,
  publishProduct,
  updateStock,
  updateOrder,
  rejectOrder,
  saveBankAccount,
}

enum CreatorActionStatus { idle, inProgress, success, failure }

/// The signed-in creator's profile session plus the outcome of the most
/// recent write. Lists (products, orders, notifications) are streamed
/// directly from [CreatorRepository] by the views that show them.
class CreatorState extends Equatable {
  final CreatorSessionStatus status;
  final CreatorProfile? profile;
  final String? sessionError;

  final CreatorAction? action;
  final CreatorActionStatus actionStatus;
  final String? actionMessage;

  /// Increments on every action update so listeners can tell two identical
  /// outcomes apart.
  final int actionId;

  const CreatorState({
    this.status = CreatorSessionStatus.initial,
    this.profile,
    this.sessionError,
    this.action,
    this.actionStatus = CreatorActionStatus.idle,
    this.actionMessage,
    this.actionId = 0,
  });

  bool isRunning(CreatorAction value) =>
      action == value && actionStatus == CreatorActionStatus.inProgress;

  CreatorState withSession({
    required CreatorSessionStatus status,
    CreatorProfile? profile,
    String? sessionError,
  }) => CreatorState(
    status: status,
    profile: profile,
    sessionError: sessionError,
    action: action,
    actionStatus: actionStatus,
    actionMessage: actionMessage,
    actionId: actionId,
  );

  CreatorState withAction(
    CreatorAction action,
    CreatorActionStatus actionStatus, {
    String? message,
  }) => CreatorState(
    status: status,
    profile: profile,
    sessionError: sessionError,
    action: action,
    actionStatus: actionStatus,
    actionMessage: message,
    actionId: actionId + 1,
  );

  @override
  List<Object?> get props => [
    status,
    profile,
    sessionError,
    action,
    actionStatus,
    actionMessage,
    actionId,
  ];
}
