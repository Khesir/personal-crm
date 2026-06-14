import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_stream_event.dart';
import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_definition.dart';
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

  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    final controller = StreamController<ChatStreamEvent>();

    () async {
      try {
        final response = await _dio.post<ResponseBody>(
          '/v1/chat/completions',
          data: {
            'model': model,
            'messages': messages.map(_toOpenAiMessage).toList(),
            'stream': true,
            if (tools.isNotEmpty) 'tools': tools.map(_toOpenAiTool).toList(),
          },
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        final toolCallFragments = <int, _ToolCallFragment>{};

        await for (final line in stream) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.startsWith('data: ')) continue;

          final payload = trimmed.substring(6).trim();
          if (payload == '[DONE]') break;

          final json = jsonDecode(payload) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>? ?? [];
          if (choices.isEmpty) continue;

          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(ChatStreamTextDelta(content));
          }

          final deltaToolCalls = delta?['tool_calls'] as List<dynamic>?;
          if (deltaToolCalls != null) {
            for (final fragment in deltaToolCalls.cast<Map<String, dynamic>>()) {
              final index = fragment['index'] as int;
              final existing = toolCallFragments.putIfAbsent(
                index,
                () => _ToolCallFragment(),
              );
              final id = fragment['id'] as String?;
              if (id != null) existing.id = id;
              final function = fragment['function'] as Map<String, dynamic>?;
              final name = function?['name'] as String?;
              if (name != null) existing.name = name;
              final argumentsChunk = function?['arguments'] as String?;
              if (argumentsChunk != null) existing.arguments.write(argumentsChunk);
            }
          }

          if (choice['finish_reason'] == 'tool_calls') {
            final sortedIndexes = toolCallFragments.keys.toList()..sort();
            controller.add(ChatStreamToolCallsRequested(
              sortedIndexes
                  .map((index) => toolCallFragments[index]!.toToolCall(index))
                  .toList(),
            ));
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

  Map<String, dynamic> _toOpenAiMessage(ChatMessage m) {
    if (m.role == ChatRole.tool) {
      return {'role': 'tool', 'tool_call_id': m.toolCallId, 'content': m.content};
    }
    if (m.role == ChatRole.assistant && m.toolCalls.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': m.content,
        'tool_calls': m.toolCalls.map(_toOpenAiToolCall).toList(),
      };
    }
    return {'role': m.role.value, 'content': m.content};
  }

  /// OpenAI's `/v1/chat/completions` expects `function.arguments` as a
  /// JSON-encoded string (unlike Ollama, which expects a JSON object).
  Map<String, dynamic> _toOpenAiToolCall(ToolCall call) => {
        'id': call.id,
        'type': 'function',
        'function': {
          'name': call.name,
          'arguments': jsonEncode(call.arguments),
        },
      };

  Map<String, dynamic> _toOpenAiTool(ToolDefinition tool) => {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.parameters,
        },
      };
}

class _ToolCallFragment {
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();

  ToolCall toToolCall(int index) => ToolCall(
        id: id ?? 'call_$index',
        name: name ?? '',
        arguments: (jsonDecode(arguments.toString()) as Map<String, dynamic>?) ?? const {},
      );
}
