import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import 'chat_error_mapper.dart';

/// Datasource for OpenAI-compatible local servers (e.g. LM Studio,
/// llama.cpp server, vLLM) exposing `/v1/models` and
/// `/v1/chat/completions`.
class OpenAiCompatibleDatasource {
  final Dio _dio;

  OpenAiCompatibleDatasource(this._dio);

  Future<List<String>> listModels() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/models');
    final data = (response.data?['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return data.map((m) => m['id'] as String).toList();
  }

  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    final controller = StreamController<String>();

    () async {
      try {
        final response = await _dio.post<ResponseBody>(
          '/v1/chat/completions',
          data: {
            'model': model,
            'messages': messages
                .map((m) => {'role': m.role.value, 'content': m.content})
                .toList(),
            'stream': true,
          },
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.startsWith('data: ')) continue;

          final payload = trimmed.substring(6).trim();
          if (payload == '[DONE]') break;

          final json = jsonDecode(payload) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>? ?? [];
          if (choices.isEmpty) continue;

          final delta = (choices.first as Map<String, dynamic>)['delta']
              as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(content);
          }
        }
        await controller.close();
      } catch (e, st) {
        controller.addError(await describeChatError(e), st);
        await controller.close();
      }
    }();

    return controller.stream;
  }
}
