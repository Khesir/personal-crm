import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/main.dart';

class SettingsEnvDatasource {
  final SharedPreferences prefs;

  SettingsEnvDatasource(this.prefs);

  String getValue(String key) => dotenv.env[key] ?? '';

  Future<void> setValue(String key, String value) async {
    if (value.isEmpty) {
      await prefs.remove('$kSettingsPrefix$key');
    } else {
      await prefs.setString('$kSettingsPrefix$key', value);
    }
    dotenv.env[key] = value;
  }
}
