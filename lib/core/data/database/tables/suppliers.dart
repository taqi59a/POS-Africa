import 'package:drift/drift.dart';

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get contact => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get paymentTerms => text().nullable()();
  RealColumn get balanceOwed => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
