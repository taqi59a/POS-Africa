import '../../../../core/data/database/app_database.dart';

abstract class ReportRepository {
  Future<Map<String, double>> getDailySalesSummary(DateTime date);
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime start, DateTime end, int limit);
  Future<double> getInventoryTotalValuation();
  Future<Map<String, double>> getExpenseSummary(DateTime start, DateTime end);
}
