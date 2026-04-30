import 'package:drift/drift.dart' hide Column;
import '../../../../core/data/database/app_database.dart';

abstract class AuthRepository {
  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<User?> login(String username, String password);
  Future<void>  logout();
  Future<User?> getCurrentUser();
  Future<void>  changePassword(int userId, String newPassword);
  Future<void>  logAudit(int? userId, String username, String actionType,
      {String? affectedRecordId, String? oldValue, String? newValue});

  // ── User management ───────────────────────────────────────────────────────
  Future<List<User>> getAllUsers();
  Future<List<Role>>   getAllRoles();
  Future<void> createUser(String username, String password, int roleId,
      {bool requirePasswordChange = false});
  Future<void> updateUser(int userId, UsersCompanion companion);
  Future<void> deleteUser(int userId);
}
