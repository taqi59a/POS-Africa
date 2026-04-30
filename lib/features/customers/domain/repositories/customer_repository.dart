import '../../../../core/data/database/app_database.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getAllCustomers();
  Future<List<Customer>> searchCustomers(String query);
  Future<Customer?> getCustomerById(int id);
  Future<int> addCustomer(CustomersCompanion customer);
  Future<void> updateCustomer(int id, CustomersCompanion customer);
  Future<void> deleteCustomer(int id);
}
