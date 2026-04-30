import 'package:drift/drift.dart';
import 'sales.dart';

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  // Method: CASH, MOBILE_MONEY, CREDIT, SPLIT
  TextColumn get method => text()();
  RealColumn get amountPaid => real()(); // CDF
  RealColumn get amountTendered => real().withDefault(const Constant(0.0))(); // for cash
  RealColumn get changeDue => real().withDefault(const Constant(0.0))();
  TextColumn get reference => text().nullable()(); // mobile money ref
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
}
