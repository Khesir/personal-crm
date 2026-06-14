import 'package:dio/dio.dart';

import '../../domain/model/huggingface_model_result.dart';
import '../../domain/model/model_name_parser.dart';

/// Datasource for the public, unauthenticated Hugging Face Hub API
/// (`GET /api/models`), used to discover GGUF models for local inference.
///
/// Parsing assumptions (the exact response shape can't be hit live from this
/// sandbox — a human should sanity-check against the real API during QA):
/// - Each model object has an `id` field (e.g.
///   `"TheBloke/Llama-2-7B-Chat-GGUF"`) and a `siblings` array of
///   `{"rfilename": "..."}` (optionally with a `size` field, in bytes).
/// - Parameter count (billions) is parsed from `id` via a regex matching a
///   number immediately followed by `B`/`b` (e.g. `7B`, `13B`, `0.5B`). For
///   MoE-style ids like `2x7B`, the last `B`-suffixed number is used (`7`).
///   Models where this can't be determined are skipped entirely.
/// - For each `.gguf` sibling, the quantization label is extracted via a
///   regex matching one of `Q\d_K_[SML]`, `Q\d_K`, `Q\d_\d`, `F16`, `F32`,
///   `BF16` (case-insensitive, normalized to uppercase). Siblings whose
///   filename doesn't match any of these are skipped.
/// - `contextLength` is read from `model['config']['max_position_embeddings']`
///   if present and an int, else left null.
/// - Models with no recognized-quant `.gguf` siblings are skipped entirely.
class HuggingFaceDatasource {
  final Dio _dio;

  HuggingFaceDatasource(this._dio);

  Future<List<HuggingFaceModelResult>> searchModels({String? query}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/models',
      queryParameters: {
        'filter': 'gguf',
        'sort': 'downloads',
        'direction': '-1',
        'limit': '30',
        'full': 'true',
        if (query != null && query.isNotEmpty) 'search': query,
      },
    );

    final models = (response.data ?? []).cast<Map<String, dynamic>>();
    final results = <HuggingFaceModelResult>[];

    for (final model in models) {
      final repoId = model['id'] as String?;
      if (repoId == null) continue;

      final paramsBillions = ModelNameParser.parseParamsBillions(repoId);
      if (paramsBillions == null) continue;

      final siblings = (model['siblings'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final contextLength = _parseContextLength(model);
      final displayName = repoId.contains('/') ? repoId.split('/').last : repoId;

      for (final sibling in siblings) {
        final filename = sibling['rfilename'] as String?;
        if (filename == null || !filename.toLowerCase().endsWith('.gguf')) continue;

        final quant = ModelNameParser.parseQuant(filename);
        if (quant == null) continue;

        final size = sibling['size'];
        final fileSizeBytes = size is int ? size : 0;

        results.add(HuggingFaceModelResult(
          repoId: repoId,
          displayName: displayName,
          paramsBillions: paramsBillions,
          quant: quant,
          fileSizeBytes: fileSizeBytes,
          contextLength: contextLength,
        ));
      }
    }

    return results;
  }

  int? _parseContextLength(Map<String, dynamic> model) {
    final config = model['config'];
    if (config is Map<String, dynamic>) {
      final maxPositionEmbeddings = config['max_position_embeddings'];
      if (maxPositionEmbeddings is int) return maxPositionEmbeddings;
    }
    return null;
  }
}
