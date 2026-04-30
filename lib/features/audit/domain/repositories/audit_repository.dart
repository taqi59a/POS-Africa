import '../../../../core/data/database/app_database.dart';

abstract class AuditRepository {
  Future<List<AuditLog>> getAllLogs();
  Future<void> logEvent(AuditLogsCompanion log);
}
