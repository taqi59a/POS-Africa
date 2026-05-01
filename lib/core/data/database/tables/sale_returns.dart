import 'package:drift/drift.dart';
import 'users.dart';
import 'customers.dart';
import 'sales.dart';

class SaleReturns extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Reference to original sale (nullable: some walk-in returns may not have original TXN)
  IntColumn get originalSaleId => integer().nullable().references(Sales, #id)();
  TextColumn get returnNumber => text().unique()();
  IntColumn get processedByUserId => integer().nullable().references(Users, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  // Status: COMPLETED, VOIDED
  TextColumn get status => text().withDefault(const Constant('COMPLETED'))();
  TextColumn get reason => text().withDefault(const Constant('Customer return'))();
  RealColumn get totalRefundAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalRefundAmountUsd => real().withDefault(const Constant(0.0))();
  RealColumn get exchangeRateUsed => real().withDefault(const Constant(0.0))();
  // CASH / CREDIT / STORE_CREDIT
  TextColumn get refundMethod => text().withDefault(const Constant('CASH'))();
  DateTimeColumn get returnDate => dateTime().withDefault(currentDateAndTime)();
}
