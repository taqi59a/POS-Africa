import 'package:drift/drift.dart';
import 'users.dart';

class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get categoryId => integer().nullable().references(ExpenseCategories, #id)();
  IntColumn get paidByUserId => integer().nullable().references(Users, #id)();
  TextColumn get description => text()();
  RealColumn get amount => real()(); // CDF
  TextColumn get receiptReference => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
