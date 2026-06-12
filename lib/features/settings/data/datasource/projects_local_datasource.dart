import 'dart:convert';

import 'package:crm/core/config/data_namespace.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kProjectsPrefsKey = '$kDataNamespace.settings.projects';

class ProjectsLocalDatasource {
  final SharedPreferences prefs;

  ProjectsLocalDatasource(this.prefs);

  List<Map<String, dynamic>> read() {
    final raw = prefs.getString(kProjectsPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> write(List<Map<String, dynamic>> projects) async {
    await prefs.setString(kProjectsPrefsKey, jsonEncode(projects));
  }
}
