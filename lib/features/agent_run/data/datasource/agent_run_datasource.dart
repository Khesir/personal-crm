import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class AgentRunDatasource {
  final Dio _dio;

  AgentRunDatasource(this._dio);

  Stream<Map<String, dynamic>> runSkill({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  }) {
    final controller = StreamController<Map<String, dynamic>>();

    () async {
      try {
        final response = await _dio.post<ResponseBody>(
          '/webhook/dev-command-center',
          data: {
            'skill': skill,
            'repo': repoPath,
            'context': context ?? <String, dynamic>{},
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
          controller.add(json);
        }
        await controller.close();
      } catch (e, st) {
        controller.addError(e, st);
        await controller.close();
      }
    }();

    return controller.stream;
  }
}
