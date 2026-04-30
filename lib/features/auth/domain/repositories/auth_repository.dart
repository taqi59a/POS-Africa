import '../../../../core/data/database/app_database.dart';

abstract class AuthRepository {
  Future<User?> login(String username, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<void> changePassword(int userId, String newPassword);
  Future<void> logAudit(int? userId, String username, String actionType, {String? affectedRecordId, String? oldValue, String? newValue});
}
