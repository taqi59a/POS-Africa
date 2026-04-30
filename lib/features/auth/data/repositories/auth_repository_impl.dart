import 'dart:io';
import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../../../core/utils/password_utils.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AppDatabase _db;
  User? _currentUser;

  AuthRepositoryImpl(this._db);

  @override
  Future<User?> login(String username, String password) async {
    final user = await (_db.select(_db.users)
          ..where((t) => t.username.equals(username)))
        .getSingleOrNull();

    if (user != null) {
      if (!user.isActive) throw Exception('User account is inactive.');
      if (user.failedLoginAttempts >= 5) {
        throw Exception('Account locked due to too many failed attempts.');
      }
      if (PasswordUtils.verifyPassword(password, user.passwordHash)) {
        await (_db.update(_db.users)..where((t) => t.id.equals(user.id))).write(
          UsersCompanion(
            failedLoginAttempts: const Value(0),
            lastLoginAt:         Value(DateTime.now()),
          ),
        );
        _currentUser = user;
        await logAudit(user.id, user.username, 'LOGIN');
        return user;
      } else {
        await (_db.update(_db.users)..where((t) => t.id.equals(user.id))).write(
          UsersCompanion(failedLoginAttempts: Value(user.failedLoginAttempts + 1)),
        );
        await logAudit(user.id, user.username, 'FAILED_LOGIN');
        throw Exception('Invalid username or password.');
      }
    }
    throw Exception('Invalid username or password.');
  }

  @override
  Future<void> logout() async {
    if (_currentUser != null) {
      await logAudit(_currentUser!.id, _currentUser!.username, 'LOGOUT');
      _currentUser = null;
    }
  }

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<void> changePassword(int userId, String newPassword) async {
    final hash = PasswordUtils.hashPassword(newPassword);
    await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordHash:          Value(hash),
        requirePasswordChange: const Value(false),
      ),
    );
    await logAudit(userId, _currentUser?.username ?? 'System', 'PASSWORD_CHANGE');
  }

  @override
  Future<void> logAudit(int? userId, String username, String actionType,
      {String? affectedRecordId, String? oldValue, String? newValue}) async {
    await _db.into(_db.auditLogs).insert(
      AuditLogsCompanion.insert(
        userId:           Value(userId),
        username:         Value(username),
        actionType:       actionType,
        affectedRecordId: Value(affectedRecordId),
        workstationName:  Value(Platform.localHostname),
        oldValue:         Value(oldValue),
        newValue:         Value(newValue),
      ),
    );
  }

  // ── User management ───────────────────────────────────────────────────────

  @override
  Future<List<User>> getAllUsers() => _db.select(_db.users).get();

  @override
  Future<List<Role>> getAllRoles() => _db.select(_db.roles).get();

  @override
  Future<void> createUser(String username, String password, int roleId,
      {bool requirePasswordChange = false}) async {
    final hash = PasswordUtils.hashPassword(password);
    await _db.into(_db.users).insert(UsersCompanion.insert(
      username:              username,
      passwordHash:          hash,
      roleId:                roleId,
      requirePasswordChange: Value(requirePasswordChange),
    ));
    await logAudit(_currentUser?.id, _currentUser?.username ?? 'System',
        'CREATE_USER', newValue: username);
  }

  @override
  Future<void> updateUser(int userId, UsersCompanion companion) async {
    await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(companion);
    await logAudit(_currentUser?.id, _currentUser?.username ?? 'System', 'UPDATE_USER',
        affectedRecordId: userId.toString());
  }

  @override
  Future<void> deleteUser(int userId) async {
    final user = await (_db.select(_db.users)
          ..where((t) => t.id.equals(userId)))
        .getSingleOrNull();
    await (_db.delete(_db.users)..where((t) => t.id.equals(userId))).go();
    await logAudit(_currentUser?.id, _currentUser?.username ?? 'System',
        'DELETE_USER',
        affectedRecordId: userId.toString(),
        oldValue: user?.username);
  }
}

