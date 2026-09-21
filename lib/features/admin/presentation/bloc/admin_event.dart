part of 'admin_bloc.dart';

sealed class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

final class AdminLoadDataRequested extends AdminEvent {}

final class AdminFetchBuyersRequested extends AdminEvent {}

final class AdminFetchCreatorsRequested extends AdminEvent {}

final class AdminFetchAdminsRequested extends AdminEvent {}

final class AdminSuspendUserRequested extends AdminEvent {
  final String uid;
  final bool isSuspended;
  const AdminSuspendUserRequested(this.uid, this.isSuspended);
}

final class AdminChangeUserRoleRequested extends AdminEvent {
  final String uid;
  final String newRole;
  const AdminChangeUserRoleRequested(this.uid, this.newRole);
}

final class AdminApproveCreatorRequested extends AdminEvent {
  final String applicationId;
  const AdminApproveCreatorRequested(this.applicationId);
}

final class AdminRejectCreatorRequested extends AdminEvent {
  final String applicationId;
  const AdminRejectCreatorRequested(this.applicationId);
}

final class AdminApproveProductRequested extends AdminEvent {
  final String productId;
  const AdminApproveProductRequested(this.productId);
}

final class AdminRejectProductRequested extends AdminEvent {
  final String productId;
  const AdminRejectProductRequested(this.productId);
}

final class AdminAddCategoryRequested extends AdminEvent {
  final String name;
  const AdminAddCategoryRequested(this.name);
}

final class AdminDeleteCategoryRequested extends AdminEvent {
  final String name;
  const AdminDeleteCategoryRequested(this.name);
}

final class AdminSendMessageRequested extends AdminEvent {
  final String ticketId;
  final String message;
  const AdminSendMessageRequested({required this.ticketId, required this.message});
}

final class AdminUpdateSettingsRequested extends AdminEvent {
  final double flatFee;
  final double percentFee;
  const AdminUpdateSettingsRequested({required this.flatFee, required this.percentFee});
}
