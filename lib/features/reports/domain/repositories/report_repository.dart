import '../../../../core/data/database/app_database.dart';

abstract class ReportRepository {
  Future<Map<String, double>> getDailySalesSummary(DateTime date);
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end, int limit);
  Future<double> getInventoryTotalValuation();
  Future<Map<String, double>> getExpenseSummary(DateTime start, DateTime end);
  // Extended reports
  Future<List<Map<String, dynamic>>> getSalesReport(DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getCustomerLedger();
  Future<List<Map<String, dynamic>>> getCustomerPurchases(int? customerId, DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getExpensesDetailed(DateTime start, DateTime end);
  Future<List<Map<String, dynamic>>> getInventoryReport();
  // Product sales history
  Future<List<Map<String, dynamic>>> getProductSalesHistory(int? productId, DateTime start, DateTime end);
  // Receipt search & reprint
  Future<List<Map<String, dynamic>>> findReceiptsForReprint(String query, DateTime? start, DateTime? end);
  Future<Map<String, dynamic>?> getSaleDetail(int saleId);
}
