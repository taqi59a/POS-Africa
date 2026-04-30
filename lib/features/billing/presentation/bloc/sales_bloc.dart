import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/sales_repository.dart';

// ══════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════

class CartItem extends Equatable {
  final Product product;
  final double quantity;
  final double discount; // CDF fixed amount

  const CartItem({
    required this.product,
    required this.quantity,
    this.discount = 0,
  });

  double get lineTotal => (product.sellingPrice * quantity) - discount;

  CartItem copyWith({double? quantity, double? discount}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [product, quantity, discount];
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
  @override
  List<Object> get props => [product];
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

class ApplyGlobalDiscount extends SalesEvent {
  final double amount;
  const ApplyGlobalDiscount(this.amount);
}

class CompleteSale extends SalesEvent {
  final int cashierId;
  final int? customerId;
  final List<PaymentsCompanion> payments;
  final double grandTotalUsd;
  final double exchangeRate;
  const CompleteSale({
    required this.cashierId,
    this.customerId,
    required this.payments,
    required this.grandTotalUsd,
    required this.exchangeRate,
  });
}

class ClearCart extends SalesEvent {}

// ══════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════

class SalesState extends Equatable {
  final List<CartItem> cart;
  final double globalDiscount;
  final bool isProcessing;
  final String? error;
  final int? lastCompletedSaleId;

  const SalesState({
    this.cart = const [],
    this.globalDiscount = 0,
    this.isProcessing = false,
    this.error,
    this.lastCompletedSaleId,
  });

  double get subtotal => cart.fold(0, (sum, item) => sum + (item.product.sellingPrice * item.quantity));
  double get totalDiscount => cart.fold(0, (sum, item) => sum + item.discount) + globalDiscount;
  double get grandTotal => subtotal - totalDiscount;

  SalesState copyWith({
    List<CartItem>? cart,
    double? globalDiscount,
    bool? isProcessing,
    String? error,
    int? lastCompletedSaleId,
  }) {
    return SalesState(
      cart: cart ?? this.cart,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastCompletedSaleId: lastCompletedSaleId,
    );
  }

  @override
  List<Object?> get props => [cart, globalDiscount, isProcessing, error, lastCompletedSaleId];
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
    on<ApplyGlobalDiscount>(_onApplyGlobalDiscount);
    on<CompleteSale>(_onCompleteSale);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddProductToCart event, Emitter<SalesState> emit) {
    final existingIndex = state.cart.indexWhere((item) => item.product.id == event.product.id);
    if (existingIndex >= 0) {
      final newCart = List<CartItem>.from(state.cart);
      newCart[existingIndex] = newCart[existingIndex].copyWith(
        quantity: newCart[existingIndex].quantity + 1,
      );
      emit(state.copyWith(cart: newCart));
    } else {
      emit(state.copyWith(cart: [...state.cart, CartItem(product: event.product, quantity: 1)]));
    }
  }

  void _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<SalesState> emit) {
    final newCart = state.cart.map((item) {
      if (item.product.id == event.productId) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).where((item) => item.quantity > 0).toList();
    emit(state.copyWith(cart: newCart));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<SalesState> emit) {
    final newCart = state.cart.where((item) => item.product.id != event.productId).toList();
    emit(state.copyWith(cart: newCart));
  }

  void _onApplyGlobalDiscount(ApplyGlobalDiscount event, Emitter<SalesState> emit) {
    emit(state.copyWith(globalDiscount: event.amount));
  }

  void _onClearCart(ClearCart event, Emitter<SalesState> emit) {
    emit(const SalesState());
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
        grandTotal: Value(state.grandTotal),
        grandTotalUsd: Value(event.grandTotalUsd),
        exchangeRateUsed: Value(event.exchangeRate),
      );

      final lineCompanions = state.cart.map((item) => SaleLinesCompanion.insert(
        productId: item.product.id,
        saleId: const Value(0), // Placeholder, will be replaced in repo
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.product.sellingPrice,
        discountAmount: Value(item.discount),
        lineTotal: item.lineTotal,
      )).toList();

      final saleId = await _repo.createSale(saleCompanion, lineCompanions, event.payments);
      
      emit(state.copyWith(
        isProcessing: false,
        lastCompletedSaleId: saleId,
        cart: [],
        globalDiscount: 0,
      ));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, error: e.toString()));
    }
  }
}
