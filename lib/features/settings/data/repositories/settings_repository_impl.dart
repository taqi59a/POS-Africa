import 'package:drift/drift.dart';
import '../../../../core/data/database/app_database.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<Map<String, String>> getAllSettings() async {
    final settingsList = await _db.select(_db.settings).get();
    final Map<String, String> map = {};
    for (var s in settingsList) {
      if (s.value != null) {
        map[s.key] = s.value!;
      }
    }
    return map;
  }

  @override
  Future<String?> getSetting(String key) async {
    final setting = await (_db.select(_db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return setting?.value;
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingsCompanion.insert(
        key: key,
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> saveSettings(Map<String, String> settings) async {
    await _db.transaction(() async {
      for (final entry in settings.entries) {
        await saveSetting(entry.key, entry.value);
      }
    });
  }
}
