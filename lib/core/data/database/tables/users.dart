import 'package:drift/drift.dart';
import 'roles.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  IntColumn get roleId => integer().references(Roles, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get requirePasswordChange => boolean().withDefault(const Constant(true))();
  IntColumn get failedLoginAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
