import 'package:equatable/equatable.dart';
import '../../../../core/data/database/app_database.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested(this.username, this.password);

  @override
  List<Object> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthChangePasswordRequested extends AuthEvent {
  final String newPassword;

  const AuthChangePasswordRequested(this.newPassword);

  @override
  List<Object> get props => [newPassword];
}

class AuthCheckStatus extends AuthEvent {}
