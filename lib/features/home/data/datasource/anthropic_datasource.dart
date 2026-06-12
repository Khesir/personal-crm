import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import 'chat_error_mapper.dart';

/// Datasource for Anthropic's Claude API, exposing `/v1/models` and
/// `/v1/messages`.
class AnthropicDatasource {
  static const _maxTokens = 4096;

  final Dio _dio;

  AnthropicDatasource(this._dio);

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
        final system = messages
            .where((m) => m.role == ChatRole.system)
            .map((m) => m.content)
            .join('\n');
        final conversation = messages.where((m) => m.role != ChatRole.system);

        final response = await _dio.post<ResponseBody>(
          '/v1/messages',
          data: {
            'model': model,
            'max_tokens': _maxTokens,
            'messages': conversation
                .map((m) => {'role': m.role.value, 'content': m.content})
                .toList(),
            'stream': true,
            if (system.isNotEmpty) 'system': system,
          },
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;

          final payload = trimmed.substring(6).trim();
          if (payload.isEmpty) continue;

          final json = jsonDecode(payload) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            if (delta?['type'] == 'text_delta') {
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                controller.add(text);
              }
            }
          } else if (type == 'message_stop') {
            break;
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
