import 'package:get_it/get_it.dart';
import '../data/database/app_database.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../features/billing/domain/repositories/sales_repository.dart';
import '../../features/billing/data/repositories/sales_repository_impl.dart';
import '../../features/billing/presentation/bloc/sales_bloc.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/presentation/bloc/customer_bloc.dart';
import '../../features/reports/domain/repositories/report_repository.dart';
import '../../features/reports/data/repositories/report_repository_impl.dart';
import '../../features/reports/presentation/bloc/report_bloc.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../features/audit/domain/repositories/audit_repository.dart';
import '../../features/audit/data/repositories/audit_repository_impl.dart';
import '../../features/audit/presentation/bloc/audit_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Database — single instance shared across all repos
  final database = AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => database);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(sl()));
  sl.registerLazySingleton<InventoryRepository>(() => InventoryRepositoryImpl(sl()));
  sl.registerLazySingleton<SalesRepository>(() => SalesRepositoryImpl(sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(sl()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepositoryImpl(sl()));
  sl.registerLazySingleton<AuditRepository>(() => AuditRepositoryImpl(sl()));

  // Blocs (factory so each page gets a fresh instance)
  sl.registerFactory(() => AuthBloc(sl()));
  sl.registerFactory(() => SettingsBloc(sl()));
  sl.registerFactory(() => InventoryBloc(sl()));
  sl.registerFactory(() => SalesBloc(sl()));
  sl.registerFactory(() => CustomerBloc(sl()));
  sl.registerFactory(() => ReportBloc(sl()));
  sl.registerFactory(() => ExpenseBloc(sl()));
  sl.registerFactory(() => AuditBloc(sl()));
}
