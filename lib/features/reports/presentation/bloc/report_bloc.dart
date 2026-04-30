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
class ReportLoading extends ReportState {}
class DailySummaryLoaded extends ReportState {
  final Map<String, double> summary;
  const DailySummaryLoaded(this.summary);
  @override
  List<Object> get props => [summary];
}
class TopProductsLoaded extends ReportState {
  final List<Map<String, dynamic>> products;
  const TopProductsLoaded(this.products);
}
class InventoryValuationLoaded extends ReportState {
  final double total;
  const InventoryValuationLoaded(this.total);
}
class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
}

// BLOC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _repo;

  ReportBloc(this._repo) : super(ReportInitial()) {
    on<LoadDailySalesSummary>(_onLoadDailySummary);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadInventoryValuation>(_onLoadInventoryValuation);
  }

  Future<void> _onLoadDailySummary(LoadDailySalesSummary event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final summary = await _repo.getDailySalesSummary(event.date);
      emit(DailySummaryLoaded(summary));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadTopProducts(LoadTopProducts event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final products = await _repo.getTopSellingProducts(event.start, event.end, 10);
      emit(TopProductsLoaded(products));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadInventoryValuation(LoadInventoryValuation event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final total = await _repo.getInventoryTotalValuation();
      emit(InventoryValuationLoaded(total));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}
