import 'package:drift/drift.dart';
import 'roles.dart';

class Permissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roleId => integer().references(Roles, #id)();
  BoolColumn get canApplyDiscount => boolean().withDefault(const Constant(false))();
  BoolColumn get canProcessRefund => boolean().withDefault(const Constant(false))();
  BoolColumn get canVoidSale => boolean().withDefault(const Constant(false))();
  BoolColumn get canViewCostPrice => boolean().withDefault(const Constant(false))();
  BoolColumn get canExportReports => boolean().withDefault(const Constant(false))();
  BoolColumn get canDeleteRecords => boolean().withDefault(const Constant(false))();
  BoolColumn get canManageUsers => boolean().withDefault(const Constant(false))();
  BoolColumn get canChangeSettings => boolean().withDefault(const Constant(false))();
}
