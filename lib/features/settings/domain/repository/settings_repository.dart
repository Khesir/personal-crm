abstract class SettingsRepository {
  String getValue(String key);

  Future<void> setValue(String key, String value);
}
