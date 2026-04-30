import '../../../../core/data/database/app_database.dart';

abstract class InventoryRepository {
  // Products
  Future<List<Product>> getAllProducts();
  Future<List<Product>> searchProducts(String query);
  Future<List<Product>> getLowStockProducts();
  Future<Product?> getProductById(int id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<int> addProduct(ProductsCompanion product);
  Future<void> updateProduct(int id, ProductsCompanion product);
  Future<void> toggleProductActive(int id, bool isActive);

  // Categories
  Future<List<Category>> getAllCategories();
  Future<int> addCategory(CategoriesCompanion category);

  // Suppliers
  Future<List<Supplier>> getAllSuppliers();
  Future<int> addSupplier(SuppliersCompanion supplier);
  Future<void> updateSupplier(int id, SuppliersCompanion supplier);

  // Stock Adjustments
  Future<void> adjustStock({
    required int productId,
    required int userId,
    required double quantityChange,
    required String movementType,
    String? reasonCode,
    String? notes,
  });
  Future<List<StockMovement>> getStockMovementsForProduct(int productId);
}
