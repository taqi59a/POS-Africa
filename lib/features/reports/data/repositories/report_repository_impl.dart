import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final AppDatabase _db;

  ReportRepositoryImpl(this._db);

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  @override
  Future<Map<String, double>> getDailySalesSummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final sales = await (_db.select(_db.sales)
          ..where((t) => t.saleDate.isBetweenValues(start, end) & t.status.equals('COMPLETED')))
        .get();

    return {
      'count': sales.length.toDouble(),
      'subtotal': sales.fold(0, (s, e) => s + e.subtotal),
      'discount': sales.fold(0, (s, e) => s + e.discountAmount),
      'tax': sales.fold(0, (s, e) => s + e.vatAmount),
      'total': sales.fold(0, (s, e) => s + e.grandTotal),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      DateTime start, DateTime end, int limit) async {
    final query = _db.select(_db.saleLines).join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleLines.saleId)),
    ])
      ..where(_db.sales.saleDate.isBetweenValues(start, _endOfDay(end)) &
          _db.sales.status.equals('COMPLETED'));

    final results = await query.get();
    final Map<int, Map<String, dynamic>> stats = {};

    for (final row in results) {
      final line = row.readTable(_db.saleLines);
      stats.putIfAbsent(line.productId, () => {
        'name': line.productName,
        'quantity': 0.0,
        'revenue': 0.0,
      });
      stats[line.productId]!['quantity'] += line.quantity;
      stats[line.productId]!['revenue'] += line.lineTotal;
    }

    final sorted = stats.values.toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    return sorted.take(limit).toList();
  }

  @override
  Future<double> getInventoryTotalValuation() async {
    final products = await _db.select(_db.products).get();
    return products.fold<double>(0.0, (sum, p) => sum + (p.stockQuantity * p.costPrice));
  }

  @override
  Future<Map<String, double>> getExpenseSummary(DateTime start, DateTime end) async {
    final expenses = await (_db.select(_db.expenses)
          ..where((t) => t.date.isBetweenValues(start, _endOfDay(end))))
        .get();
    return {'total': expenses.fold(0, (s, e) => s + e.amount)};
  }

  // ── Extended reports ───────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSalesReport(DateTime start, DateTime end) async {
    final query = _db.select(_db.sales).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ])
      ..where(_db.sales.saleDate.isBetweenValues(start, _endOfDay(end)))
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
  Future<List<Map<String, dynamic>>> getCustomerLedger() async {
    final customers = await _db.select(_db.customers).get();
    final results = <Map<String, dynamic>>[];

    for (final c in customers) {
      final sales = await (_db.select(_db.sales)
            ..where((t) => t.customerId.equals(c.id) & t.status.equals('COMPLETED')))
          .get();
      final totalSpent = sales.fold<double>(0, (s, sale) => s + sale.grandTotal);
      final lastSale = sales.isEmpty
          ? null
          : sales.map((s) => s.saleDate).reduce((a, b) => a.isAfter(b) ? a : b);
      results.add({
        'id': c.id,
        'fullName': c.fullName,
        'phone': c.phone ?? '',
        'balanceOwed': c.balanceOwed,
        'creditLimit': c.creditLimit,
        'totalPurchases': sales.length,
        'totalSpent': totalSpent,
        'lastPurchase': lastSale,
      });
    }
    results.sort((a, b) =>
        (b['balanceOwed'] as double).compareTo(a['balanceOwed'] as double));
    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerPurchases(
      int? customerId, DateTime start, DateTime end) async {
    final query = _db.select(_db.sales).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ]);

    if (customerId != null) {
      query.where(_db.sales.customerId.equals(customerId) &
          _db.sales.saleDate.isBetweenValues(start, _endOfDay(end)));
    } else {
      query.where(_db.sales.customerId.isNotNull() &
          _db.sales.saleDate.isBetweenValues(start, _endOfDay(end)));
    }
    query.orderBy([OrderingTerm.desc(_db.sales.saleDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final sale = row.readTable(_db.sales);
      final customer = row.readTableOrNull(_db.customers);
      return <String, dynamic>{
        'id': sale.id,
        'transactionNumber': sale.transactionNumber,
        'saleDate': sale.saleDate,
        'grandTotal': sale.grandTotal,
        'status': sale.status,
        'customerName': customer?.fullName ?? 'Unknown',
        'customerId': sale.customerId,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesDetailed(
      DateTime start, DateTime end) async {
    final query = _db.select(_db.expenses).join([
      leftOuterJoin(_db.expenseCategories,
          _db.expenseCategories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.date.isBetweenValues(start, _endOfDay(end)))
      ..orderBy([OrderingTerm.desc(_db.expenses.date)]);

    final rows = await query.get();
    return rows.map((row) {
      final expense = row.readTable(_db.expenses);
      final category = row.readTableOrNull(_db.expenseCategories);
      return <String, dynamic>{
        'id': expense.id,
        'date': expense.date,
        'description': expense.description,
        'amount': expense.amount,
        'category': category?.name ?? 'Uncategorized',
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getInventoryReport() async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.products.categoryId)),
    ])
      ..where(_db.products.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(_db.products.name)]);

    final rows = await query.get();
    return rows.map((row) {
      final p = row.readTable(_db.products);
      final cat = row.readTableOrNull(_db.categories);
      return <String, dynamic>{
        'id': p.id,
        'name': p.name,
        'sku': p.sku ?? '',
        'category': cat?.name ?? 'Uncategorized',
        'stockQuantity': p.stockQuantity,
        'costPrice': p.costPrice,
        'sellingPrice': p.sellingPrice,
        'totalValue': p.stockQuantity * p.costPrice,
        'isLowStock': p.stockQuantity <= p.minimumStockLevel,
      };
    }).toList();
  }

  // ── Product Sales History ─────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getProductSalesHistory(
      int? productId, DateTime start, DateTime end) async {
    final query = _db.select(_db.saleLines).join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleLines.saleId)),
      leftOuterJoin(_db.products, _db.products.id.equalsExp(_db.saleLines.productId)),
    ])
      ..where(_db.sales.saleDate.isBetweenValues(start, _endOfDay(end)) &
          _db.sales.status.equals('COMPLETED'));

    if (productId != null) {
      query.where(_db.saleLines.productId.equals(productId));
    }
    query.orderBy([OrderingTerm.desc(_db.sales.saleDate)]);

    final rows = await query.get();
    final Map<int, Map<String, dynamic>> stats = {};

    for (final row in rows) {
      final line = row.readTable(_db.saleLines);
      final sale = row.readTable(_db.sales);
      final product = row.readTableOrNull(_db.products);

      stats.putIfAbsent(line.productId, () => {
        'productId': line.productId,
        'name': line.productName,
        'stockQuantity': product?.stockQuantity ?? 0.0,
        'costPrice': product?.costPrice ?? 0.0,
        'sellingPrice': product?.sellingPrice ?? 0.0,
        'totalQtySold': 0.0,
        'totalRevenue': 0.0,
        'timesTransacted': 0,
        'firstSale': sale.saleDate,
        'lastSale': sale.saleDate,
        'transactions': <Map<String, dynamic>>[],
      });

      final entry = stats[line.productId]!;
      entry['totalQtySold'] = (entry['totalQtySold'] as double) + line.quantity;
      entry['totalRevenue'] = (entry['totalRevenue'] as double) + line.lineTotal;
      entry['timesTransacted'] = (entry['timesTransacted'] as int) + 1;
      if (sale.saleDate.isBefore(entry['firstSale'] as DateTime)) {
        entry['firstSale'] = sale.saleDate;
      }
      if (sale.saleDate.isAfter(entry['lastSale'] as DateTime)) {
        entry['lastSale'] = sale.saleDate;
      }
      (entry['transactions'] as List<Map<String, dynamic>>).add({
        'saleId': sale.id,
        'transactionNumber': sale.transactionNumber,
        'date': sale.saleDate,
        'quantity': line.quantity,
        'unitPrice': line.unitPrice,
        'lineTotal': line.lineTotal,
      });
    }

    // Also include stock loading history from stock_movements
    for (final productIdKey in stats.keys) {
      final movements = await (_db.select(_db.stockMovements)
            ..where((t) =>
                t.productId.equals(productIdKey) &
                t.movementType.isIn(['RECEIVE', 'ADJUST']) &
                t.timestamp.isBetweenValues(start, _endOfDay(end)))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();
      stats[productIdKey]!['stockLoads'] =
          movements.map((m) => {
                'date': m.timestamp,
                'type': m.movementType,
                'qty': m.quantityChange,
                'stockAfter': m.stockAfter,
                'notes': m.notes ?? '',
              }).toList();
    }

    final sorted = stats.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));
    return sorted;
  }

  // ── Receipt Search & Reprint ──────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> findReceiptsForReprint(
      String query, DateTime? start, DateTime? end) async {
    final q = _db.select(_db.sales).join([
      leftOuterJoin(_db.customers, _db.customers.id.equalsExp(_db.sales.customerId)),
    ]);

    if (start != null && end != null) {
      q.where(_db.sales.saleDate.isBetweenValues(start, _endOfDay(end)));
    }

    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      q.where(_db.sales.transactionNumber.contains(trimmed) |
          _db.customers.fullName.contains(trimmed));
    }

    q.orderBy([OrderingTerm.desc(_db.sales.saleDate)]);
    q.limit(100);

    final rows = await q.get();
    return rows.map((row) {
      final sale = row.readTable(_db.sales);
      final customer = row.readTableOrNull(_db.customers);
      return <String, dynamic>{
        'id': sale.id,
        'transactionNumber': sale.transactionNumber,
        'saleDate': sale.saleDate,
        'grandTotal': sale.grandTotal,
        'vatAmount': sale.vatAmount,
        'status': sale.status,
        'customerName': customer?.fullName ?? 'Walk-in',
        'customerId': sale.customerId,
      };
    }).toList();
  }

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

    final payment = await (_db.select(_db.payments)
          ..where((t) => t.saleId.equals(saleId))
          ..limit(1))
        .getSingleOrNull();

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
      'customerName': customer?.fullName,
      'lines': lines.map((l) => {
        'productName': l.productName,
        'quantity': l.quantity,
        'unitPrice': l.unitPrice,
        'lineTotal': l.lineTotal,
        'vatAmount': l.vatAmount,
      }).toList(),
      'paymentMethod': payment?.method ?? 'CASH',
      'amountTendered': payment?.amountTendered ?? sale.grandTotal,
      'changeDue': payment?.changeDue ?? 0.0,
    };
  }
}

