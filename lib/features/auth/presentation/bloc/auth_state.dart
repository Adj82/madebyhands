part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

final class AuthNeedsRoleSelection extends AuthState {
  final UserEntity tempUser;
  const AuthNeedsRoleSelection(this.tempUser);

  @override
  List<Object?> get props => [tempUser];
}

/// Signing in or restoring the session failed.
final class AuthFailure extends AuthState {
  final String message;

  /// False for sign-in attempts, where the welcome screen shows the error
  /// itself and a "Retry session" screen makes no sense.
  final bool canRetrySession;

  const AuthFailure(this.message, {this.canRetrySession = true});

  @override
  List<Object?> get props => [message, canRetrySession];
}

/// A one-off action (such as account deletion) failed; the previous state is
/// re-emitted right after so the user stays where they were.
final class AuthActionFailed extends AuthState {
  final String message;
  const AuthActionFailed(this.message);

  @override
  List<Object?> get props => [message];
}
