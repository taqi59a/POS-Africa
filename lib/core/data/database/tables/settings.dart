import 'package:drift/drift.dart';

class Settings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 100)();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
