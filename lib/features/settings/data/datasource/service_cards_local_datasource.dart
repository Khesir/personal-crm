import 'dart:convert';

import 'package:crm/core/config/data_namespace.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kServiceCardsPrefsKey = '$kDataNamespace.settings.serviceCards';

class ServiceCardsLocalDatasource {
  final SharedPreferences prefs;

  ServiceCardsLocalDatasource(this.prefs);

  List<Map<String, dynamic>> read() {
    final raw = prefs.getString(kServiceCardsPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> write(List<Map<String, dynamic>> cards) async {
    await prefs.setString(kServiceCardsPrefsKey, jsonEncode(cards));
  }
}
