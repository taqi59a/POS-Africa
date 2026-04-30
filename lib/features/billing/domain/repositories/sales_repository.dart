import '../../../../core/data/database/app_database.dart';

abstract class SalesRepository {
  Future<String> generateTransactionNumber();
  Future<int> createSale(SalesCompanion sale, List<SaleLinesCompanion> lines, List<PaymentsCompanion> payments);
  Future<List<Sale>> getAllSales();
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end);
  Future<Sale?> getSaleByTransactionNumber(String txnNumber);
  Future<List<SaleLine>> getSaleLines(int saleId);
  Future<List<Payment>> getPayments(int saleId);
  Future<void> voidSale(int saleId, String reason);
  Future<List<Map<String, dynamic>>> getSalesReport(DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getCustomerSales(int customerId, DateTime start, DateTime end);
}
