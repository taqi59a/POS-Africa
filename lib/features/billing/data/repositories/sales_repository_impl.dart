import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  final AppDatabase _db;

  SalesRepositoryImpl(this._db);

  @override
  Future<String> generateTransactionNumber() async {
    final now = DateTime.now();
    final prefix = 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    // Count sales today to get a sequence
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final countQuery = _db.select(_db.sales)
      ..where((t) => t.saleDate.isBetweenValues(todayStart, todayEnd));
    
    final count = (await countQuery.get()).length + 1;
    return '$prefix-${count.toString().padLeft(4, '0')}';
  }

  @override
  Future<int> createSale(
    SalesCompanion sale,
    List<SaleLinesCompanion> lines,
    List<PaymentsCompanion> payments,
  ) async {
    return _db.transaction(() async {
      // 1. Insert the Sale
      final saleId = await _db.into(_db.sales).insert(sale);

      // 2. Insert Sale Lines and Update Stock
      for (final line in lines) {
        final lineWithId = line.copyWith(saleId: Value(saleId));
        await _db.into(_db.saleLines).insert(lineWithId);

        // Update Stock
        final productId = line.productId.value;
        final qtySold = line.quantity.value;
        
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(productId))).getSingle();
        final newStock = product.stockQuantity - qtySold;
        
        await (_db.update(_db.products)..where((t) => t.id.equals(productId))).write(
          ProductsCompanion(stockQuantity: Value(newStock), updatedAt: Value(DateTime.now()))
        );

        // Log Stock Movement
        await _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: productId,
            userId: Value(sale.cashierId.value),
            movementType: 'SALE',
            quantityChange: -qtySold,
            stockBefore: product.stockQuantity,
            stockAfter: newStock,
            notes: Value('Sale #$saleId'),
          ),
        );
      }

      // 3. Insert Payments
      for (final payment in payments) {
        await _db.into(_db.payments).insert(payment.copyWith(saleId: Value(saleId)));
      }

      return saleId;
    });
  }

  @override
  Future<List<Sale>> getAllSales() => 
    (_db.select(_db.sales)..orderBy([(t) => OrderingTerm.desc(t.saleDate)])).get();

  @override
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) =>
    (_db.select(_db.sales)
      ..where((t) => t.saleDate.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
    .get();

  @override
  Future<List<SaleLine>> getSaleLines(int saleId) =>
    (_db.select(_db.saleLines)..where((t) => t.saleId.equals(saleId))).get();

  @override
  Future<List<Payment>> getPayments(int saleId) =>
    (_db.select(_db.payments)..where((t) => t.saleId.equals(saleId))).get();

  @override
  Future<void> voidSale(int saleId, String reason) async {
    await _db.transaction(() async {
      // 1. Update Sale status
      await (_db.update(_db.sales)..where((t) => t.id.equals(saleId))).write(
        SalesCompanion(
          status: const Value('VOIDED'),
          voidReason: Value(reason),
        ),
      );

      // 2. Return Stock
      final lines = await getSaleLines(saleId);
      for (final line in lines) {
        final product = await (_db.select(_db.products)..where((t) => t.id.equals(line.productId))).getSingle();
        final newStock = product.stockQuantity + line.quantity;
        
        await (_db.update(_db.products)..where((t) => t.id.equals(line.productId))).write(
          ProductsCompanion(stockQuantity: Value(newStock), updatedAt: Value(DateTime.now()))
        );

        // Log Stock Movement
        await _db.into(_db.stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: line.productId,
            movementType: 'RETURN',
            quantityChange: line.quantity,
            stockBefore: product.stockQuantity,
            stockAfter: newStock,
            notes: Value('Voided Sale #$saleId'),
          ),
        );
      }
    });
  }
}
