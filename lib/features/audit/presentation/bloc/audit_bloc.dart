import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/audit_repository.dart';

// EVENTS
abstract class AuditEvent extends Equatable {
  const AuditEvent();
  @override
  List<Object?> get props => [];
}

class LoadAuditLogs extends AuditEvent {}

// STATES
abstract class AuditState extends Equatable {
  const AuditState();
  @override
  List<Object?> get props => [];
}

class AuditInitial extends AuditState {}
class AuditLoading extends AuditState {}
class AuditLogsLoaded extends AuditState {
  final List<AuditLog> logs;
  const AuditLogsLoaded(this.logs);
  @override
  List<Object> get props => [logs];
}
class AuditError extends AuditState {
  final String message;
  const AuditError(this.message);
}

// BLOC
class AuditBloc extends Bloc<AuditEvent, AuditState> {
  final AuditRepository _repo;

  AuditBloc(this._repo) : super(AuditInitial()) {
    on<LoadAuditLogs>(_onLoad);
  }

  Future<void> _onLoad(LoadAuditLogs event, Emitter<AuditState> emit) async {
    emit(AuditLoading());
    try {
      final logs = await _repo.getAllLogs();
      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(AuditError(e.toString()));
    }
  }
}
