import 'package:drift/drift.dart';
import 'sales.dart';
import 'products.dart';

class SaleLines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot at time of sale
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()(); // CDF
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real()(); // CDF after discount
  RealColumn get vatAmount => real().withDefault(const Constant(0.0))();
}
