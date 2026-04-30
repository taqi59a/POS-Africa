import 'package:drift/drift.dart';
import 'categories.dart';
import 'suppliers.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  TextColumn get sku => text().nullable().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get unitOfMeasure => text().withDefault(const Constant('piece'))();
  RealColumn get costPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0.0))();
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  RealColumn get minimumStockLevel => real().withDefault(const Constant(5.0))();
  BlobColumn get imageData => blob().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
