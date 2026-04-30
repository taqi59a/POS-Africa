import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AppDatabase _db;

  AuditRepositoryImpl(this._db);

  @override
  Future<List<AuditLog>> getAllLogs() =>
    (_db.select(_db.auditLogs)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();

  @override
  Future<void> logEvent(AuditLogsCompanion log) =>
    _db.into(_db.auditLogs).insert(log);
}
