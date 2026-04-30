import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';

// ══════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends InventoryEvent {}
class SearchProducts extends InventoryEvent {
  final String query;
  const SearchProducts(this.query);
  @override
  List<Object> get props => [query];
}
class LoadLowStockProducts extends InventoryEvent {}
class LoadCategories extends InventoryEvent {}
class LoadSuppliers extends InventoryEvent {}
class AddProduct extends InventoryEvent {
  final ProductsCompanion product;
  const AddProduct(this.product);
  @override
  List<Object> get props => [product];
}
class UpdateProduct extends InventoryEvent {
  final int id;
  final ProductsCompanion product;
  const UpdateProduct(this.id, this.product);
  @override
  List<Object> get props => [id, product];
}
class ToggleProductActive extends InventoryEvent {
  final int id;
  final bool isActive;
  const ToggleProductActive(this.id, this.isActive);
  @override
  List<Object> get props => [id, isActive];
}
class AdjustStock extends InventoryEvent {
  final int productId;
  final int userId;
  final double quantityChange;
  final String movementType;
  final String? reasonCode;
  final String? notes;
  const AdjustStock({
    required this.productId,
    required this.userId,
    required this.quantityChange,
    required this.movementType,
    this.reasonCode,
    this.notes,
  });
}

// ══════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════
abstract class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}
class InventoryLoading extends InventoryState {}
class InventoryLoaded extends InventoryState {
  final List<Product> products;
  final List<Category> categories;
  final List<Supplier> suppliers;
  final String? searchQuery;
  const InventoryLoaded({
    required this.products,
    required this.categories,
    required this.suppliers,
    this.searchQuery,
  });
  @override
  List<Object?> get props => [products, categories, suppliers, searchQuery];
}
class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object> get props => [message];
}
class InventoryActionSuccess extends InventoryState {
  final String message;
  const InventoryActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// ══════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository _repo;

  InventoryBloc(this._repo) : super(InventoryInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<LoadLowStockProducts>(_onLoadLowStock);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<ToggleProductActive>(_onToggleActive);
    on<AdjustStock>(_onAdjustStock);
  }

  Future<void> _refresh(Emitter<InventoryState> emit, {String? query}) async {
    final products = query != null && query.isNotEmpty
        ? await _repo.searchProducts(query)
        : await _repo.getAllProducts();
    final cats = await _repo.getAllCategories();
    final sups = await _repo.getAllSuppliers();
    emit(InventoryLoaded(products: products, categories: cats, suppliers: sups, searchQuery: query));
  }

  Future<void> _onLoadProducts(LoadProducts e, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try { await _refresh(emit); } catch (ex) { emit(InventoryError(ex.toString())); }
  }

  Future<void> _onSearchProducts(SearchProducts e, Emitter<InventoryState> emit) async {
    try { await _refresh(emit, query: e.query); } catch (ex) { emit(InventoryError(ex.toString())); }
  }

  Future<void> _onLoadLowStock(LoadLowStockProducts e, Emitter<InventoryState> emit) async {
    emit(InventoryLoading());
    try {
      final products = await _repo.getLowStockProducts();
      final cats = await _repo.getAllCategories();
      final sups = await _repo.getAllSuppliers();
      emit(InventoryLoaded(products: products, categories: cats, suppliers: sups));
    } catch (ex) { emit(InventoryError(ex.toString())); }
  }

  Future<void> _onAddProduct(AddProduct e, Emitter<InventoryState> emit) async {
    try {
      await _repo.addProduct(e.product);
      emit(const InventoryActionSuccess('Product added successfully.'));
      await _refresh(emit);
    } catch (ex) { emit(InventoryError('Failed to add product: $ex')); }
  }

  Future<void> _onUpdateProduct(UpdateProduct e, Emitter<InventoryState> emit) async {
    try {
      await _repo.updateProduct(e.id, e.product);
      emit(const InventoryActionSuccess('Product updated successfully.'));
      await _refresh(emit);
    } catch (ex) { emit(InventoryError('Failed to update product: $ex')); }
  }

  Future<void> _onToggleActive(ToggleProductActive e, Emitter<InventoryState> emit) async {
    try {
      await _repo.toggleProductActive(e.id, e.isActive);
      await _refresh(emit);
    } catch (ex) { emit(InventoryError(ex.toString())); }
  }

  Future<void> _onAdjustStock(AdjustStock e, Emitter<InventoryState> emit) async {
    try {
      await _repo.adjustStock(
        productId: e.productId,
        userId: e.userId,
        quantityChange: e.quantityChange,
        movementType: e.movementType,
        reasonCode: e.reasonCode,
        notes: e.notes,
      );
      emit(const InventoryActionSuccess('Stock adjusted successfully.'));
      await _refresh(emit);
    } catch (ex) { emit(InventoryError('Failed to adjust stock: $ex')); }
  }
}
