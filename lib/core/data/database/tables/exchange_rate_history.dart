import 'package:drift/drift.dart';
import 'users.dart';

class ExchangeRateHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get usdToCdf => real()();
  IntColumn get changedByUserId => integer().nullable().references(Users, #id)();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
}
