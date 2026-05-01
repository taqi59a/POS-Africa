import '../../../../core/data/database/app_database.dart';

abstract class ReturnsRepository {
  /// Generate a unique return number like RTN-20260501-0001
  Future<String> generateReturnNumber();

  /// Fetch the original sale detail for pre-filling return form
  Future<Map<String, dynamic>?> getSaleDetail(int saleId);

  /// Search sales by transaction number for return lookup
  Future<List<Map<String, dynamic>>> searchSalesForReturn(String query);

  /// Process a return: refund stock, create return record
  Future<int> processReturn({
    required SaleReturnsCompanion returnHeader,
    required List<ReturnLinesCompanion> lines,
  });

  /// Get all returns, newest first
  Future<List<Map<String, dynamic>>> getAllReturns();

  /// Get returns in a date range
  Future<List<Map<String, dynamic>>> getReturnsByDateRange(
      DateTime start, DateTime end);

  /// Get lines of a specific return
  Future<List<ReturnLine>> getReturnLines(int returnId);

  /// Void / cancel a return (re-removes stock)
  Future<void> voidReturn(int returnId, String reason);
}
