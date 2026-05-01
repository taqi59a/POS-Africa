import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/returns_repository.dart';

class ReturnsRepositoryImpl implements ReturnsRepository {
  final AppDatabase _db;
  ReturnsRepositoryImpl(this._db);

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  // ── Number generation ───────────────────────────────────────────────────
  @override
  Future<String> generateReturnNumber() async {
    final now = DateTime.now();
    final prefix =
        'RTN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayReturns = await (_db.select(_db.saleReturns)
          ..where((t) => t.returnDate.isBetweenValues(todayStart, todayEnd)))
        .get();
    final seq = (todayReturns.length + 1).toString().padLeft(4, '0');
    return '$prefix-$seq';
  }

  // ── Sale lookup ─────────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>?> getSaleDetail(int saleId) async {
    final sale = await (_db.select(_db.sales)
          ..where((t) => t.id.equals(saleId)))
        .getSingleOrNull();
    if (sale == null) return null;

    final customer = sale.customerId == null
        ? null
        : await (_db.select(_db.customers)
                ..where((t) => t.id.equals(sale.customerId!)))
            .getSingleOrNull();

    final lines = await (_db.select(_db.saleLines)
          ..where((t) => t.saleId.equals(saleId)))
        .get();

    return {
      'id': sale.id,
      'transactionNumber': sale.transactionNumber,
      'saleDate': sale.saleDate,
      'status': sale.status,
      'subtotal': sale.subtotal,
      'discountAmount': sale.discountAmount,
      'vatAmount': sale.vatAmount,
      'grandTotal': sale.grandTotal,
      'grandTotalUsd': sale.grandTotalUsd,
      'exchangeRate': sale.exchangeRateUsed,
      'customerId': sale.customerId,
      'customerName': customer?.fullName,
      'lines': lines
          .map((l) => {
                'id': l.id,
                'productId': l.productId,
                'productName': l.productName,
                'quantity': l.quantity,
                'unitPrice': l.unitPrice,
                'lineTotal': l.lineTotal,
              })
          .toList(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> searchSalesForReturn(String query) async {
    final q = _db.select(_db.sales).join([
      leftOuterJoin(
          _db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ]);
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      q.where(_db.sales.transactionNumber.contains(trimmed) |
          _db.customers.fullName.contains(trimmed));
    }
    q.where(_db.sales.status.equals('COMPLETED'));
    q.orderBy([OrderingTerm.desc(_db.sales.saleDate)]);
    q.limit(50);

    final rows = await q.get();
    return rows.map((row) {
      final sale = row.readTable(_db.sales);
      final customer = row.readTableOrNull(_db.customers);
      return <String, dynamic>{
        'id': sale.id,
        'transactionNumber': sale.transactionNumber,
        'saleDate': sale.saleDate,
        'grandTotal': sale.grandTotal,
        'customerName': customer?.fullName ?? 'Walk-in',
      };
    }).toList();
  }

  // ── Process return ──────────────────────────────────────────────────────
  @override
  Future<int> processReturn({
    required SaleReturnsCompanion returnHeader,
    required List<ReturnLinesCompanion> lines,
  }) async {
    return _db.transaction(() async {
      // 1. Insert return header
      final returnId = await _db.into(_db.saleReturns).insert(returnHeader);

      // 2. Insert lines, restore stock, log movements
      for (final line in lines) {
        final lineWithId = line.copyWith(returnId: Value(returnId));
        await _db.into(_db.returnLines).insert(lineWithId);

        final productId = line.productId.value;
        final qty = line.quantity.value;

        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(productId)))
            .getSingle();
        final newStock = product.stockQuantity + qty;

        await (_db.update(_db.products)
              ..where((t) => t.id.equals(productId)))
            .write(ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                productId: productId,
                userId: returnHeader.processedByUserId,
                movementType: 'RETURN',
                quantityChange: qty,
                stockBefore: product.stockQuantity,
                stockAfter: newStock,
                notes: Value('Return #$returnId'),
              ),
            );
      }

      // 3. Mark original sale as REFUNDED if all lines are returned
      if (returnHeader.originalSaleId.present &&
          returnHeader.originalSaleId.value != null) {
        final origId = returnHeader.originalSaleId.value!;
        final origLines = await (_db.select(_db.saleLines)
              ..where((t) => t.saleId.equals(origId)))
            .get();
        final returnedLines = await (_db.select(_db.returnLines)
              ..where((t) => t.returnId.equals(returnId)))
            .get();

        // Check if total returned qty >= sold qty for all lines
        final origQty = origLines.fold<double>(0, (s, l) => s + l.quantity);
        final retQty = returnedLines.fold<double>(0, (s, l) => s + l.quantity);

        if (retQty >= origQty) {
          await (_db.update(_db.sales)
                ..where((t) => t.id.equals(origId)))
              .write(const SalesCompanion(status: Value('REFUNDED')));
        }
      }

      return returnId;
    });
  }

  // ── Queries ─────────────────────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> getAllReturns() async {
    final q = _db.select(_db.saleReturns).join([
      leftOuterJoin(
          _db.customers, _db.customers.id.equalsExp(_db.saleReturns.customerId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.saleReturns.returnDate)]);

    final rows = await q.get();
    return rows.map((row) {
      final r = row.readTable(_db.saleReturns);
      final c = row.readTableOrNull(_db.customers);
      return _mapReturn(r, c);
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getReturnsByDateRange(
      DateTime start, DateTime end) async {
    final q = _db.select(_db.saleReturns).join([
      leftOuterJoin(
          _db.customers, _db.customers.id.equalsExp(_db.saleReturns.customerId)),
    ])
      ..where(_db.saleReturns.returnDate.isBetweenValues(start, _endOfDay(end)))
      ..orderBy([OrderingTerm.desc(_db.saleReturns.returnDate)]);

    final rows = await q.get();
    return rows.map((row) {
      final r = row.readTable(_db.saleReturns);
      final c = row.readTableOrNull(_db.customers);
      return _mapReturn(r, c);
    }).toList();
  }

  Map<String, dynamic> _mapReturn(SaleReturn r, Customer? c) => {
        'id': r.id,
        'returnNumber': r.returnNumber,
        'originalSaleId': r.originalSaleId,
        'returnDate': r.returnDate,
        'status': r.status,
        'reason': r.reason,
        'totalRefundAmount': r.totalRefundAmount,
        'totalRefundAmountUsd': r.totalRefundAmountUsd,
        'exchangeRate': r.exchangeRateUsed,
        'refundMethod': r.refundMethod,
        'customerName': c?.fullName ?? 'Walk-in',
        'customerId': r.customerId,
      };

  @override
  Future<List<ReturnLine>> getReturnLines(int returnId) =>
      (_db.select(_db.returnLines)
            ..where((t) => t.returnId.equals(returnId)))
          .get();

  @override
  Future<void> voidReturn(int returnId, String reason) async {
    await _db.transaction(() async {
      await (_db.update(_db.saleReturns)
            ..where((t) => t.id.equals(returnId)))
          .write(const SaleReturnsCompanion(status: Value('VOIDED')));

      // Re-take stock (undo the restore)
      final lines = await getReturnLines(returnId);
      for (final line in lines) {
        final product = await (_db.select(_db.products)
              ..where((t) => t.id.equals(line.productId)))
            .getSingle();
        final newStock = (product.stockQuantity - line.quantity).clamp(0.0, double.infinity);
        await (_db.update(_db.products)
              ..where((t) => t.id.equals(line.productId)))
            .write(ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ));

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                productId: line.productId,
                movementType: 'ADJUST',
                quantityChange: -line.quantity,
                stockBefore: product.stockQuantity,
                stockAfter: newStock,
                notes: Value('Void Return #$returnId: $reason'),
              ),
            );
      }
    });
  }
}
