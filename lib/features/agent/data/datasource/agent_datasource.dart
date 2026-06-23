import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../domain/model/agent_event.dart';

class AgentSessionNotFoundException implements Exception {
  final String sessionId;
  const AgentSessionNotFoundException(this.sessionId);

  @override
  String toString() => 'AgentSessionNotFoundException: session $sessionId not found';
}

class AgentDatasource {
  final int port;

  AgentDatasource({this.port = 8765});

  Future<List<Map<String, dynamic>>> listSessions() async {
    final client = HttpClient();
    try {
      final req = await client.get('localhost', port, '/sessions');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    } finally {
      client.close();
    }
  }

  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    final client = HttpClient();
    try {
      final req = await client.get('localhost', port, '/sessions/$sessionId/messages');
      final res = await req.close();
      if (res.statusCode == 404) {
        await res.drain();
        throw AgentSessionNotFoundException(sessionId);
      }
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return (decoded['messages'] as List).cast<Map<String, dynamic>>();
    } finally {
      client.close();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final client = HttpClient();
    try {
      final req = await client.delete('localhost', port, '/sessions/$sessionId');
      final res = await req.close();
      if (res.statusCode == 404) {
        await res.drain();
        throw AgentSessionNotFoundException(sessionId);
      }
      await res.drain();
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> listModels() async {
    final client = HttpClient();
    try {
      final req = await client.get('localhost', port, '/models');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    final client = HttpClient();
    try {
      final req = await client.get('localhost', port, '/config');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  Future<void> setConfig(Map<String, dynamic> config) async {
    final client = HttpClient();
    try {
      final req = await client.post('localhost', port, '/config');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(config));
      final res = await req.close();
      await res.drain();
    } finally {
      client.close();
    }
  }

  Stream<AgentEvent> streamChat({
    required String? sessionId,
    required String message,
    String? localPath,
  }) async* {
    final client = HttpClient();
    try {
      final request = await client.post('localhost', port, '/chat');
      request.headers.set('Content-Type', 'application/json');

      final body = jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        if (localPath != null) 'local_path': localPath,
      });
      request.write(body);

      final response = await request.close();
      final buffer = StringBuffer();

      await for (final chunk in response.transform(utf8.decoder)) {
        buffer.write(chunk);
        final raw = buffer.toString();
        final blocks = raw.split('\n\n');

        for (var i = 0; i < blocks.length - 1; i++) {
          final event = parseBlock(blocks[i]);
          if (event != null) yield event;
        }

        buffer.clear();
        buffer.write(blocks.last);
      }

      final remaining = buffer.toString().trim();
      if (remaining.isNotEmpty) {
        final event = parseBlock(remaining);
        if (event != null) yield event;
      }
    } finally {
      client.close();
    }
  }

  AgentEvent? parseBlock(String block) {
    final lines = block.split('\n');
    final dataLine = lines.firstWhere(
      (l) => l.startsWith('data:'),
      orElse: () => '',
    );
    if (dataLine.isEmpty) return null;

    final jsonStr = dataLine.substring('data:'.length).trim();
    if (jsonStr.isEmpty) return null;

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    return _mapJson(json);
  }

  AgentEvent? _mapJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'text' => AgentTextEvent(json['text'] as String? ?? ''),
      'thinking' => AgentThinkingEvent(json['text'] as String? ?? ''),
      'tool_call' => AgentToolCallEvent(
          json['tool'] as String? ?? '',
          (json['input'] as Map<String, dynamic>?) ?? {},
        ),
      'tool_result' => AgentToolResultEvent(
          json['tool'] as String? ?? '',
          json['output'] as String? ?? '',
        ),
      'done' => AgentDoneEvent(
          sessionId: json['session_id'] as String?,
          success: json['success'] as bool? ?? true,
        ),
      'error' => AgentErrorEvent(json['message'] as String? ?? 'Unknown error'),
      _ => null,
    };
  }
}
