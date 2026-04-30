import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables/roles.dart';
import 'tables/permissions.dart';
import 'tables/users.dart';
import 'tables/settings.dart';
import 'tables/audit_log.dart';
import 'tables/categories.dart';
import 'tables/suppliers.dart';
import 'tables/products.dart';
import 'tables/stock_movements.dart';
import 'tables/customers.dart';
import 'tables/sales.dart';
import 'tables/sale_lines.dart';
import 'tables/payments.dart';
import 'tables/expenses.dart';
import 'tables/exchange_rate_history.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Roles,
  Permissions,
  Users,
  Settings,
  AuditLogs,
  Categories,
  Suppliers,
  Products,
  StockMovements,
  Customers,
  Sales,
  SaleLines,
  Payments,
  ExpenseCategories,
  Expenses,
  ExchangeRateHistory,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaults();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(categories);
          await m.createTable(suppliers);
          await m.createTable(products);
          await m.createTable(stockMovements);
        }
        if (from < 3) {
          await m.createTable(customers);
          await m.createTable(sales);
          await m.createTable(saleLines);
          await m.createTable(payments);
          await m.createTable(expenseCategories);
          await m.createTable(expenses);
          await m.createTable(exchangeRateHistory);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode=WAL;');
        // Integrity check on startup
        final result = await customSelect('PRAGMA integrity_check;').get();
        final status = result.first.read<String>('integrity_check');
        if (status != 'ok') {
          throw Exception('Database integrity check failed: $status');
        }
      },
    );
  }

  /// Seeds the database with default roles, admin user, and settings on first run.
  Future<void> _seedDefaults() async {
    final adminRoleId = await into(roles).insert(RolesCompanion.insert(
        name: 'Admin', description: const Value('Full access to everything')));
    final managerRoleId = await into(roles).insert(RolesCompanion.insert(
        name: 'Manager', description: const Value('Reports, inventory, discounts, refunds')));
    final cashierRoleId = await into(roles).insert(RolesCompanion.insert(
        name: 'Cashier', description: const Value('POS screen and customer lookup only')));
    await into(roles).insert(RolesCompanion.insert(
        name: 'Stock Clerk', description: const Value('Inventory receive/adjust only')));

    // Admin gets all permissions
    await into(permissions).insert(PermissionsCompanion.insert(
      roleId: adminRoleId,
      canApplyDiscount: const Value(true),
      canProcessRefund: const Value(true),
      canVoidSale: const Value(true),
      canViewCostPrice: const Value(true),
      canExportReports: const Value(true),
      canDeleteRecords: const Value(true),
      canManageUsers: const Value(true),
      canChangeSettings: const Value(true),
    ));
    // Manager permissions
    await into(permissions).insert(PermissionsCompanion.insert(
      roleId: managerRoleId,
      canApplyDiscount: const Value(true),
      canProcessRefund: const Value(true),
      canVoidSale: const Value(true),
      canViewCostPrice: const Value(true),
      canExportReports: const Value(true),
    ));
    // Cashier permissions
    await into(permissions).insert(PermissionsCompanion.insert(roleId: cashierRoleId));

    // Default admin user — password 'master' (bcrypt hash)
    await into(users).insert(UsersCompanion.insert(
      username: 'admin',
      passwordHash: r'$2b$10$3yWGIrTZKb4Gf5H6c7I8yOkF.OLqPbY7FXNz.L3LjEEiBjYkQU4sa',
      roleId: adminRoleId,
      requirePasswordChange: const Value(true),
    ));

    // Default app settings
    final defaults = {
      'business_name': 'My Business',
      'business_address': '',
      'business_phone': '',
      'business_email': '',
      'business_vat_number': '',
      'dual_currency_enabled': 'false',
      'usd_exchange_rate': '2850',
      'vat_enabled': 'false',
      'vat_percentage': '16',
      'vat_mode': 'inclusive',
      'language': 'fr',
      'low_stock_threshold': '5',
      'receipt_footer': 'Merci pour votre achat!',
      'paper_width': '80',
      'date_format': 'DD/MM/YYYY',
      'time_format': '24h',
      'idle_timeout_minutes': '10',
      'next_invoice_number': '1000',
      'business_logo_path': '',
    };
    for (final entry in defaults.entries) {
      await into(settings).insert(
          SettingsCompanion.insert(key: entry.key, value: Value(entry.value)));
    }

    // Default categories
    await into(categories).insert(CategoriesCompanion.insert(name: 'General'));

    // Default expense categories
    for (final cat in ['Loyer', 'Salaires', 'Utilitaires', 'Transport', 'Divers']) {
      await into(expenseCategories).insert(ExpenseCategoriesCompanion.insert(name: cat));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'CongoPOS', 'db.sqlite'));
    await file.parent.create(recursive: true);

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
