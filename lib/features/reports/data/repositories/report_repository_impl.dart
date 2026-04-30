import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final AppDatabase _db;

  ReportRepositoryImpl(this._db);

  @override
  Future<Map<String, double>> getDailySalesSummary(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final query = _db.select(_db.sales)
      ..where((t) => t.saleDate.isBetweenValues(start, end) & t.status.equals('COMPLETED'));
    
    final sales = await query.get();
    
    double totalSubtotal = 0;
    double totalDiscount = 0;
    double totalTax = 0;
    double totalGrandTotal = 0;

    for (final sale in sales) {
      totalSubtotal += sale.subtotal;
      totalDiscount += sale.discountAmount;
      totalTax += sale.vatAmount;
      totalGrandTotal += sale.grandTotal;
    }

    return {
      'count': sales.length.toDouble(),
      'subtotal': totalSubtotal,
      'discount': totalDiscount,
      'tax': totalTax,
      'total': totalGrandTotal,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end, int limit) async {
    // This is a more complex query involving joins
    final query = _db.select(_db.saleLines).join([
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleLines.saleId)),
    ])
    ..where(_db.sales.saleDate.isBetweenValues(start, end) & _db.sales.status.equals('COMPLETED'));

    final results = await query.get();
    final Map<int, Map<String, dynamic>> productStats = {};

    for (final row in results) {
      final line = row.readTable(_db.saleLines);
      if (!productStats.containsKey(line.productId)) {
        productStats[line.productId] = {
          'name': line.productName,
          'quantity': 0.0,
          'revenue': 0.0,
        };
      }
      productStats[line.productId]!['quantity'] += line.quantity;
      productStats[line.productId]!['revenue'] += line.lineTotal;
    }

    final sortedList = productStats.values.toList()
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));

    return sortedList.take(limit).toList();
  }

  @override
  Future<double> getInventoryTotalValuation() async {
    final products = await _db.select(_db.products).get();
    return products.fold<double>(0.0, (sum, p) => sum + (p.stockQuantity * p.costPrice));
  }

  @override
  Future<Map<String, double>> getExpenseSummary(DateTime start, DateTime end) async {
    final query = _db.select(_db.expenses)
      ..where((t) => t.date.isBetweenValues(start, end));
    
    final expenses = await query.get();
    return {
      'total': expenses.fold(0, (sum, e) => sum + e.amount),
    };
  }
}
