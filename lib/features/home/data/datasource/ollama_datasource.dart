import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import '../../domain/model/chat_stream_event.dart';
import '../../domain/model/ollama_pull_progress.dart';
import '../../domain/model/tool_call.dart';
import '../../domain/model/tool_definition.dart';
import 'chat_error_mapper.dart';

class OllamaDatasource {
  final Dio _dio;

  OllamaDatasource(this._dio);

  Future<List<String>> listModels() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/tags');
    final models = (response.data?['models'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return models.map((m) => m['name'] as String).toList();
  }

  /// Fetches [model]'s capability list via `POST /api/show`, e.g.
  /// `["completion", "tools", "vision"]`.
  Future<List<String>> getModelCapabilities(String model) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/show',
      data: {'name': model},
    );
    return (response.data?['capabilities'] as List<dynamic>? ?? [])
        .cast<String>();
  }

  /// Sends a single non-streaming `POST /api/chat` request for [model] with
  /// [tool] as its only available tool and [prompt] as the user message,
  /// capped to [maxTokens] generated tokens via Ollama's `num_predict`
  /// option. Returns whether the response's `message.tool_calls` includes a
  /// call to [tool]'s name.
  Future<bool> probeToolCall({
    required String model,
    required ToolDefinition tool,
    required String prompt,
    required int maxTokens,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/chat',
      data: {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'stream': false,
        'tools': [_toOllamaTool(tool)],
        'options': {'num_predict': maxTokens},
      },
    );
    final message = response.data?['message'] as Map<String, dynamic>?;
    final toolCalls = (message?['tool_calls'] as List<dynamic>?) ?? const [];
    return toolCalls.cast<Map<String, dynamic>>().any(
          (call) => (call['function'] as Map<String, dynamic>?)?['name'] == tool.name,
        );
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
          '/api/chat',
          data: {
            'model': model,
            'messages': messages.map(_toOllamaMessage).toList(),
            'stream': true,
            if (tools.isNotEmpty) 'tools': tools.map(_toOllamaTool).toList(),
          },
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.trim().isEmpty) continue;
          final json = jsonDecode(line) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(ChatStreamTextDelta(content));
          }
          if (json['done'] == true) {
            final toolCalls = message?['tool_calls'] as List<dynamic>?;
            if (toolCalls != null && toolCalls.isNotEmpty) {
              controller.add(ChatStreamToolCallsRequested(
                toolCalls
                    .cast<Map<String, dynamic>>()
                    .indexed
                    .map((entry) => _toToolCall(entry.$2, entry.$1))
                    .toList(),
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

  Map<String, dynamic> _toOllamaMessage(ChatMessage m) {
    if (m.role == ChatRole.tool) {
      return {'role': 'tool', 'content': m.content};
    }
    if (m.role == ChatRole.assistant && m.toolCalls.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': m.content,
        'tool_calls': m.toolCalls.map(_toOllamaToolCall).toList(),
      };
    }
    return {'role': m.role.value, 'content': m.content};
  }

  /// Ollama's `/api/chat` expects `function.arguments` as a JSON object
  /// (unlike OpenAI, which expects a JSON-encoded string).
  Map<String, dynamic> _toOllamaToolCall(ToolCall call) => {
        'id': call.id,
        'type': 'function',
        'function': {
          'name': call.name,
          'arguments': call.arguments,
        },
      };

  Map<String, dynamic> _toOllamaTool(ToolDefinition tool) => {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.parameters,
        },
      };

  ToolCall _toToolCall(Map<String, dynamic> json, int index) {
    final function = json['function'] as Map<String, dynamic>;
    return ToolCall(
      id: json['id'] as String? ?? 'call_$index',
      name: function['name'] as String,
      arguments: (function['arguments'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Pulls [name] (e.g. `hf.co/<repoId>:<quant>`) into the local Ollama
  /// install via `POST /api/pull`, streaming progress updates.
  ///
  /// Each line of the newline-delimited JSON response is parsed into an
  /// [OllamaPullProgress]. The stream completes after emitting the line with
  /// `{"status": "success"}`. On request failure, the error is mapped via
  /// [describeChatError] and added to the stream as an error.
  Stream<OllamaPullProgress> pullModel({required String name}) {
    final controller = StreamController<OllamaPullProgress>();

    () async {
      try {
        final response = await _dio.post<ResponseBody>(
          '/api/pull',
          data: {'name': name, 'stream': true},
          options: Options(responseType: ResponseType.stream),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.trim().isEmpty) continue;
          final json = jsonDecode(line) as Map<String, dynamic>;
          final progress = OllamaPullProgress.fromJson(json);
          controller.add(progress);
          if (json['status'] == 'success') break;
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
