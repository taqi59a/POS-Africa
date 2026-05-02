import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/report_repository.dart';

// ══════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override List<Object?> get props => [];
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

class LoadSalesReport extends ReportEvent {
  final DateTime start;
  final DateTime end;
  const LoadSalesReport(this.start, this.end);
  @override List<Object> get props => [start, end];
}

class LoadSalesProfitReport extends ReportEvent {
  final DateTime start;
  final DateTime end;
  final int? cashierId;
  const LoadSalesProfitReport(this.start, this.end, {this.cashierId});
  @override List<Object?> get props => [start, end, cashierId];
}

class LoadCustomerLedger extends ReportEvent {
  const LoadCustomerLedger();
}

class LoadCustomerPurchases extends ReportEvent {
  final int? customerId;
  final DateTime start;
  final DateTime end;
  const LoadCustomerPurchases(this.start, this.end, {this.customerId});
  @override List<Object?> get props => [start, end, customerId];
}

class LoadExpenseReport extends ReportEvent {
  final DateTime start;
  final DateTime end;
  const LoadExpenseReport(this.start, this.end);
  @override List<Object> get props => [start, end];
}

class LoadInventoryReport extends ReportEvent {
  const LoadInventoryReport();
}

class LoadProductSalesHistory extends ReportEvent {
  final int? productId;
  final DateTime start;
  final DateTime end;
  const LoadProductSalesHistory(this.start, this.end, {this.productId});
  @override List<Object?> get props => [start, end, productId];
}

class FindReceiptsForReprint extends ReportEvent {
  final String query;
  final DateTime? start;
  final DateTime? end;
  const FindReceiptsForReprint(this.query, {this.start, this.end});
  @override List<Object?> get props => [query, start, end];
}

class LoadSaleDetail extends ReportEvent {
  final int saleId;
  const LoadSaleDetail(this.saleId);
  @override List<Object> get props => [saleId];
}

// ══════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════

abstract class ReportState extends Equatable {
  const ReportState();
  @override List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportDataState extends ReportState {
  // Daily summary
  final bool isLoadingDaily;
  final Map<String, double>? dailySummary;
  // Top products
  final bool isLoadingTopProducts;
  final List<Map<String, dynamic>>? topProducts;
  // Inventory valuation
  final bool isLoadingInventory;
  final double? inventoryValuation;
  // Sales report
  final bool isLoadingSalesReport;
  final List<Map<String, dynamic>>? salesReport;
  // Sales + profit report
  final bool isLoadingSalesProfitReport;
  final Map<String, dynamic>? salesProfitReport;
  // Customer ledger
  final bool isLoadingCustomerLedger;
  final List<Map<String, dynamic>>? customerLedger;
  // Customer purchases
  final bool isLoadingCustomerPurchases;
  final List<Map<String, dynamic>>? customerPurchases;
  // Expense report
  final bool isLoadingExpenseReport;
  final List<Map<String, dynamic>>? expenseReport;
  // Inventory detailed report
  final bool isLoadingInventoryReport;
  final List<Map<String, dynamic>>? inventoryReport;
  // Product sales history
  final bool isLoadingProductHistory;
  final List<Map<String, dynamic>>? productHistory;
  // Receipt search results
  final bool isLoadingReceipts;
  final List<Map<String, dynamic>>? receiptSearchResults;
  // Selected sale detail (for reprint)
  final bool isLoadingSaleDetail;
  final Map<String, dynamic>? saleDetail;
  // Error
  final String? error;

  const ReportDataState({
    this.isLoadingDaily = false,
    this.dailySummary,
    this.isLoadingTopProducts = false,
    this.topProducts,
    this.isLoadingInventory = false,
    this.inventoryValuation,
    this.isLoadingSalesReport = false,
    this.salesReport,
    this.isLoadingSalesProfitReport = false,
    this.salesProfitReport,
    this.isLoadingCustomerLedger = false,
    this.customerLedger,
    this.isLoadingCustomerPurchases = false,
    this.customerPurchases,
    this.isLoadingExpenseReport = false,
    this.expenseReport,
    this.isLoadingInventoryReport = false,
    this.inventoryReport,
    this.isLoadingProductHistory = false,
    this.productHistory,
    this.isLoadingReceipts = false,
    this.receiptSearchResults,
    this.isLoadingSaleDetail = false,
    this.saleDetail,
    this.error,
  });

  ReportDataState copyWith({
    bool? isLoadingDaily, Map<String, double>? dailySummary,
    bool? isLoadingTopProducts, List<Map<String, dynamic>>? topProducts,
    bool? isLoadingInventory, double? inventoryValuation,
    bool? isLoadingSalesReport, List<Map<String, dynamic>>? salesReport,
    bool? isLoadingSalesProfitReport, Map<String, dynamic>? salesProfitReport,
    bool? isLoadingCustomerLedger, List<Map<String, dynamic>>? customerLedger,
    bool? isLoadingCustomerPurchases, List<Map<String, dynamic>>? customerPurchases,
    bool? isLoadingExpenseReport, List<Map<String, dynamic>>? expenseReport,
    bool? isLoadingInventoryReport, List<Map<String, dynamic>>? inventoryReport,
    bool? isLoadingProductHistory, List<Map<String, dynamic>>? productHistory,
    bool? isLoadingReceipts, List<Map<String, dynamic>>? receiptSearchResults,
    bool? isLoadingSaleDetail, Map<String, dynamic>? saleDetail,
    String? error,
  }) {
    return ReportDataState(
      isLoadingDaily: isLoadingDaily ?? this.isLoadingDaily,
      dailySummary: dailySummary ?? this.dailySummary,
      isLoadingTopProducts: isLoadingTopProducts ?? this.isLoadingTopProducts,
      topProducts: topProducts ?? this.topProducts,
      isLoadingInventory: isLoadingInventory ?? this.isLoadingInventory,
      inventoryValuation: inventoryValuation ?? this.inventoryValuation,
      isLoadingSalesReport: isLoadingSalesReport ?? this.isLoadingSalesReport,
      salesReport: salesReport ?? this.salesReport,
        isLoadingSalesProfitReport:
          isLoadingSalesProfitReport ?? this.isLoadingSalesProfitReport,
        salesProfitReport: salesProfitReport ?? this.salesProfitReport,
      isLoadingCustomerLedger: isLoadingCustomerLedger ?? this.isLoadingCustomerLedger,
      customerLedger: customerLedger ?? this.customerLedger,
      isLoadingCustomerPurchases: isLoadingCustomerPurchases ?? this.isLoadingCustomerPurchases,
      customerPurchases: customerPurchases ?? this.customerPurchases,
      isLoadingExpenseReport: isLoadingExpenseReport ?? this.isLoadingExpenseReport,
      expenseReport: expenseReport ?? this.expenseReport,
      isLoadingInventoryReport: isLoadingInventoryReport ?? this.isLoadingInventoryReport,
      inventoryReport: inventoryReport ?? this.inventoryReport,
      isLoadingProductHistory: isLoadingProductHistory ?? this.isLoadingProductHistory,
      productHistory: productHistory ?? this.productHistory,
      isLoadingReceipts: isLoadingReceipts ?? this.isLoadingReceipts,
      receiptSearchResults: receiptSearchResults ?? this.receiptSearchResults,
      isLoadingSaleDetail: isLoadingSaleDetail ?? this.isLoadingSaleDetail,
      saleDetail: saleDetail ?? this.saleDetail,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoadingDaily, dailySummary, isLoadingTopProducts, topProducts,
    isLoadingInventory, inventoryValuation, isLoadingSalesReport, salesReport,
    isLoadingSalesProfitReport, salesProfitReport,
    isLoadingCustomerLedger, customerLedger, isLoadingCustomerPurchases, customerPurchases,
    isLoadingExpenseReport, expenseReport, isLoadingInventoryReport, inventoryReport,
    isLoadingProductHistory, productHistory, isLoadingReceipts, receiptSearchResults,
    isLoadingSaleDetail, saleDetail, error,
  ];
}

// Keep for backward compat
class ReportLoading extends ReportState {}
class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override List<Object> get props => [message];
}

// ══════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _repo;

  ReportBloc(this._repo) : super(const ReportDataState()) {
    on<LoadDailySalesSummary>(_onLoadDailySummary);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadInventoryValuation>(_onLoadInventoryValuation);
    on<LoadSalesReport>(_onLoadSalesReport);
    on<LoadSalesProfitReport>(_onLoadSalesProfitReport);
    on<LoadCustomerLedger>(_onLoadCustomerLedger);
    on<LoadCustomerPurchases>(_onLoadCustomerPurchases);
    on<LoadExpenseReport>(_onLoadExpenseReport);
    on<LoadInventoryReport>(_onLoadInventoryReport);
    on<LoadProductSalesHistory>(_onLoadProductSalesHistory);
    on<FindReceiptsForReprint>(_onFindReceiptsForReprint);
    on<LoadSaleDetail>(_onLoadSaleDetail);
  }

  ReportDataState get _cur =>
      state is ReportDataState ? state as ReportDataState : const ReportDataState();

  Future<void> _onLoadDailySummary(LoadDailySalesSummary event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingDaily: true, error: null));
    try {
      final summary = await _repo.getDailySalesSummary(event.date);
      emit(_cur.copyWith(isLoadingDaily: false, dailySummary: summary));
    } catch (e) {
      emit(_cur.copyWith(isLoadingDaily: false, error: e.toString()));
    }
  }

  Future<void> _onLoadTopProducts(LoadTopProducts event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingTopProducts: true, error: null));
    try {
      final products = await _repo.getTopSellingProducts(event.start, event.end, 15);
      emit(_cur.copyWith(isLoadingTopProducts: false, topProducts: products));
    } catch (e) {
      emit(_cur.copyWith(isLoadingTopProducts: false, error: e.toString()));
    }
  }

  Future<void> _onLoadInventoryValuation(LoadInventoryValuation event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingInventory: true, error: null));
    try {
      final total = await _repo.getInventoryTotalValuation();
      emit(_cur.copyWith(isLoadingInventory: false, inventoryValuation: total));
    } catch (e) {
      emit(_cur.copyWith(isLoadingInventory: false, error: e.toString()));
    }
  }

  Future<void> _onLoadSalesReport(LoadSalesReport event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingSalesReport: true, error: null));
    try {
      final data = await _repo.getSalesReport(event.start, event.end);
      emit(_cur.copyWith(isLoadingSalesReport: false, salesReport: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingSalesReport: false, error: e.toString()));
    }
  }

  Future<void> _onLoadSalesProfitReport(
      LoadSalesProfitReport event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingSalesProfitReport: true, error: null));
    try {
      final data = await _repo.getSalesAndProfitReport(
        event.start,
        event.end,
        cashierId: event.cashierId,
      );
      emit(_cur.copyWith(
        isLoadingSalesProfitReport: false,
        salesProfitReport: data,
      ));
    } catch (e) {
      emit(_cur.copyWith(isLoadingSalesProfitReport: false, error: e.toString()));
    }
  }

  Future<void> _onLoadCustomerLedger(LoadCustomerLedger event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingCustomerLedger: true, error: null));
    try {
      final data = await _repo.getCustomerLedger();
      emit(_cur.copyWith(isLoadingCustomerLedger: false, customerLedger: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingCustomerLedger: false, error: e.toString()));
    }
  }

  Future<void> _onLoadCustomerPurchases(LoadCustomerPurchases event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingCustomerPurchases: true, error: null));
    try {
      final data = await _repo.getCustomerPurchases(event.customerId, event.start, event.end);
      emit(_cur.copyWith(isLoadingCustomerPurchases: false, customerPurchases: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingCustomerPurchases: false, error: e.toString()));
    }
  }

  Future<void> _onLoadExpenseReport(LoadExpenseReport event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingExpenseReport: true, error: null));
    try {
      final data = await _repo.getExpensesDetailed(event.start, event.end);
      emit(_cur.copyWith(isLoadingExpenseReport: false, expenseReport: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingExpenseReport: false, error: e.toString()));
    }
  }

  Future<void> _onLoadInventoryReport(LoadInventoryReport event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingInventoryReport: true, error: null));
    try {
      final data = await _repo.getInventoryReport();
      emit(_cur.copyWith(isLoadingInventoryReport: false, inventoryReport: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingInventoryReport: false, error: e.toString()));
    }
  }

  Future<void> _onLoadProductSalesHistory(
      LoadProductSalesHistory event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingProductHistory: true, error: null));
    try {
      final data = await _repo.getProductSalesHistory(event.productId, event.start, event.end);
      emit(_cur.copyWith(isLoadingProductHistory: false, productHistory: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingProductHistory: false, error: e.toString()));
    }
  }

  Future<void> _onFindReceiptsForReprint(
      FindReceiptsForReprint event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingReceipts: true, error: null));
    try {
      final data = await _repo.findReceiptsForReprint(event.query, event.start, event.end);
      emit(_cur.copyWith(isLoadingReceipts: false, receiptSearchResults: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingReceipts: false, error: e.toString()));
    }
  }

  Future<void> _onLoadSaleDetail(
      LoadSaleDetail event, Emitter<ReportState> emit) async {
    emit(_cur.copyWith(isLoadingSaleDetail: true, error: null));
    try {
      final data = await _repo.getSaleDetail(event.saleId);
      emit(_cur.copyWith(isLoadingSaleDetail: false, saleDetail: data));
    } catch (e) {
      emit(_cur.copyWith(isLoadingSaleDetail: false, error: e.toString()));
    }
  }
}

