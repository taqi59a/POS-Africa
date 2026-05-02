import 'package:drift/drift.dart' hide Column;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/sales_repository.dart';

// ══════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════

class _Unset { const _Unset(); }
const _unset = _Unset();

class CartItem extends Equatable {
  final Product product;
  final double quantity;
  final double discount;
  final double? unitPriceOverride;

  const CartItem({
    required this.product,
    required this.quantity,
    this.discount = 0,
    this.unitPriceOverride,
  });

  double get unitPrice => unitPriceOverride ?? product.sellingPrice;

  double get lineTotal => (unitPrice * quantity) - discount;

  CartItem copyWith({double? quantity, double? discount, double? unitPriceOverride}) => CartItem(
    product: product,
    quantity: quantity ?? this.quantity,
    discount: discount ?? this.discount,
    unitPriceOverride: unitPriceOverride ?? this.unitPriceOverride,
  );

  @override
  List<Object?> get props => [product, quantity, discount, unitPriceOverride];
}

class CompletedSaleReceipt {
  final int saleId;
  final String transactionNumber;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double vatAmount;
  final double grandTotal;
  final double grandTotalUsd;
  final double exchangeRate;
  final String paymentMethod;
  final double amountTendered;
  final double changeDue;
  final DateTime saleDate;
  final String? customerName;
  final int? customerId;

  const CompletedSaleReceipt({
    required this.saleId,
    required this.transactionNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.vatAmount = 0,
    required this.grandTotal,
    required this.grandTotalUsd,
    required this.exchangeRate,
    required this.paymentMethod,
    required this.amountTendered,
    required this.changeDue,
    required this.saleDate,
    this.customerName,
    this.customerId,
  });
}

// ══════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════

abstract class SalesEvent extends Equatable {
  const SalesEvent();
  @override
  List<Object?> get props => [];
}

class AddProductToCart extends SalesEvent {
  final Product product;
  const AddProductToCart(this.product);
  @override List<Object> get props => [product];
}

class UpdateCartItemQuantity extends SalesEvent {
  final int productId;
  final double quantity;
  const UpdateCartItemQuantity(this.productId, this.quantity);
}

class RemoveFromCart extends SalesEvent {
  final int productId;
  const RemoveFromCart(this.productId);
}

class UpdateCartItemUnitPrice extends SalesEvent {
  final int productId;
  final double unitPrice;
  const UpdateCartItemUnitPrice(this.productId, this.unitPrice);
}

class ApplyGlobalDiscount extends SalesEvent {
  final double amount;
  const ApplyGlobalDiscount(this.amount);
}

class SetSelectedCustomer extends SalesEvent {
  final Customer? customer;
  const SetSelectedCustomer(this.customer);
  @override List<Object?> get props => [customer];
}

class CompleteSale extends SalesEvent {
  final int cashierId;
  final int? customerId;
  final List<PaymentsCompanion> payments;
  final double grandTotalUsd;
  final double exchangeRate;
  final double vatAmount;
  const CompleteSale({
    required this.cashierId,
    this.customerId,
    required this.payments,
    required this.grandTotalUsd,
    required this.exchangeRate,
    this.vatAmount = 0,
  });
}

class ClearCart extends SalesEvent {}
class DismissSaleReceipt extends SalesEvent {}

// ══════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════

class SalesState extends Equatable {
  final List<CartItem> cart;
  final double globalDiscount;
  final bool isProcessing;
  final String? error;
  final int? lastCompletedSaleId;
  final CompletedSaleReceipt? lastSaleReceipt;
  final Customer? selectedCustomer;

  const SalesState({
    this.cart = const [],
    this.globalDiscount = 0,
    this.isProcessing = false,
    this.error,
    this.lastCompletedSaleId,
    this.lastSaleReceipt,
    this.selectedCustomer,
  });

  double get subtotal => cart.fold(0.0, (s, i) => s + (i.unitPrice * i.quantity));
  double get totalDiscount => cart.fold(0.0, (s, i) => s + i.discount) + globalDiscount;
  double get grandTotal => subtotal - totalDiscount;

  SalesState copyWith({
    List<CartItem>? cart,
    double? globalDiscount,
    bool? isProcessing,
    Object? error = _unset,
    Object? lastCompletedSaleId = _unset,
    Object? lastSaleReceipt = _unset,
    Object? selectedCustomer = _unset,
  }) {
    return SalesState(
      cart: cart ?? this.cart,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error is _Unset ? this.error : error as String?,
      lastCompletedSaleId: lastCompletedSaleId is _Unset ? this.lastCompletedSaleId : lastCompletedSaleId as int?,
      lastSaleReceipt: lastSaleReceipt is _Unset ? this.lastSaleReceipt : lastSaleReceipt as CompletedSaleReceipt?,
      selectedCustomer: selectedCustomer is _Unset ? this.selectedCustomer : selectedCustomer as Customer?,
    );
  }

  @override
  List<Object?> get props => [cart, globalDiscount, isProcessing, error, lastCompletedSaleId, lastSaleReceipt, selectedCustomer];
}

// ══════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final SalesRepository _repo;

  SalesBloc(this._repo) : super(const SalesState()) {
    on<AddProductToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemUnitPrice>(_onUpdateUnitPrice);
    on<ApplyGlobalDiscount>(_onApplyGlobalDiscount);
    on<SetSelectedCustomer>(_onSetSelectedCustomer);
    on<CompleteSale>(_onCompleteSale);
    on<ClearCart>(_onClearCart);
    on<DismissSaleReceipt>(_onDismissReceipt);
  }

  void _onAddToCart(AddProductToCart event, Emitter<SalesState> emit) {
    final idx = state.cart.indexWhere((i) => i.product.id == event.product.id);
    if (idx >= 0) {
      final newCart = List<CartItem>.from(state.cart);
      newCart[idx] = newCart[idx].copyWith(quantity: newCart[idx].quantity + 1);
      emit(state.copyWith(cart: newCart));
    } else {
      emit(state.copyWith(cart: [...state.cart, CartItem(product: event.product, quantity: 1)]));
    }
  }

  void _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<SalesState> emit) {
    final newCart = state.cart
        .map((i) => i.product.id == event.productId ? i.copyWith(quantity: event.quantity) : i)
        .where((i) => i.quantity > 0)
        .toList();
    emit(state.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<SalesState> emit) {
    emit(state.copyWith(cart: state.cart.where((i) => i.product.id != event.productId).toList()));
  }

  void _onUpdateUnitPrice(UpdateCartItemUnitPrice event, Emitter<SalesState> emit) {
    final newCart = state.cart.map((i) {
      if (i.product.id != event.productId) return i;
      // Never allow a temporary sale price below product cost price.
      final guarded = event.unitPrice < i.product.costPrice
          ? i.product.costPrice
          : event.unitPrice;
      return i.copyWith(unitPriceOverride: guarded);
    }).toList();
    emit(state.copyWith(cart: newCart));
  }

  void _onApplyGlobalDiscount(ApplyGlobalDiscount event, Emitter<SalesState> emit) {
    emit(state.copyWith(globalDiscount: event.amount));
  }

  void _onSetSelectedCustomer(SetSelectedCustomer event, Emitter<SalesState> emit) {
    emit(state.copyWith(selectedCustomer: event.customer));
  }

  void _onClearCart(ClearCart event, Emitter<SalesState> emit) {
    emit(SalesState(selectedCustomer: state.selectedCustomer));
  }

  Future<void> _onCompleteSale(CompleteSale event, Emitter<SalesState> emit) async {
    if (state.cart.isEmpty) return;
    emit(state.copyWith(isProcessing: true, error: null));
    try {
      final trxNumber = await _repo.generateTransactionNumber();

      final saleCompanion = SalesCompanion.insert(
        transactionNumber: trxNumber,
        cashierId: Value(event.cashierId),
        customerId: Value(event.customerId),
        subtotal: Value(state.subtotal),
        discountAmount: Value(state.totalDiscount),
        vatAmount: Value(event.vatAmount),
        grandTotal: Value(state.grandTotal),
        grandTotalUsd: Value(event.grandTotalUsd),
        exchangeRateUsed: Value(event.exchangeRate),
      );

      final lineCompanions = state.cart.map((item) => SaleLinesCompanion.insert(
        productId: item.product.id,
        saleId: 0,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: Value(item.discount),
        lineTotal: item.lineTotal,
      )).toList();

      final saleId = await _repo.createSale(saleCompanion, lineCompanions, event.payments);

      final receipt = CompletedSaleReceipt(
        saleId: saleId,
        transactionNumber: trxNumber,
        items: List<CartItem>.from(state.cart),
        subtotal: state.subtotal,
        discount: state.totalDiscount,
        vatAmount: event.vatAmount,
        grandTotal: state.grandTotal,
        grandTotalUsd: event.grandTotalUsd,
        exchangeRate: event.exchangeRate,
        paymentMethod: event.payments.isNotEmpty ? event.payments.first.method.value : 'CASH',
        amountTendered: event.payments.isNotEmpty
            ? (event.payments.first.amountTendered.value ?? state.grandTotal)
            : state.grandTotal,
        changeDue: event.payments.isNotEmpty
            ? (event.payments.first.changeDue.value ?? 0)
            : 0,
        saleDate: DateTime.now(),
        customerName: state.selectedCustomer?.fullName,
        customerId: event.customerId,
      );

      emit(SalesState(
        isProcessing: false,
        lastCompletedSaleId: saleId,
        lastSaleReceipt: receipt,
        selectedCustomer: state.selectedCustomer,
      ));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.toString()));
    }
  }

  void _onDismissReceipt(DismissSaleReceipt event, Emitter<SalesState> emit) {
    emit(SalesState(selectedCustomer: state.selectedCustomer));
  }
}
