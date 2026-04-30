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
      double totalCredit = 0;
      for (final payment in payments) {
        await _db.into(_db.payments).insert(payment.copyWith(saleId: Value(saleId)));
        if ((payment.method.value) == 'CREDIT') {
          totalCredit += payment.amountPaid.value;
        }
      }

      // 4. Update customer balance for credit purchases
      final customerId = sale.customerId.value;
      if (customerId != null && totalCredit > 0) {
        final customer = await (_db.select(_db.customers)
              ..where((t) => t.id.equals(customerId)))
            .getSingleOrNull();
        if (customer != null) {
          await (_db.update(_db.customers)..where((t) => t.id.equals(customerId))).write(
            CustomersCompanion(balanceOwed: Value(customer.balanceOwed + totalCredit)),
          );
        }
      }

      return saleId;
    });
  }

  @override
  Future<List<Sale>> getAllSales() => 
    (_db.select(_db.sales)..orderBy([(t) => OrderingTerm.desc(t.saleDate)])).get();

  @override
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) {
    final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return (_db.select(_db.sales)
      ..where((t) => t.saleDate.isBetweenValues(start, endInclusive))
      ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
    .get();
  }

  @override
  Future<Sale?> getSaleByTransactionNumber(String txnNumber) =>
    (_db.select(_db.sales)..where((t) => t.transactionNumber.equals(txnNumber)))
        .getSingleOrNull();

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

      // 3. Reverse customer credit balance if applicable
      final sale = await (_db.select(_db.sales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
      if (sale?.customerId != null) {
        final payments = await getPayments(saleId);
        double totalCredit = payments
            .where((p) => p.method == 'CREDIT')
            .fold(0.0, (s, p) => s + p.amountPaid);
        if (totalCredit > 0) {
          final customer = await (_db.select(_db.customers)
                ..where((t) => t.id.equals(sale!.customerId!)))
              .getSingleOrNull();
          if (customer != null) {
            await (_db.update(_db.customers)..where((t) => t.id.equals(customer.id))).write(
              CustomersCompanion(
                balanceOwed: Value((customer.balanceOwed - totalCredit).clamp(0, double.infinity)),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSalesReport(DateTime start, DateTime end) async {
    final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final query = _db.select(_db.sales).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ])
      ..where(_db.sales.saleDate.isBetweenValues(start, endInclusive))
      ..orderBy([OrderingTerm.desc(_db.sales.saleDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final sale = row.readTable(_db.sales);
      final customer = row.readTableOrNull(_db.customers);
      return <String, dynamic>{
        'id': sale.id,
        'transactionNumber': sale.transactionNumber,
        'saleDate': sale.saleDate,
        'grandTotal': sale.grandTotal,
        'vatAmount': sale.vatAmount,
        'discount': sale.discountAmount,
        'status': sale.status,
        'customerName': customer?.fullName ?? 'Walk-in',
        'customerId': sale.customerId,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerSales(
      int customerId, DateTime start, DateTime end) async {
    final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final sales = await (_db.select(_db.sales)
          ..where((t) =>
              t.customerId.equals(customerId) &
              t.saleDate.isBetweenValues(start, endInclusive))
          ..orderBy([(t) => OrderingTerm.desc(t.saleDate)]))
        .get();

    final result = <Map<String, dynamic>>[];
    for (final sale in sales) {
      final payments = await getPayments(sale.id);
      result.add({
        'id': sale.id,
        'transactionNumber': sale.transactionNumber,
        'saleDate': sale.saleDate,
        'grandTotal': sale.grandTotal,
        'status': sale.status,
        'paymentMethod': payments.isNotEmpty ? payments.first.method : 'N/A',
      });
    }
    return result;
  }
}
