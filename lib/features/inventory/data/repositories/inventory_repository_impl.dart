import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final AppDatabase _db;

  InventoryRepositoryImpl(this._db);

  // ── Products ──────────────────────────────────────────────────────────────

  @override
  Future<List<Product>> getAllProducts() =>
      (_db.select(_db.products)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  @override
  Future<List<Product>> searchProducts(String query) =>
      (_db.select(_db.products)
            ..where((t) => t.name.contains(query) | t.barcode.contains(query) | t.sku.contains(query))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  @override
  Future<List<Product>> getLowStockProducts() =>
      (_db.select(_db.products)
            ..where((t) => t.stockQuantity.isSmallerOrEqualValue(t.minimumStockLevel))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  @override
  Future<Product?> getProductById(int id) =>
      (_db.select(_db.products)..where((t) => t.id.equals(id))).getSingleOrNull();

  @override
  Future<Product?> getProductByBarcode(String barcode) =>
      (_db.select(_db.products)..where((t) => t.barcode.equals(barcode))).getSingleOrNull();

  @override
  Future<int> addProduct(ProductsCompanion product) =>
      _db.into(_db.products).insert(product);

  @override
  Future<void> updateProduct(int id, ProductsCompanion product) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      product.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> toggleProductActive(int id, bool isActive) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(isActive: Value(isActive), updatedAt: Value(DateTime.now())),
    );
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<Category>> getAllCategories() =>
      (_db.select(_db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  @override
  Future<int> addCategory(CategoriesCompanion category) =>
      _db.into(_db.categories).insert(category);

  // ── Suppliers ─────────────────────────────────────────────────────────────

  @override
  Future<List<Supplier>> getAllSuppliers() =>
      (_db.select(_db.suppliers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  @override
  Future<int> addSupplier(SuppliersCompanion supplier) =>
      _db.into(_db.suppliers).insert(supplier);

  @override
  Future<void> updateSupplier(int id, SuppliersCompanion supplier) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(supplier);
  }

  // ── Stock Adjustments ─────────────────────────────────────────────────────

  @override
  Future<void> adjustStock({
    required int productId,
    required int userId,
    required double quantityChange,
    required String movementType,
    String? reasonCode,
    String? notes,
  }) async {
    final product = await getProductById(productId);
    if (product == null) throw Exception('Product not found');

    final stockBefore = product.stockQuantity;
    final stockAfter = stockBefore + quantityChange;

    await _db.transaction(() async {
      // Update stock quantity
      await (_db.update(_db.products)..where((t) => t.id.equals(productId))).write(
        ProductsCompanion(stockQuantity: Value(stockAfter), updatedAt: Value(DateTime.now())),
      );

      // Log stock movement
      await _db.into(_db.stockMovements).insert(
        StockMovementsCompanion.insert(
          productId: productId,
          userId: Value(userId),
          movementType: movementType,
          reasonCode: Value(reasonCode),
          quantityChange: quantityChange,
          stockBefore: stockBefore,
          stockAfter: stockAfter,
          notes: Value(notes),
        ),
      );
    });
  }

  @override
  Future<List<StockMovement>> getStockMovementsForProduct(int productId) =>
      (_db.select(_db.stockMovements)
            ..where((t) => t.productId.equals(productId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();
}
