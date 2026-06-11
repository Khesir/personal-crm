import '../../domain/repository/settings_repository.dart';
import '../datasource/settings_env_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsEnvDatasource datasource;

  SettingsRepositoryImpl(this.datasource);

  @override
  String getValue(String key) => datasource.getValue(key);

  @override
  Future<void> setValue(String key, String value) => datasource.setValue(key, value);
}
