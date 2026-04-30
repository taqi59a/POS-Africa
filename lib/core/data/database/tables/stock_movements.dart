import 'package:drift/drift.dart';
import 'products.dart';
import 'users.dart';

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get movementType => text()(); // SALE, RECEIVE, ADJUST, RETURN
  TextColumn get reasonCode => text().nullable()(); // DAMAGE, THEFT, CORRECTION, OPENING_COUNT
  RealColumn get quantityChange => real()();
  RealColumn get stockBefore => real()();
  RealColumn get stockAfter => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
