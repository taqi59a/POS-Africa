import 'package:drift/drift.dart';
import 'sale_returns.dart';
import 'products.dart';
import 'sale_lines.dart';

class ReturnLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnId => integer().references(SaleReturns, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()(); // FC price at time of return
  RealColumn get lineTotal => real()(); // FC
  // Optional link back to the original sale line
  IntColumn get originalSaleLineId => integer().nullable().references(SaleLines, #id)();
}
