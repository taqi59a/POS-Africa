import 'package:drift/drift.dart' hide Column;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/returns_repository.dart';

// ══════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════

abstract class ReturnsEvent extends Equatable {
  const ReturnsEvent();
  @override
  List<Object?> get props => [];
}

class LoadAllReturns extends ReturnsEvent {
  const LoadAllReturns();
}

class LoadReturnsByDate extends ReturnsEvent {
  final DateTime start;
  final DateTime end;
  const LoadReturnsByDate(this.start, this.end);
  @override
  List<Object> get props => [start, end];
}

class SearchSalesForReturn extends ReturnsEvent {
  final String query;
  const SearchSalesForReturn(this.query);
  @override
  List<Object> get props => [query];
}

class LoadSaleForReturn extends ReturnsEvent {
  final int saleId;
  const LoadSaleForReturn(this.saleId);
  @override
  List<Object> get props => [saleId];
}

class ClearSaleForReturn extends ReturnsEvent {
  const ClearSaleForReturn();
}

class SubmitReturn extends ReturnsEvent {
  final int? cashierId;
  final int? originalSaleId;
  final String reason;
  final String refundMethod;
  final double exchangeRate;
  final List<_ReturnLineInput> lines;

  const SubmitReturn({
    this.cashierId,
    this.originalSaleId,
    required this.reason,
    required this.refundMethod,
    required this.exchangeRate,
    required this.lines,
  });
  @override
  List<Object?> get props => [originalSaleId, reason, lines];
}

class VoidReturn extends ReturnsEvent {
  final int returnId;
  final String reason;
  const VoidReturn(this.returnId, this.reason);
  @override
  List<Object> get props => [returnId, reason];
}

class DismissReturnSuccess extends ReturnsEvent {
  const DismissReturnSuccess();
}

/// Simple data holder for a line item being returned
class _ReturnLineInput extends Equatable {
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final int? originalSaleLineId;

  const _ReturnLineInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.originalSaleLineId,
  });

  double get lineTotal => quantity * unitPrice;

  ReturnLinesCompanion toCompanion(int returnId) => ReturnLinesCompanion.insert(
        returnId: returnId,
        productId: productId,
        productName: productName,
        quantity: quantity,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
        originalSaleLineId: Value(originalSaleLineId),
      );

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}

// Export _ReturnLineInput publicly via typedef
typedef ReturnLineInput = _ReturnLineInput;

// ══════════════════════════════════════════════
// STATE
// ══════════════════════════════════════════════

class ReturnsState extends Equatable {
  final bool isLoading;
  final bool isProcessing;
  final List<Map<String, dynamic>> returns;
  final List<Map<String, dynamic>> saleSearchResults;
  final Map<String, dynamic>? selectedSaleForReturn;
  final String? successMessage;
  final int? lastReturnId;
  final String? error;

  const ReturnsState({
    this.isLoading = false,
    this.isProcessing = false,
    this.returns = const [],
    this.saleSearchResults = const [],
    this.selectedSaleForReturn,
    this.successMessage,
    this.lastReturnId,
    this.error,
  });

  ReturnsState copyWith({
    bool? isLoading,
    bool? isProcessing,
    List<Map<String, dynamic>>? returns,
    List<Map<String, dynamic>>? saleSearchResults,
    Object? selectedSaleForReturn = _sentinel,
    Object? successMessage = _sentinel,
    Object? lastReturnId = _sentinel,
    Object? error = _sentinel,
  }) {
    return ReturnsState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      returns: returns ?? this.returns,
      saleSearchResults: saleSearchResults ?? this.saleSearchResults,
      selectedSaleForReturn: selectedSaleForReturn is _Sentinel
          ? this.selectedSaleForReturn
          : selectedSaleForReturn as Map<String, dynamic>?,
      successMessage: successMessage is _Sentinel
          ? this.successMessage
          : successMessage as String?,
      lastReturnId:
          lastReturnId is _Sentinel ? this.lastReturnId : lastReturnId as int?,
      error: error is _Sentinel ? this.error : error as String?,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isProcessing,
        returns,
        saleSearchResults,
        selectedSaleForReturn,
        successMessage,
        lastReturnId,
        error,
      ];
}

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

// ══════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════

class ReturnsBloc extends Bloc<ReturnsEvent, ReturnsState> {
  final ReturnsRepository _repo;

  ReturnsBloc(this._repo) : super(const ReturnsState()) {
    on<LoadAllReturns>(_onLoadAll);
    on<LoadReturnsByDate>(_onLoadByDate);
    on<SearchSalesForReturn>(_onSearchSales);
    on<LoadSaleForReturn>(_onLoadSale);
    on<ClearSaleForReturn>(_onClearSale);
    on<SubmitReturn>(_onSubmit);
    on<VoidReturn>(_onVoid);
    on<DismissReturnSuccess>(_onDismiss);
  }

  Future<void> _onLoadAll(
      LoadAllReturns event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repo.getAllReturns();
      emit(state.copyWith(isLoading: false, returns: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadByDate(
      LoadReturnsByDate event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _repo.getReturnsByDateRange(event.start, event.end);
      emit(state.copyWith(isLoading: false, returns: data));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSearchSales(
      SearchSalesForReturn event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await _repo.searchSalesForReturn(event.query);
      emit(state.copyWith(isLoading: false, saleSearchResults: results));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadSale(
      LoadSaleForReturn event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final detail = await _repo.getSaleDetail(event.saleId);
      emit(state.copyWith(
          isLoading: false, selectedSaleForReturn: detail, saleSearchResults: []));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onClearSale(ClearSaleForReturn event, Emitter<ReturnsState> emit) {
    emit(state.copyWith(
        selectedSaleForReturn: null, saleSearchResults: []));
  }

  Future<void> _onSubmit(
      SubmitReturn event, Emitter<ReturnsState> emit) async {
    if (event.lines.isEmpty) {
      emit(state.copyWith(error: 'No items selected for return'));
      return;
    }
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      final returnNumber = await _repo.generateReturnNumber();
      final totalRefund = event.lines.fold<double>(
          0.0, (s, l) => s + l.lineTotal);
      final rate = event.exchangeRate > 0 ? event.exchangeRate : 1.0;

      final header = SaleReturnsCompanion.insert(
        returnNumber: returnNumber,
        originalSaleId: Value(event.originalSaleId),
        processedByUserId: Value(event.cashierId),
        reason: Value(event.reason),
        refundMethod: Value(event.refundMethod),
        totalRefundAmount: Value(totalRefund),
        totalRefundAmountUsd: Value(totalRefund / rate),
        exchangeRateUsed: Value(rate),
      );

      final companions = event.lines
          .map((l) => ReturnLinesCompanion.insert(
                returnId: 0, // placeholder – repo replaces
                productId: l.productId,
                productName: l.productName,
                quantity: l.quantity,
                unitPrice: l.unitPrice,
                lineTotal: l.lineTotal,
                originalSaleLineId: Value(l.originalSaleLineId),
              ))
          .toList();

      final returnId =
          await _repo.processReturn(returnHeader: header, lines: companions);

      emit(state.copyWith(
        isProcessing: false,
        lastReturnId: returnId,
        successMessage: 'Return $returnNumber processed successfully',
        selectedSaleForReturn: null,
        saleSearchResults: [],
      ));
      add(const LoadAllReturns());
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.toString()));
    }
  }

  Future<void> _onVoid(VoidReturn event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      await _repo.voidReturn(event.returnId, event.reason);
      emit(state.copyWith(isProcessing: false,
          successMessage: 'Return #${event.returnId} voided'));
      add(const LoadAllReturns());
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.toString()));
    }
  }

  void _onDismiss(DismissReturnSuccess event, Emitter<ReturnsState> emit) {
    emit(state.copyWith(successMessage: null, lastReturnId: null));
  }
}
