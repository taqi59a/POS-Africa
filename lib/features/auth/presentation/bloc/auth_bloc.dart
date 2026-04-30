import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthChangePasswordRequested>(_onChangePasswordRequested);
    on<AuthCheckStatus>(_onCheckStatus);
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.username, event.password);
      if (user != null) {
        if (user.requirePasswordChange) {
          emit(AuthRequirePasswordChange(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(const AuthFailure('Login failed.'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onChangePasswordRequested(AuthChangePasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        await _authRepository.changePassword(currentUser.id, event.newPassword);
        // After changing password, fetch updated user to refresh status
        final updatedUser = await _authRepository.getCurrentUser();
        emit(AuthAuthenticated(currentUser));
      } else {
        emit(const AuthFailure('No user is currently logged in.'));
      }
    } catch (e) {
      emit(AuthFailure('Failed to change password: $e'));
    }
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      if (user.requirePasswordChange) {
        emit(AuthRequirePasswordChange(user));
      } else {
        emit(AuthAuthenticated(user));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
