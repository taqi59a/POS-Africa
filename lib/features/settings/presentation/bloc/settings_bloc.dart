import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/settings_repository.dart';

// EVENTS
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class SaveSettings extends SettingsEvent {
  final Map<String, String> newSettings;
  const SaveSettings(this.newSettings);
  @override
  List<Object> get props => [newSettings];
}

// STATES
abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Map<String, String> settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object> get props => [message];
}

// BLOC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc(this._repository) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final settings = await _repository.getAllSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onSaveSettings(SaveSettings event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      await _repository.saveSettings(event.newSettings);
      final updatedSettings = await _repository.getAllSettings();
      emit(SettingsLoaded(updatedSettings));
    } catch (e) {
      emit(SettingsError('Failed to save settings: $e'));
    }
  }
}
