import 'package:drift/drift.dart' hide Column;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override List<Object?> get props => [];
}

class LoadUsers extends UserEvent {}

class CreateUser extends UserEvent {
  final String username;
  final String password;
  final int    roleId;
  final bool   requirePasswordChange;
  const CreateUser({
    required this.username,
    required this.password,
    required this.roleId,
    this.requirePasswordChange = true,
  });
  @override List<Object?> get props => [username, roleId];
}

class UpdateUser extends UserEvent {
  final int            userId;
  final UsersCompanion companion;
  const UpdateUser(this.userId, this.companion);
  @override List<Object?> get props => [userId];
}

class DeleteUser extends UserEvent {
  final int userId;
  const DeleteUser(this.userId);
  @override List<Object> get props => [userId];
}

class ResetUserPassword extends UserEvent {
  final int    userId;
  final String newPassword;
  const ResetUserPassword(this.userId, this.newPassword);
  @override List<Object> get props => [userId];
}

class ToggleUserActive extends UserEvent {
  final int  userId;
  final bool isActive;
  const ToggleUserActive(this.userId, this.isActive);
  @override List<Object> get props => [userId, isActive];
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class UserState extends Equatable {
  const UserState();
  @override List<Object?> get props => [];
}

class UserInitial  extends UserState {}
class UserLoading  extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  final List<Role> roles;
  const UserLoaded(this.users, this.roles);
  @override List<Object> get props => [users, roles];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override List<Object> get props => [message];
}

class UserActionSuccess extends UserState {
  final String    message;
  final List<User> users;
  final List<Role> roles;
  const UserActionSuccess(this.message, this.users, this.roles);
  @override List<Object> get props => [message, users, roles];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository _auth;

  UserBloc(this._auth) : super(UserInitial()) {
    on<LoadUsers>(_onLoad);
    on<CreateUser>(_onCreate);
    on<UpdateUser>(_onUpdate);
    on<DeleteUser>(_onDelete);
    on<ResetUserPassword>(_onResetPassword);
    on<ToggleUserActive>(_onToggleActive);
  }

  Future<void> _onLoad(LoadUsers event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserLoaded(users, roles));
    } catch (e) {
      emit(UserError('Failed to load users: $e'));
    }
  }

  Future<void> _onCreate(CreateUser event, Emitter<UserState> emit) async {
    try {
      await _auth.createUser(
        event.username, event.password, event.roleId,
        requirePasswordChange: event.requirePasswordChange,
      );
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserActionSuccess('User "${event.username}" created.', users, roles));
    } catch (e) {
      emit(UserError('Failed to create user: $e'));
    }
  }

  Future<void> _onUpdate(UpdateUser event, Emitter<UserState> emit) async {
    try {
      await _auth.updateUser(event.userId, event.companion);
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserActionSuccess('User updated.', users, roles));
    } catch (e) {
      emit(UserError('Failed to update user: $e'));
    }
  }

  Future<void> _onDelete(DeleteUser event, Emitter<UserState> emit) async {
    try {
      await _auth.deleteUser(event.userId);
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserActionSuccess('User deleted.', users, roles));
    } catch (e) {
      emit(UserError('Failed to delete user: $e'));
    }
  }

  Future<void> _onResetPassword(
      ResetUserPassword event, Emitter<UserState> emit) async {
    try {
      await _auth.changePassword(event.userId, event.newPassword);
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserActionSuccess('Password reset successfully.', users, roles));
    } catch (e) {
      emit(UserError('Failed to reset password: $e'));
    }
  }

  Future<void> _onToggleActive(
      ToggleUserActive event, Emitter<UserState> emit) async {
    try {
      await _auth.updateUser(
        event.userId,
        UsersCompanion(isActive: Value(event.isActive)),
      );
      final users = await _auth.getAllUsers();
      final roles = await _auth.getAllRoles();
      emit(UserActionSuccess(
        event.isActive ? 'User activated.' : 'User deactivated.',
        users, roles,
      ));
    } catch (e) {
      emit(UserError('Failed to update user status: $e'));
    }
  }
}
