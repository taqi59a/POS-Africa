import 'package:drift/drift.dart';
import 'users.dart';
import 'customers.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionNumber => text().unique()();
  IntColumn get cashierId => integer().nullable().references(Users, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  // Status: COMPLETED, HELD, VOIDED, REFUNDED
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotalUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(0.0))();
  TextColumn get voidReason => text().nullable()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
}
