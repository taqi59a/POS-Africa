import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/report_repository.dart';

// EVENTS
abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadDailySalesSummary extends ReportEvent {
  final DateTime date;
  const LoadDailySalesSummary(this.date);
}

class LoadTopProducts extends ReportEvent {
  final DateTime start;
  final DateTime end;
  const LoadTopProducts(this.start, this.end);
}

class LoadInventoryValuation extends ReportEvent {}

// STATES
abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

/// Single accumulated state — eliminates race-condition clobbering.
class ReportDataState extends ReportState {
  final bool isLoadingDaily;
  final bool isLoadingInventory;
  final bool isLoadingTopProducts;
  final Map<String, double>? dailySummary;
  final double? inventoryValuation;
  final List<Map<String, dynamic>>? topProducts;
  final String? error;

  const ReportDataState({
    this.isLoadingDaily = false,
    this.isLoadingInventory = false,
    this.isLoadingTopProducts = false,
    this.dailySummary,
    this.inventoryValuation,
    this.topProducts,
    this.error,
  });

  ReportDataState copyWith({
    bool? isLoadingDaily,
    bool? isLoadingInventory,
    bool? isLoadingTopProducts,
    Map<String, double>? dailySummary,
    double? inventoryValuation,
    List<Map<String, dynamic>>? topProducts,
    String? error,
  }) {
    return ReportDataState(
      isLoadingDaily: isLoadingDaily ?? this.isLoadingDaily,
      isLoadingInventory: isLoadingInventory ?? this.isLoadingInventory,
      isLoadingTopProducts: isLoadingTopProducts ?? this.isLoadingTopProducts,
      dailySummary: dailySummary ?? this.dailySummary,
      inventoryValuation: inventoryValuation ?? this.inventoryValuation,
      topProducts: topProducts ?? this.topProducts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingDaily, isLoadingInventory, isLoadingTopProducts,
        dailySummary, inventoryValuation, topProducts, error
      ];
}

// Keep these for backward-compat references in report_screen (will update screen separately)
class ReportLoading extends ReportState {}
class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object> get props => [message];
}

// BLOC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _repo;

  ReportBloc(this._repo) : super(const ReportDataState()) {
    on<LoadDailySalesSummary>(_onLoadDailySummary);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadInventoryValuation>(_onLoadInventoryValuation);
  }

  ReportDataState get _current =>
      state is ReportDataState ? state as ReportDataState : const ReportDataState();

  Future<void> _onLoadDailySummary(LoadDailySalesSummary event, Emitter<ReportState> emit) async {
    emit(_current.copyWith(isLoadingDaily: true, error: null));
    try {
      final summary = await _repo.getDailySalesSummary(event.date);
      emit(_current.copyWith(isLoadingDaily: false, dailySummary: summary));
    } catch (e) {
      emit(_current.copyWith(isLoadingDaily: false, error: e.toString()));
    }
  }

  Future<void> _onLoadTopProducts(LoadTopProducts event, Emitter<ReportState> emit) async {
    emit(_current.copyWith(isLoadingTopProducts: true, error: null));
    try {
      final products = await _repo.getTopSellingProducts(event.start, event.end, 10);
      emit(_current.copyWith(isLoadingTopProducts: false, topProducts: products));
    } catch (e) {
      emit(_current.copyWith(isLoadingTopProducts: false, error: e.toString()));
    }
  }

  Future<void> _onLoadInventoryValuation(LoadInventoryValuation event, Emitter<ReportState> emit) async {
    emit(_current.copyWith(isLoadingInventory: true, error: null));
    try {
      final total = await _repo.getInventoryTotalValuation();
      emit(_current.copyWith(isLoadingInventory: false, inventoryValuation: total));
    } catch (e) {
      emit(_current.copyWith(isLoadingInventory: false, error: e.toString()));
    }
  }
}
