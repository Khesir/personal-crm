import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/repository/chat_model_repository.dart';

/// Inspects a `streamChat()` failure and, if [error] is a [DioException]
/// whose response body is JSON shaped like `{"error": "..."}` or
/// `{"error": {"message": "..."}}` (the shape used by Anthropic,
/// OpenAI-compatible, and Ollama error responses), returns a
/// [ChatRequestException] carrying that message. Otherwise returns [error]
/// unchanged.
Future<Object> describeChatError(Object error) async {
  if (error is! DioException) return error;

  final data = error.response?.data;
  String? body;
  if (data is ResponseBody) {
    final bytes = await data.stream
        .cast<List<int>>()
        .fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    body = utf8.decode(bytes, allowMalformed: true);
  } else if (data is String) {
    body = data;
  }
  if (body == null || body.isEmpty) return error;

  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return error;
    final apiError = decoded['error'];
    final message = apiError is Map ? apiError['message'] : apiError;
    if (message is String && message.isNotEmpty) {
      return ChatRequestException(message);
    }
  } catch (_) {
    // Not JSON, or an unexpected shape — fall through.
  }
  return error;
}
