import '../repository/settings_repository.dart';

class SettingsController {
  final SettingsRepository repository;

  SettingsController(this.repository);

  String getValue(String key) => repository.getValue(key);

  Future<void> setValue(String key, String value) => repository.setValue(key, value);
}
