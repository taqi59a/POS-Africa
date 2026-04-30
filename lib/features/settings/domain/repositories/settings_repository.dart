abstract class SettingsRepository {
  Future<Map<String, String>> getAllSettings();
  Future<String?> getSetting(String key);
  Future<void> saveSetting(String key, String value);
  Future<void> saveSettings(Map<String, String> settings);
}
