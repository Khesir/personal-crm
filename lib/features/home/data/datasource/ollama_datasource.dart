import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/model/chat_message.dart';
import '../../domain/model/ollama_pull_progress.dart';
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

  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    final controller = StreamController<String>();

    () async {
      try {
        final response = await _dio.post<ResponseBody>(
          '/api/chat',
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
          if (line.trim().isEmpty) continue;
          final json = jsonDecode(line) as Map<String, dynamic>;
          final content = json['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            controller.add(content);
          }
          if (json['done'] == true) break;
        }
        await controller.close();
      } catch (e, st) {
        controller.addError(await describeChatError(e), st);
        await controller.close();
      }
    }();

    return controller.stream;
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
