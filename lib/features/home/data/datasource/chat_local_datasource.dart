import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const kChatConversationsPrefsKey = 'home.conversations';

class ChatLocalDatasource {
  final SharedPreferences prefs;

  ChatLocalDatasource(this.prefs);

  List<Map<String, dynamic>> read() {
    final raw = prefs.getString(kChatConversationsPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> write(List<Map<String, dynamic>> conversations) async {
    await prefs.setString(kChatConversationsPrefsKey, jsonEncode(conversations));
  }
}
