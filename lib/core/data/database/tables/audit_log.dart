import 'package:drift/drift.dart';
import 'users.dart';

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get username => text().nullable()();
  TextColumn get actionType => text()(); // LOGIN, SALE_COMPLETE, REFUND, VOID, STOCK_ADJUST, SETTINGS_CHANGE
  TextColumn get affectedRecordId => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get workstationName => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
}
