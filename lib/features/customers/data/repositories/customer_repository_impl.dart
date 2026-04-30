import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final AppDatabase _db;

  CustomerRepositoryImpl(this._db);

  @override
  Future<List<Customer>> getAllCustomers() =>
    (_db.select(_db.customers)..orderBy([(t) => OrderingTerm.asc(t.fullName)])).get();

  @override
  Future<List<Customer>> searchCustomers(String query) =>
    (_db.select(_db.customers)
      ..where((t) => t.fullName.contains(query) | t.phone.contains(query) | t.email.contains(query))
      ..orderBy([(t) => OrderingTerm.asc(t.fullName)]))
    .get();

  @override
  Future<Customer?> getCustomerById(int id) =>
    (_db.select(_db.customers)..where((t) => t.id.equals(id))).getSingleOrNull();

  @override
  Future<int> addCustomer(CustomersCompanion customer) =>
    _db.into(_db.customers).insert(customer);

  @override
  Future<void> updateCustomer(int id, CustomersCompanion customer) =>
    (_db.update(_db.customers)..where((t) => t.id.equals(id))).write(customer);

  @override
  Future<void> deleteCustomer(int id) =>
    (_db.delete(_db.customers)..where((t) => t.id.equals(id))).go();
}
