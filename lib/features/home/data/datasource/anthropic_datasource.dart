import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_stream_event.dart';
import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_definition.dart';
import 'chat_error_mapper.dart';

/// Accumulates the streamed `content_block_start`/`content_block_delta`/
/// `content_block_stop` events for a single `tool_use` content block into a
/// completed [ToolCall].
class _ToolUseBuilder {
  final String id;
  final String name;
  final StringBuffer _argumentsJson = StringBuffer();

  _ToolUseBuilder({required this.id, required this.name, String initialJson = ''}) {
    _argumentsJson.write(initialJson);
  }

  void appendPartialJson(String partialJson) => _argumentsJson.write(partialJson);

  ToolCall build() {
    final json = _argumentsJson.toString();
    return ToolCall(
      id: id,
      name: name,
      arguments: json.isEmpty ? const {} : jsonDecode(json) as Map<String, dynamic>,
    );
  }
}

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

  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    final controller = StreamController<ChatStreamEvent>();

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
            'messages': _toAnthropicMessages(conversation.toList()),
            'stream': true,
            if (system.isNotEmpty) 'system': system,
            if (tools.isNotEmpty) 'tools': tools.map(_toAnthropicTool).toList(),
          },
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        final toolUseBuilders = <int, _ToolUseBuilder>{};

        await for (final line in stream) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;

          final payload = trimmed.substring(6).trim();
          if (payload.isEmpty) continue;

          final json = jsonDecode(payload) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == 'content_block_start') {
            final index = json['index'] as int;
            final block = json['content_block'] as Map<String, dynamic>?;
            if (block?['type'] == 'tool_use') {
              final input = block?['input'] as Map<String, dynamic>? ?? const {};
              toolUseBuilders[index] = _ToolUseBuilder(
                id: block!['id'] as String,
                name: block['name'] as String,
                initialJson: input.isEmpty ? '' : jsonEncode(input),
              );
            }
          } else if (type == 'content_block_delta') {
            final index = json['index'] as int;
            final delta = json['delta'] as Map<String, dynamic>?;
            if (delta?['type'] == 'text_delta') {
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                controller.add(ChatStreamTextDelta(text));
              }
            } else if (delta?['type'] == 'input_json_delta') {
              final partialJson = delta?['partial_json'] as String?;
              if (partialJson != null) {
                toolUseBuilders[index]?.appendPartialJson(partialJson);
              }
            }
          } else if (type == 'message_stop') {
            if (toolUseBuilders.isNotEmpty) {
              controller.add(ChatStreamToolCallsRequested(
                toolUseBuilders.values.map((b) => b.build()).toList(),
              ));
            }
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

  /// Anthropic has no native `tool` role: a `tool`-role [ChatMessage] is
  /// serialized as a `user` message containing a `tool_result` content
  /// block. Consecutive tool-role messages are combined into a single
  /// `user` message with one `tool_result` block per message, since
  /// Anthropic rejects consecutive `user` messages in a single request.
  List<Map<String, dynamic>> _toAnthropicMessages(List<ChatMessage> messages) {
    final result = <Map<String, dynamic>>[];

    for (final message in messages) {
      if (message.role == ChatRole.tool) {
        final toolResult = {
          'type': 'tool_result',
          'tool_use_id': message.toolCallId,
          'content': message.content,
        };
        final previous = result.isNotEmpty ? result.last : null;
        if (previous != null && previous['role'] == 'user' && previous['content'] is List) {
          (previous['content'] as List<dynamic>).add(toolResult);
        } else {
          result.add({'role': 'user', 'content': [toolResult]});
        }
        continue;
      }

      if (message.role == ChatRole.assistant && message.toolCalls.isNotEmpty) {
        result.add({
          'role': 'assistant',
          'content': [
            if (message.content.isNotEmpty) {'type': 'text', 'text': message.content},
            ...message.toolCalls.map((t) => {
                  'type': 'tool_use',
                  'id': t.id,
                  'name': t.name,
                  'input': t.arguments,
                }),
          ],
        });
        continue;
      }

      result.add({'role': message.role.value, 'content': message.content});
    }

    return result;
  }

  Map<String, dynamic> _toAnthropicTool(ToolDefinition tool) => {
        'name': tool.name,
        'description': tool.description,
        'input_schema': tool.parameters,
      };
}
