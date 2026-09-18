import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:madebyhands/features/auth/domain/entities/user_entity.dart';
import 'package:madebyhands/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignUpWithRoleRequested>(_onSignUpWithRoleRequested);
    on<AuthIsUserLoggedIn>(_onIsUserLoggedIn);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _authRepository.signInWithGoogle();

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) {
        if (r.role.isEmpty) {
          emit(AuthNeedsRoleSelection(r));
        } else {
          emit(AuthSuccess(r));
        }
      },
    );
  }

  void _onSignUpWithRoleRequested(
    AuthSignUpWithRoleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _authRepository.signUpWithRole(
      uid: event.uid,
      email: event.email,
      name: event.name,
      role: event.role,
    );

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthSuccess(r)),
    );
  }

  void _onIsUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    final res = await _authRepository.getCurrentUser();

    res.fold(
      (l) => emit(AuthInitial()),
      (r) {
        if (r.role.isEmpty) {
          emit(AuthNeedsRoleSelection(r));
        } else {
          emit(AuthSuccess(r));
        }
      },
    );
  }

  void _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _authRepository.signOut();

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthInitial()),
    );
  }
}
